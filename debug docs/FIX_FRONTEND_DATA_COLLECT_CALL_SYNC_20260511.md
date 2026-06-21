# Frontend Fix: Data Collect Call Sync Status Handling

**Issue ID**: FIX_FRONTEND_DATA_COLLECT_CALL_SYNC_20260511
**Date**: 2026-05-11
**Severity**: High
**Status**: Open for Flutter implementation

---

## Issue Summary

The monitored Flutter app can lose call-log data when `/api/v1/data/collect/` returns a transport-level response that the client treats as a full sync success. The backend is now more resilient, but the client must still send complete timestamps and handle item-level failures.

---

## Timestamp

**Detected**: 2026-05-11T08:53:30+01:00  
**Reported By**: Codex AI Agent  
**Environment**: Development, Django backend on Windows

---

## Affected Frontend App

**App**: Monitored App  
**Version**: Unknown  
**Platform**: Android  
**User Scenario**: Background sync sends collected call logs to the backend.

---

## API Endpoint

**URL**: `/api/v1/data/collect/`  
**Method**: `POST`  
**Authentication**: Required, JWT Bearer token  
**Permissions**: Authenticated user must own the submitted `device_id`  
**Expected Status**: `200 OK` for full success, `207 Multi-Status` for partial success, `400 Bad Request` for total item failure  
**Actual Previous Status**: `200 OK` even when all submitted call items failed

---

## Request Details

**Headers**:
```http
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
```

**Body**:
```json
{
  "device_id": "<device_uuid>",
  "data_type": "calls",
  "items": [
    {
      "call_type": "INCOMING",
      "phone_number": "+237699999999",
      "contact_name": "Test",
      "start_time": "2026-05-11T07:00:00Z",
      "end_time": "2026-05-11T07:01:00Z",
      "duration": 60,
      "recorded_at": "2026-05-11T07:00:00Z",
      "is_conference": false,
      "sim_slot": -1
    }
  ]
}
```

---

## Response Details

**Full success**:
```json
{
  "success": true,
  "processed_count": 1,
  "error_count": 0,
  "batch_id": "<batch_uuid>",
  "device_id": "<device_uuid>",
  "data_type": "calls",
  "item_errors": []
}
```

**Partial success**:
```json
{
  "success": false,
  "processed_count": 49,
  "error_count": 1,
  "batch_id": "<batch_uuid>",
  "device_id": "<device_uuid>",
  "data_type": "calls",
  "item_errors": [
    {
      "index": 49,
      "reason": "start_time is required",
      "error": "start_time is required",
      "item_preview": {
        "call_type": "INCOMING",
        "phone_number": "+237699999999"
      }
    }
  ]
}
```

**Total failure**:
```json
{
  "success": false,
  "processed_count": 0,
  "error_count": 50,
  "batch_id": "<batch_uuid>",
  "device_id": "<device_uuid>",
  "data_type": "calls",
  "item_errors": [
    {
      "index": 0,
      "reason": "start_time is required",
      "error": "start_time is required",
      "item_preview": {
        "call_type": "INCOMING"
      }
    }
  ]
}
```

---

## Expected vs Actual

### Expected Behavior

1. The monitored app sends each call item with `start_time` and `recorded_at` in ISO 8601 format.
2. The backend stores valid items.
3. The client marks only successfully processed items as synced.
4. Failed items remain queued with the backend `item_errors` reason for retry/debugging.

### Actual Previous Behavior

1. The monitored app omitted `recorded_at` for call items.
2. The backend rejected the items but returned HTTP 200.
3. The monitored app interpreted HTTP 200 as total success.
4. The app marked failed items as synced, causing data loss.

### Root Cause Analysis

- **Problem**: The frontend relied on HTTP 200 alone and did not inspect `processed_count`, `error_count`, or item-level failures.
- **Location**: Monitored app sync queue / call-log collector / data collect API client.
- **Impact**: Call logs could be dropped after a failed backend processing attempt.

---

## Proposed Solution

### Backend Changes

**Files**:
- `services/data_collection_service.py`
- `apps/api/views.py`

**Action**: Implemented. The backend now falls back from `recorded_at` to `start_time` for calls, returns `item_errors`, and uses `200`, `207`, or `400` according to processing results.

**Testing**:
```bash
..\Scripts\python.exe -m pytest -q tests/test_data_collect_api.py tests/test_monitoring_missing_endpoints.py
..\Scripts\python.exe manage.py check
..\Scripts\python.exe manage.py makemigrations --check --dry-run
```

---

### Frontend Changes

**Files to Modify**:
1. `lib/services/sync_service.dart` or the equivalent sync queue processor.
2. `lib/services/data_collection_service.dart` or the equivalent `/data/collect/` API client.
3. Call-log collector/model files that build the `calls` payload.

**Actions**:
1. Include `recorded_at` for every call item. Use the original event timestamp when available; otherwise use `start_time`.
2. Treat `200` as full success only when `success == true` and `error_count == 0`.
3. Treat `207` as partial success. Mark only items not present in `item_errors[*].index` as synced.
4. Treat `400` as total failure when `processed_count == 0`. Keep all submitted items queued for retry.
5. Persist `item_errors` in debug logs or local diagnostics without exposing sensitive data in user-visible UI.

**Suggested Dart handling**:
```dart
final response = await api.post('/api/v1/data/collect/', body: payload);
final body = jsonDecode(response.body) as Map<String, dynamic>;
final itemErrors = (body['item_errors'] as List? ?? const []);
final failedIndexes = itemErrors
    .map((error) => error['index'])
    .whereType<int>()
    .toSet();

if (response.statusCode == 200 && body['success'] == true) {
  markBatchSynced(items);
} else if (response.statusCode == 207) {
  markItemsSyncedByIndex(items, excludeIndexes: failedIndexes);
  keepItemsQueuedByIndex(items, indexes: failedIndexes);
} else if (response.statusCode == 400) {
  keepBatchQueued(items);
} else {
  keepBatchQueued(items);
}
```

**Payload mapping**:
```dart
{
  'call_type': call.callType,
  'phone_number': call.phoneNumber,
  'contact_name': call.contactName,
  'start_time': call.startTime.toUtc().toIso8601String(),
  'end_time': call.endTime?.toUtc().toIso8601String(),
  'duration': call.durationSeconds,
  'recorded_at': (call.recordedAt ?? call.startTime).toUtc().toIso8601String(),
  'is_conference': call.isConference ?? false,
  'sim_slot': call.simSlot ?? -1,
}
```

---

## Verification Steps

1. Queue at least 3 call-log items with valid `start_time` and `recorded_at`; verify backend returns `200` and all items are marked synced.
2. Queue one invalid call item without `start_time`; verify backend returns `400` for a single invalid item and the item remains queued.
3. Queue a mixed batch of valid and invalid call items; verify backend returns `207`, valid indexes are marked synced, and failed indexes remain queued.
4. Confirm the monitoring app can retrieve calls through `GET /api/v1/calls/?device=<device_uuid>`.
5. Confirm app restart does not drop queued failed items.

---

## Coordination

**Priority**: High  
**Deployment Order**: Backend first, then monitored Flutter app.  
**Backward Compatibility**: Backend now accepts missing `recorded_at` for calls by falling back to `start_time`, but frontend should still send `recorded_at` to preserve explicit event metadata.

---

## Additional Notes

The backend also accepts `data_type: "app_info"` for installed-app inventory sync. The monitored app should use that type when it starts queueing installed application metadata.
