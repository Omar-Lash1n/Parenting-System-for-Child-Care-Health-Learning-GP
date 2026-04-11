# Todo Tasks API — Flutter Integration Guide

**Feature:** Parent To-Do List ("مهامي")  
**Base URL:** `https://<your-api-host>`  
**Auth:** All endpoints require `Authorization: Bearer <jwt_token>` header.

---

## Global Response Wrapper

Every endpoint returns the same envelope:

```json
{
  "success": true,
  "message": "تمت العملية بنجاح",
  "data": { ... },
  "errors": []
}
```

| Field     | Type            | Notes                                      |
|-----------|-----------------|--------------------------------------------|
| `success` | `bool`          | `true` on success, `false` on failure      |
| `message` | `string`        | Arabic status message                      |
| `data`    | `T \| null`     | Payload (null on failure)                  |
| `errors`  | `List<string>`  | Non-empty only when `success == false`     |

**Dart model:**
```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors = const [],
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}
```

---

## Shared Models

### TaskCategoryDto
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "دواء"
}
```
```dart
class TaskCategoryDto {
  final String id;
  final String name;

  TaskCategoryDto({required this.id, required this.name});

  factory TaskCategoryDto.fromJson(Map<String, dynamic> json) => TaskCategoryDto(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}
```

### TaskAssigneeDto
```json
{
  "type": "parent",
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "fullName": "أحمد محمد",
  "profileImageUrl": "https://storage.example.com/images/parent.jpg"
}
```
- `type` is either `"parent"` or `"child"`
- `profileImageUrl` may be `null`

```dart
class TaskAssigneeDto {
  final String type; // "parent" | "child"
  final String id;
  final String fullName;
  final String? profileImageUrl;

  TaskAssigneeDto({
    required this.type,
    required this.id,
    required this.fullName,
    this.profileImageUrl,
  });

  factory TaskAssigneeDto.fromJson(Map<String, dynamic> json) => TaskAssigneeDto(
    type: json['type'] as String,
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    profileImageUrl: json['profileImageUrl'] as String?,
  );
}
```

### TaskCardDto
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "title": "شراء الدواء",
  "color": "#FF5733",
  "dueDate": "2026-04-15T10:00:00",
  "isCompleted": false,
  "completedAt": null,
  "category": {
    "id": "...",
    "name": "دواء"
  },
  "assignees": [
    { "type": "parent", "id": "...", "fullName": "أحمد محمد", "profileImageUrl": null },
    { "type": "child",  "id": "...", "fullName": "سارة أحمد",  "profileImageUrl": "https://..." }
  ]
}
```
- `color` — hex string or null. Use for card background/accent color.
- `dueDate` — ISO 8601, always present (server stores today if client sent null).
- `category` — always non-null. Tasks with no category get the parent's system "الكل" category.
- `completedAt` — null unless `isCompleted == true`.

```dart
class TaskCardDto {
  final String id;
  final String title;
  final String? color;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final TaskCategoryDto category;
  final List<TaskAssigneeDto> assignees;

  TaskCardDto({
    required this.id,
    required this.title,
    this.color,
    this.dueDate,
    required this.isCompleted,
    this.completedAt,
    required this.category,
    required this.assignees,
  });

  factory TaskCardDto.fromJson(Map<String, dynamic> json) => TaskCardDto(
    id: json['id'] as String,
    title: json['title'] as String,
    color: json['color'] as String?,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    isCompleted: json['isCompleted'] as bool,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    category: TaskCategoryDto.fromJson(json['category']),
    assignees: (json['assignees'] as List)
        .map((a) => TaskAssigneeDto.fromJson(a))
        .toList(),
  );
}
```

---

## Task Category Endpoints

### C-1 · GET /api/TaskCategory/parent/{parentId}

Fetch all categories for the parent. Returns 4 defaults on first call if none exist yet.

**Path param:** `parentId` — the parent's GUID (from login response)

**Response `data`:**
```json
{
  "categories": [
    { "id": "...", "name": "الكل",              "isSystem": true,  "taskCount": 12 },
    { "id": "...", "name": "متطلبات المنزل",    "isSystem": false, "taskCount": 5  },
    { "id": "...", "name": "دواء",              "isSystem": false, "taskCount": 3  },
    { "id": "...", "name": "كشف",              "isSystem": false, "taskCount": 4  }
  ]
}
```
- "الكل" is always first (`isSystem: true`). Its `taskCount` = total tasks across all categories.
- `isSystem: true` → disable Edit / Delete buttons in the UI.

```dart
// Dart model
class CategoryItemDto {
  final String id;
  final String name;
  final bool isSystem;
  final int taskCount;

  CategoryItemDto({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.taskCount,
  });

  factory CategoryItemDto.fromJson(Map<String, dynamic> json) => CategoryItemDto(
    id: json['id'] as String,
    name: json['name'] as String,
    isSystem: json['isSystem'] as bool,
    taskCount: json['taskCount'] as int,
  );
}

// Usage
final response = await http.get(
  Uri.parse('$baseUrl/api/TaskCategory/parent/$parentId'),
  headers: {'Authorization': 'Bearer $token'},
);
final json = jsonDecode(response.body);
final apiResponse = ApiResponse.fromJson(json, (data) {
  final list = (data['categories'] as List)
      .map((c) => CategoryItemDto.fromJson(c))
      .toList();
  return list;
});
```

---

### C-2 · POST /api/TaskCategory

Create a new category.

**Request body:**
```json
{ "name": "رياضة" }
```

**Response `data`:** `TaskCategoryDto`
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "رياضة"
}
```

**Error cases:**
- `400` — duplicate name for this parent

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/TaskCategory'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({'name': 'رياضة'}),
);
```

---

### C-3 · PUT /api/TaskCategory/{categoryId}

Rename a category. Rejected if `isSystem == true`.

**Request body:**
```json
{ "name": "رياضة وترفيه" }
```

**Response `data`:** `TaskCategoryDto` (updated)

**Error cases:**
- `400` — trying to edit a system category
- `400` — duplicate name

```dart
final response = await http.put(
  Uri.parse('$baseUrl/api/TaskCategory/$categoryId'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({'name': 'رياضة وترفيه'}),
);
```

---

### C-4 · DELETE /api/TaskCategory/{categoryId}

Delete a category. Rejected if `isSystem == true`.  
Tasks that belonged to this category will have their category fall back to "الكل" automatically.

**Response `data`:** `true`

**Error cases:**
- `400` — trying to delete a system category

```dart
final response = await http.delete(
  Uri.parse('$baseUrl/api/TaskCategory/$categoryId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

---

## Task Endpoints

### T-1 · GET /api/Task/parent/{parentId}

Fetch all tasks for the parent. The frontend is responsible for grouping into sections.

**Path param:** `parentId` — the parent's GUID

**Response `data`:**
```json
{
  "tasks": [ /* TaskCardDto[] */ ]
}
```

**Grouping logic (implement in Flutter):**
| Section (Arabic)   | Condition                                   |
|--------------------|---------------------------------------------|
| الفترة السابقة     | `dueDate < today` and `isCompleted == false` |
| اليوم              | `dueDate == today` and `isCompleted == false`|
| الفترة القادمة     | `dueDate > today` and `isCompleted == false` |
| تم انجازه          | `isCompleted == true`                        |

```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/Task/parent/$parentId'),
  headers: {'Authorization': 'Bearer $token'},
);
final json = jsonDecode(response.body);
final tasks = (json['data']['tasks'] as List)
    .map((t) => TaskCardDto.fromJson(t))
    .toList();
```

---

### T-2 · POST /api/Task

Create a new task.

**Request body:**
```json
{
  "title": "شراء الدواء",
  "categoryId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "color": "#FF5733",
  "dueDate": "2026-04-15T10:00:00",
  "includeParent": true,
  "childIds": [
    "child-guid-1",
    "child-guid-2"
  ]
}
```

**Field rules:**
| Field           | Required | Notes                                                                       |
|-----------------|----------|-----------------------------------------------------------------------------|
| `title`         | Yes      | 1–200 characters                                                            |
| `categoryId`    | No       | Must belong to this parent. Send `null` to use "الكل"                      |
| `color`         | No       | Hex string e.g. `"#FF5733"`. Send `null` for no color                     |
| `dueDate`       | No       | ISO 8601. Send `null` → server stores today, no push notification sent    |
| `includeParent` | No       | `true` = parent is an assignee on this task. Default `false`               |
| `childIds`      | No       | List of child GUIDs. Send `[]` for no child assignees                     |

**Notification behavior:**
- `dueDate` provided → push notification fires at that time
- `dueDate` null → no notification (task stored with today's date)

**Response `data`:** `TaskCardDto` (the created task)

```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/Task'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'title': 'شراء الدواء',
    'categoryId': categoryId,       // or null
    'color': '#FF5733',             // or null
    'dueDate': '2026-04-15T10:00:00', // or null
    'includeParent': true,
    'childIds': ['child-guid-1'],
  }),
);
final json = jsonDecode(response.body);
final task = TaskCardDto.fromJson(json['data']);
```

---

### T-3 · PUT /api/Task/{taskId}

Update all mutable fields of a task.

**Request body:** Same shape as Create (T-2)

**Note:** `isCompleted` / `completedAt` are NOT part of this body — use T-5 to toggle completion.

**Notification re-trigger rule:**
- If `dueDate` changes to a new explicit value → notification will fire again at the new time
- If `dueDate` changes to null → notification suppressed

**Response `data`:** `TaskCardDto` (updated task)

```dart
final response = await http.put(
  Uri.parse('$baseUrl/api/Task/$taskId'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'title': 'شراء الدواء والفيتامينات',
    'categoryId': categoryId,
    'color': '#33A1FF',
    'dueDate': '2026-04-20T09:00:00',
    'includeParent': true,
    'childIds': [],
  }),
);
```

---

### T-4 · DELETE /api/Task/{taskId}

Delete a task permanently.

**Response `data`:** `true`

```dart
final response = await http.delete(
  Uri.parse('$baseUrl/api/Task/$taskId'),
  headers: {'Authorization': 'Bearer $token'},
);
```

---

### T-5 · PATCH /api/Task/{taskId}/complete

Toggle task completion status. No request body needed.

**Behavior:**
- If `isCompleted == false` → sets `isCompleted = true`, records `completedAt = now`
- If `isCompleted == true` → sets `isCompleted = false`, clears `completedAt`

**Response `data`:** `TaskCardDto` (updated task with new completion state)

```dart
final response = await http.patch(
  Uri.parse('$baseUrl/api/Task/$taskId/complete'),
  headers: {'Authorization': 'Bearer $token'},
);
final json = jsonDecode(response.body);
final updatedTask = TaskCardDto.fromJson(json['data']);
```

---

## Error Handling

All failures return HTTP `400` (bad request) or `401` (unauthorized) with:

```json
{
  "success": false,
  "message": "رسالة الخطأ بالعربي",
  "data": null,
  "errors": ["تفاصيل الخطأ"]
}
```

**Common error scenarios:**

| Scenario                              | HTTP | `message`                         |
|---------------------------------------|------|-----------------------------------|
| Missing/invalid JWT                   | 401  | `"غير مصرح"`                     |
| Task/category not found               | 400  | `"المهمة غير موجودة"`             |
| Edit/delete system category "الكل"   | 400  | `"لا يمكن تعديل هذا التصنيف"`    |
| Duplicate category name               | 400  | `"التصنيف موجود بالفعل"`          |
| Title missing or too long             | 400  | validation errors in `errors[]`   |
| Access another parent's data          | 400  | `"غير مصرح"`                     |

```dart
// Generic error handler
void handleApiError(Map<String, dynamic> json) {
  final success = json['success'] as bool;
  if (!success) {
    final message = json['message'] as String;
    final errors = List<String>.from(json['errors'] ?? []);
    // Show snackbar/dialog with message or errors[0]
  }
}
```

---

## Complete Flow Example

```dart
// 1. On page open — load categories and tasks in parallel
Future<void> loadPage(String parentId, String token) async {
  final headers = {'Authorization': 'Bearer $token'};

  final results = await Future.wait([
    http.get(Uri.parse('$baseUrl/api/TaskCategory/parent/$parentId'), headers: headers),
    http.get(Uri.parse('$baseUrl/api/Task/parent/$parentId'), headers: headers),
  ]);

  final categories = (jsonDecode(results[0].body)['data']['categories'] as List)
      .map((c) => CategoryItemDto.fromJson(c))
      .toList();

  final tasks = (jsonDecode(results[1].body)['data']['tasks'] as List)
      .map((t) => TaskCardDto.fromJson(t))
      .toList();
}

// 2. User creates a task
Future<TaskCardDto?> createTask({
  required String token,
  required String title,
  required String? categoryId,
  required String? color,
  required DateTime? dueDate,
  required bool includeParent,
  required List<String> childIds,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/Task'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'title': title,
      'categoryId': categoryId,
      'color': color,
      'dueDate': dueDate?.toIso8601String(),
      'includeParent': includeParent,
      'childIds': childIds,
    }),
  );
  final json = jsonDecode(response.body);
  if (json['success'] == true) return TaskCardDto.fromJson(json['data']);
  return null;
}

// 3. User taps the complete checkbox
Future<TaskCardDto?> toggleComplete(String taskId, String token) async {
  final response = await http.patch(
    Uri.parse('$baseUrl/api/Task/$taskId/complete'),
    headers: {'Authorization': 'Bearer $token'},
  );
  final json = jsonDecode(response.body);
  if (json['success'] == true) return TaskCardDto.fromJson(json['data']);
  return null;
}
```

---

## Claude Integration Prompt

Copy the prompt below and give it to Claude to implement the full Flutter integration:

---

```
You are implementing the "مهامي" (My Tasks) feature for the Ajial parenting app in Flutter.
The backend is a .NET 9 REST API. All requests need Authorization: Bearer <token> header.
The parentId and JWT token are already stored in the app's auth state provider.

─────────────────────────────────────
GLOBAL RESPONSE WRAPPER
─────────────────────────────────────
Every endpoint returns:
{
  "success": bool,
  "message": string,       // Arabic
  "data": T | null,
  "errors": string[]
}

─────────────────────────────────────
MODELS TO CREATE
─────────────────────────────────────

TaskCategoryDto       { id: String, name: String }
CategoryItemDto       { id: String, name: String, isSystem: bool, taskCount: int }
TaskAssigneeDto       { type: String ("parent"|"child"), id: String, fullName: String, profileImageUrl: String? }
TaskCardDto           { id, title, color: String?, dueDate: DateTime?,
                        isCompleted: bool, completedAt: DateTime?,
                        category: TaskCategoryDto, assignees: List<TaskAssigneeDto> }
GetCategoriesResponse { categories: List<CategoryItemDto> }
GetTasksResponse      { tasks: List<TaskCardDto> }

─────────────────────────────────────
CATEGORY ENDPOINTS  (base: /api/TaskCategory)
─────────────────────────────────────
GET    /parent/{parentId}      → GetCategoriesResponse
  - "الكل" is always first (isSystem=true), disable edit/delete for it
  - taskCount for "الكل" = total tasks; others = tasks in that category

POST   /                       body: { name: String }  → TaskCategoryDto
PUT    /{categoryId}           body: { name: String }  → TaskCategoryDto
  - reject if isSystem==true (show error from response)
DELETE /{categoryId}           → bool
  - reject if isSystem==true

─────────────────────────────────────
TASK ENDPOINTS  (base: /api/Task)
─────────────────────────────────────
GET    /parent/{parentId}      → GetTasksResponse  (flat list, group in UI)

POST   /                       body:
  {
    title: String (required, max 200),
    categoryId: String? (null = "الكل"),
    color: String? (hex),
    dueDate: String? (ISO 8601 — null means no notification, just today),
    includeParent: bool,
    childIds: List<String>
  }
  → TaskCardDto

PUT    /{taskId}               same body as POST  → TaskCardDto
  (does NOT update isCompleted — use PATCH below)

DELETE /{taskId}               → bool

PATCH  /{taskId}/complete      no body  → TaskCardDto
  toggles isCompleted; sets/clears completedAt

─────────────────────────────────────
UI GROUPING (implement in Flutter)
─────────────────────────────────────
Group the flat task list into these sections:
  "الفترة السابقة"  → dueDate < today AND isCompleted==false
  "اليوم"           → dueDate == today AND isCompleted==false
  "الفترة القادمة"  → dueDate > today  AND isCompleted==false
  "تم انجازه"       → isCompleted==true

─────────────────────────────────────
WHAT TO BUILD
─────────────────────────────────────
1. Dart models with fromJson() for all types above.
2. TaskApiService class (or provider) with methods:
     getCategories(parentId)
     createCategory(name)
     updateCategory(categoryId, name)
     deleteCategory(categoryId)
     getTasks(parentId)
     createTask({title, categoryId, color, dueDate, includeParent, childIds})
     updateTask(taskId, {same fields})
     deleteTask(taskId)
     toggleComplete(taskId)
3. State management (use the existing pattern in the project — Riverpod/Provider/Bloc).
4. UI pages:
     - Task list page with grouped sections and category filter tabs
     - Add/Edit task bottom sheet or page
     - Category management page (list + add + rename + delete)
5. Error handling: show Arabic error message from response on failure.
6. On successful create/update/delete, refresh the task list.

Use the existing auth provider to get the JWT token and parentId.
Follow the same folder structure, naming conventions, and widget patterns
already used in the project.
```
