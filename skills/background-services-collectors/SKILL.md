---
name: background-services-collectors
description: 'Design, implement, and debug Monitored App background workflows: services, collectors, sync orchestration, and platform bridges. Use when modifying collection frequency, lifecycle, scheduling, battery-aware behavior, or native bridge interactions. Enforces background-first architecture and platform-safe behavior.'
argument-hint: 'Describe the background feature/problem, service or collector involved, and platform constraints.'
user-invocable: true
---

# Background Services and Collectors

## Purpose
Provide a safe workflow for changes in core background logic where regressions can impact continuous operation.

## Use When
- Editing lib/core/services/*
- Editing lib/core/collectors/*
- Adjusting sync cadence or battery-aware logic
- Investigating foreground service behavior or native bridge calls

## Mandatory Constraints
- Background-first: core logic remains in services/collectors, never in UI
- Respect existing orchestrator roles (BackgroundService, DataCollectorService, WebSocketService)
- Keep Android-only features guarded to prevent iOS crashes
- Preserve secure storage and token handling paths

## Workflow

### 1) Map Trigger to Execution Path
- Identify trigger: boot, unlock, timer, websocket command, manual start
- Trace path to collector and sync output

### 2) Validate Platform Boundaries
- Confirm MethodChannel contracts match native plugin interfaces
- Confirm unavailable features are gated on unsupported platform

### 3) Apply Minimal Change
- Change only required timing, retry, lifecycle, or mapping logic
- Preserve existing error handling and fallback behavior

### 4) Battery and Reliability Review
- Check impact on frequency, retries, and wake behavior
- Avoid unnecessary high-frequency loops

### 5) Verification
- Confirm service startup and persistence behavior
- Confirm collection output is cached/synced as expected
- Confirm no regressions in related collectors

## Suggested Validation
- flutter analyze
- flutter test
- Manual run on Android emulator/device for service lifecycle checks
