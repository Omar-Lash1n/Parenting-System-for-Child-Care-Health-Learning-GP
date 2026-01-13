# Voice Notes API Documentation

**For Flutter Team Integration**

---

## Authentication

Both endpoints require **Child JWT Token** in Authorization header:

```
Authorization: Bearer {child_jwt_token}
```

> [!NOTE]
> Get child token from `POST /api/Auth/login-child` endpoint

---

## 1. Upload Voice Note

### `POST /api/Child/voice-note`

**Content-Type:** `multipart/form-data`

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `VoiceNote` | File | ✅ | Audio file |
| `Title` | String | ❌ | Max 100 chars, auto-generated if empty |

### Constraints

- **Formats:** `.mp3`, `.wav`, `.m4a`, `.ogg`, `.webm`
- **Max Size:** 10 MB

### Success Response (200)

```json
{
  "success": true,
  "message": "تم رفع الملاحظة الصوتية بنجاح",
  "data": {
    "voiceNoteId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "title": "تسجيل انس 1",
    "blobUrl": "https://ajialchildimages.blob.core.windows.net/child-images/voice-notes/{childId}/voicenote_xxx.mp3",
    "fileSizeBytes": 1048576,
    "createdAt": "2026-01-13T15:00:00Z",
    "message": "تم رفع الملاحظة الصوتية بنجاح"
  },
  "errors": []
}
```

### Error Responses

| Code | Message |
|------|---------|
| 400 | نوع الملف غير مدعوم |
| 400 | حجم الملف يجب ألا يتجاوز 10 ميجابايت |
| 401 | يجب تسجيل الدخول أولاً |

---

## 2. Get Voice Notes

### `GET /api/Child/voice-notes`

**Content-Type:** `application/json`

### Request

No body required. Child ID extracted from JWT token.

### Success Response (200)

```json
{
  "success": true,
  "message": "تم جلب الملاحظات الصوتية بنجاح",
  "data": [
    {
      "voiceNoteId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "title": "تسجيل انس 1",
      "blobUrl": "https://ajialchildimages.blob.core.windows.net/...",
      "createdAt": "2026-01-13T15:00:00Z"
    },
    {
      "voiceNoteId": "4fa85f64-5717-4562-b3fc-2c963f66afa7",
      "title": "تسجيل انس 2",
      "blobUrl": "https://ajialchildimages.blob.core.windows.net/...",
      "createdAt": "2026-01-13T14:30:00Z"
    }
  ],
  "errors": []
}
```

> [!IMPORTANT]
> Returns **only** voice notes belonging to the authenticated child, sorted by newest first.

### Error Responses

| Code | Message |
|------|---------|
| 401 | يجب تسجيل الدخول أولاً |
| 400 | الطفل غير موجود |

---

## Flutter Integration Example

### Upload Voice Note

```dart
Future<void> uploadVoiceNote(File audioFile, String? title) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/api/Child/voice-note'),
  );
  
  request.headers['Authorization'] = 'Bearer $childToken';
  request.files.add(await http.MultipartFile.fromPath('VoiceNote', audioFile.path));
  
  if (title != null && title.isNotEmpty) {
    request.fields['Title'] = title;
  }
  
  var response = await request.send();
}
```

### Get Voice Notes

```dart
Future<List<VoiceNote>> getVoiceNotes() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/Child/voice-notes'),
    headers: {'Authorization': 'Bearer $childToken'},
  );
  
  final data = jsonDecode(response.body);
  return (data['data'] as List).map((e) => VoiceNote.fromJson(e)).toList();
}
```
