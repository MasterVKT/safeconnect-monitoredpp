---
name: quality-gates-flutter
description: 'Run and enforce Monitored App quality gates before sign-off: formatting, static analysis, tests, architecture checks, i18n checks, and completion checklist alignment. Use for final validation after feature work, bug fixes, refactors, or integration changes.'
argument-hint: 'Describe the scope of changes to validate and desired strictness level.'
user-invocable: true
---

# Quality Gates (Flutter)

## Purpose
Standardize completion checks so every agent provides consistent, reliable final validation.

## Use When
- Finishing a feature or bug fix
- Preparing a change summary for delivery
- Verifying non-regression after risky edits

## Gate Sequence

### 1) Format
- dart format .

### 2) Static Analysis
- flutter analyze

### 3) Tests
- flutter test

### 4) Architecture Rules Check
- GetIt usage respected
- Riverpod patterns respected
- Background-first boundaries preserved
- Native bridge boundaries preserved

### 5) i18n and Security Check
- No hardcoded user-facing strings
- FR/EN keys present for new text
- No sensitive data in logs/messages

### 6) Integration Issue Rule
- If backend-side failure detected, ensure integration issue file exists and is complete

### 7) Completion Report Contract
Always provide:
1. Commands executed
2. Pass/fail status per gate
3. Files changed
4. Residual risks
5. Suggested next actions

## Strictness Modes
- Standard: run all gates relevant to changed files
- Strict: run full analyze + full tests + deeper manual scenario checks