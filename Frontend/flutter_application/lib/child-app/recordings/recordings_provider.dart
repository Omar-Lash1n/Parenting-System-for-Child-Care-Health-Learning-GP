// --- lib/child-app/recordings/recordings_provider.dart ---

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Model for a single recording
class Recording {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final int durationSeconds;

  Recording({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'createdAt': createdAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    createdAt: DateTime.parse(json['createdAt']),
    durationSeconds: json['durationSeconds'] ?? 0,
  );
}

/// Provider for managing recordings state
class RecordingsProvider extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  List<Recording> _recordings = [];
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingId;
  int _recordingSeconds = 0;
  String _childName = 'انس';
  int _currentStars = 0;
  
  // Getters
  List<Recording> get recordings => _recordings;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentPlayingId => _currentPlayingId;
  int get recordingSeconds => _recordingSeconds;
  String get childName => _childName;
  int get currentStars => _currentStars;
  
  /// Initialize the provider with child data
  void initialize({required String name, required int stars}) {
    _childName = name;
    _currentStars = stars;
    // In-memory only - no need to load from storage
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
  
  /// Stop recording and save
  Future<Recording?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null) {
        final recordingNumber = _recordings.length + 1;
        final recording = Recording(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'تسجيل $_childName $recordingNumber',
          filePath: path,
          createdAt: DateTime.now(),
          durationSeconds: _recordingSeconds,
        );
        
        _recordings.add(recording);
        // In-memory only - no persistent storage
        notifyListeners();
        return recording;
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
  
  /// Play a recording
  Future<void> playRecording(Recording recording) async {
    try {
      // Stop current playback if any
      if (_isPlaying) {
        await _player.stop();
      }
      
      if (kIsWeb) {
        // Web playback - use URL source if available
        await _player.play(DeviceFileSource(recording.filePath));
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
      
      // Delete file if not web
      if (!kIsWeb) {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _recordings.removeWhere((r) => r.id == id);
      // In-memory only - no persistent storage
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
  
  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}
