# Detailed Code Style Guide - Monitored App

This document outlines the detailed code style, formatting, and conventions to be used across the Monitored App project.

## 1. Formatting
- **Line Length**: 80 characters. Use the VS Code ruler to help.
- **Auto-formatter**: Always run `dart format .` before committing code. This is the single source of truth for all formatting decisions (braces, spacing, etc.).
- **Trailing Commas**: Use trailing commas on all parameter lists, argument lists, collection literals, and method declarations with more than one line. This improves auto-formatting and reduces diff noise.

## 2. Naming Conventions
- **Files**: `snake_case.dart` (e.g., `battery_monitor_service.dart`).
- **Classes & Typedefs**: `PascalCase` (e.g., `BatteryMonitorService`).
- **Enums**: `PascalCase` for the type, `camelCase` for values (e.g., `enum Status { loading, success, error }`).
- **Methods, Functions, & Variables**: `camelCase` (e.g., `startMonitoring`).
- **Constants**: `camelCase` (e.g., `const defaultSyncInterval`).
- **Acronyms**: Treat acronyms as words. `Http` and `Api` are correct, `HTTP` and `API` are not (e.g., `HttpApi` not `HTTPAPI`).
- **Private Members**: Prefix with an underscore `_` (e.g., `_privateVariable`, `_privateMethod`).

## 3. Asynchronous Code (`async`/`await`)
- **Suffix**: Methods that return a `Future` should be named with an `Async` suffix (e.g., `fetchDataAsync`).
- **`await`**: Always `await` a `Future`. Do not use `.then()`.
- **Error Handling**: Always wrap `await` calls that can fail (network, I/O) in a `try-catch` block.

```dart
// ✅ CORRECT
Future<void> fetchDataAsync() async {
  try {
    final data = await _api.fetch();
    // ...
  } catch (e) {
    // Handle error
  }
}

// ❌ WRONG
void fetchData() {
  _api.fetch().then((data) {
    // ...
  });
}
```

## 4. Widget Structure
- **Stateless/Stateful**: Prefer `StatelessWidget` and `ConsumerWidget` (from Riverpod) over `StatefulWidget`. Only use `StatefulWidget` for managing local, ephemeral UI state (e.g., AnimationControllers, FocusNodes).
- **`build()` Purity**: The `build()` method should be pure and free of side effects.
- **Split Widgets**: Keep widgets small and focused. If a `build` method becomes too large or nested, extract parts of it into smaller, private widgets.

## 5. Riverpod Best Practices
- **Providers**: Define providers as global constants in their respective feature files.
- **`ref.watch` vs `ref.read`**: Use `ref.watch` inside the `build` method to rebuild the widget when the state changes. Use `ref.read` inside callbacks (like `onPressed`) to get the current state without listening for changes.
- **Provider Modifiers**: Use `.autoDispose` for providers that should be cleaned up when no longer used, and `.family` for providers that need to take an argument.

## 6. Models (using Freezed)
- **Immutability**: All model classes must be immutable. Use the `@freezed` annotation.
- **Constructors**: Include `fromJson` and `toJson` factory constructors for JSON serialization.
- **`copyWith`**: Use the generated `copyWith` method to create modified copies of model objects instead of mutating them.

```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## 7. Imports
- **Order**:
  1. `dart:` imports
  2. `package:` imports
  3. `lib/` (project-relative) imports
- **`show`**: Prefer `show` over `hide` to make code more explicit about what is being used from a library.
- **`as`**: Use `as` to prefix imports that have conflicting names.

## 8. Documentation Comments
- **Public APIs**: All public methods, classes, and functions must have documentation comments (`///`).
- **Explain *Why***: Comments should explain *why* the code is written a certain way, not *what* it does (the code itself should be clear enough to explain the 'what').
