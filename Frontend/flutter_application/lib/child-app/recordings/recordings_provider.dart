// --- lib/child-app/recordings/recordings_provider.dart ---

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:Ajial/api/auth_service.dart';

/// Model for a single recording
class Recording {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final int durationSeconds;
  final bool isFromApi; // Flag to check if recording is from API (uses URL) or local

  Recording({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.durationSeconds,
    this.isFromApi = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'createdAt': createdAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'isFromApi': isFromApi,
  };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    createdAt: DateTime.parse(json['createdAt']),
    durationSeconds: json['durationSeconds'] ?? 0,
    isFromApi: json['isFromApi'] ?? false,
  );

  /// Create Recording from VoiceNote (API response)
  factory Recording.fromVoiceNote(VoiceNote voiceNote) => Recording(
    id: voiceNote.voiceNoteId,
    name: voiceNote.title,
    filePath: voiceNote.blobUrl, // This is the URL for API recordings
    createdAt: voiceNote.createdAt,
    durationSeconds: 0, // API doesn't return duration
    isFromApi: true,
  );
}

/// Provider for managing recordings state
class RecordingsProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final AuthService _authService = AuthService();
  
  List<Recording> _recordings = [];
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _currentPlayingId;
  int _recordingSeconds = 0;
  String _childName = 'انس';
  int _currentStars = 0;
  String? _errorMessage;
  
  // Getters
  List<Recording> get recordings => _recordings;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get currentPlayingId => _currentPlayingId;
  int get recordingSeconds => _recordingSeconds;
  String get childName => _childName;
  int get currentStars => _currentStars;
  String? get errorMessage => _errorMessage;
  
  /// Initialize the provider with child data and fetch recordings from API
  Future<void> initialize({required String name, required int stars}) async {
    _childName = name;
    _currentStars = stars;
    
    // Fetch recordings from API
    await fetchRecordingsFromApi();
  }
  
  /// Fetch recordings from the API
  Future<void> fetchRecordingsFromApi() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final (success, message, voiceNotes) = await _authService.getVoiceNotes();
      
      if (success) {
        // Convert VoiceNotes to Recordings (API recordings sorted by newest first)
        _recordings = voiceNotes.map((vn) => Recording.fromVoiceNote(vn)).toList();
        debugPrint('✅ Fetched ${_recordings.length} recordings from API');
      } else {
        _errorMessage = message;
        debugPrint('❌ Failed to fetch recordings: $message');
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ في جلب التسجيلات';
      debugPrint('❌ Error fetching recordings: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Get the directory for storing recordings
  Future<String> _getRecordingsDirectory() async {
    if (kIsWeb) {
      // Web doesn't support file system, return empty path
      return '';
    }
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir.path;
  }
  
  /// Start recording
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (await _recorder.hasPermission()) {
        final dir = await _getRecordingsDirectory();
        final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final filePath = kIsWeb ? fileName : '$dir/$fileName';
        
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        
        _isRecording = true;
        _recordingSeconds = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }
  
  /// Update recording timer
  void updateRecordingTime(int seconds) {
    _recordingSeconds = seconds;
    notifyListeners();
  }
  
  /// Stop recording, upload to API, and save
  Future<Recording?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null) {
        final recordingNumber = _recordings.length + 1;
        final title = 'تسجيل $_childName $recordingNumber';
        
        // Create local recording first (will be replaced after upload)
        final localRecording = Recording(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: title,
          filePath: path,
          createdAt: DateTime.now(),
          durationSeconds: _recordingSeconds,
          isFromApi: false,
        );
        
        // Add to list immediately for instant feedback
        _recordings.insert(0, localRecording); // Add to beginning (newest first)
        notifyListeners();
        
        // Upload to API in background
        _uploadToApi(path, title, localRecording.id);
        
        return localRecording;
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Upload recording to API (background operation)
  /// Works on both Web and Mobile by reading file bytes
  Future<void> _uploadToApi(String filePath, String title, String localId) async {
    _isUploading = true;
    notifyListeners();
    
    try {
      // Read file bytes
      List<int> audioBytes;
      String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      if (kIsWeb) {
        // On Web, we need to fetch the blob URL
        // The record package on web returns a blob URL
        final response = await http.get(Uri.parse(filePath));
        audioBytes = response.bodyBytes;
        debugPrint('📦 Read ${audioBytes.length} bytes from blob URL');
      } else {
        // On mobile, read from file
        final file = File(filePath);
        audioBytes = await file.readAsBytes();
        fileName = filePath.split('/').last;
        debugPrint('📦 Read ${audioBytes.length} bytes from file');
      }
      
      // Upload using bytes
      final result = await _authService.uploadVoiceNoteFromBytes(
        audioBytes: audioBytes,
        fileName: fileName,
        title: title,
      );
      
      if (result.success && result.voiceNote != null) {
        // Replace local recording with API recording
        final apiRecording = Recording.fromVoiceNote(result.voiceNote!);
        final index = _recordings.indexWhere((r) => r.id == localId);
        if (index != -1) {
          _recordings[index] = apiRecording;
        }
        debugPrint('✅ Recording uploaded successfully: ${result.voiceNote!.title}');
      } else {
        debugPrint('❌ Failed to upload recording: ${result.message}');
        // Keep local recording as fallback
      }
    } catch (e) {
      debugPrint('❌ Error uploading recording: $e');
    }
    
    _isUploading = false;
    notifyListeners();
  }
  
  /// Play a recording
  Future<void> playRecording(Recording recording) async {
    try {
      // Stop current playback if any
      if (_isPlaying) {
        await _player.stop();
      }
      
      // Use UrlSource for API recordings, DeviceFileSource for local recordings
      if (recording.isFromApi) {
        await _player.play(UrlSource(recording.filePath));
      } else {
        await _player.play(DeviceFileSource(recording.filePath));
      }
      
      _isPlaying = true;
      _currentPlayingId = recording.id;
      notifyListeners();
      
      // Listen for completion
      _player.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentPlayingId = null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }
  
  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPlayingId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }
  
  /// Toggle play/pause for a recording
  Future<void> togglePlayback(Recording recording) async {
    if (_isPlaying && _currentPlayingId == recording.id) {
      await stopPlayback();
    } else {
      await playRecording(recording);
    }
  }
  
  /// Delete a recording
  Future<void> deleteRecording(String id) async {
    try {
      final recording = _recordings.firstWhere((r) => r.id == id);
      
      // Delete local file if not from API and not web
      if (!recording.isFromApi && !kIsWeb) {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _recordings.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }
  
  /// Add stars (called when completing a recording)
  void addStars(int amount) {
    _currentStars += amount;
    notifyListeners();
  }
  
  /// Refresh recordings from API
  Future<void> refresh() async {
    await fetchRecordingsFromApi();
  }
  
  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
