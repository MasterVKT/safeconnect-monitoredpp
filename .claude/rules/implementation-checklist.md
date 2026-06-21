# Full Implementation Checklist - Monitored App

Before submitting any code change, verify it against this comprehensive checklist.

## 1. Planning & Context
- [ ] **Understood Request**: Have you fully understood the user's request or the ticket's requirements?
- [ ] **Clarified Ambiguities**: Have you asked for clarification on any ambiguous points?
- [ ] **Reviewed Specs**: Have you reviewed all relevant specification documents in the `docs/` folder?
- [ ] **Identified Files**: Have you identified all files that will be affected by your changes?
- [ ] **Considered Architecture**: Does your proposed change fit within the existing architecture (services, collectors, background-first)?

## 2. Implementation Quality
- [ ] **Complete Code**: Have you provided complete, functional code without placeholders or `// TODO` comments?
- [ ] **Critical Rules**: Does your code adhere to all 6 critical rules defined in the main `CLAUDE.md`?
- [ ] **No Regressions**: Have you verified that your change does not break any existing functionality?
- [ ] **Code Style**: Does the code adhere to the detailed style guide (`code-style-detailed.md`)?
- [ ] **Linter Pass**: Does `flutter analyze` pass with zero warnings or errors?
- [ ] **Immutability**: Are all data models and states handled immutably (e.g., using `copyWith`)?
- [ ] **Purity**: Are `build` methods and other UI logic free of side effects?

## 3. Security & Privacy
- [ ] **No Hardcoded Secrets**: Are all API keys, credentials, and other secrets loaded from a secure configuration?
- [ ] **Input Validation**: Is all input from users or external sources validated? (Though this app has minimal UI input, this is crucial for data from the backend).
- [ ] **Secure Storage**: Is sensitive data (tokens, user info) stored using `flutter_secure_storage` via the `StorageService`?
- [ ] **Error Handling**: Do error messages avoid leaking sensitive information?

## 4. Testing
- [ ] **Unit Tests**: Have you added unit tests for any new business logic (e.g., in services or providers)?
- [ ] **Widget Tests**: Have you added widget tests for new UI components?
- [ ] **Existing Tests**: Do all existing tests still pass after your changes?
- [ ] **Manual Verification**: Have you manually tested the change on a physical device or emulator (both Android and iOS if applicable)?

## 5. Documentation & Communication
- [ ] **Code Comments**: Have you added `///` documentation comments for all new public members?
- [ ] **Integration Issue**: If you encountered a backend or other integration issue, have you created a documentation file for it?
- [ ] **Commit Message**: Is your commit message clear and descriptive, explaining the *why* behind the change?
- [ ] **Summary**: Have you prepared a concise summary of your work, noting what was completed and what might be next?

## 6. Platform Considerations
- [ ] **Android**: Does the feature work as expected on Android?
- [ ] **iOS**: Does the feature work as expected on iOS? If the feature is Android-only, is it guarded appropriately to prevent crashes on iOS?
- [ ] **Permissions**: If the change requires new device permissions, is the permission request flow handled correctly?
- [ ] **Battery Impact**: Have you considered the battery consumption of your change, especially for background tasks?
