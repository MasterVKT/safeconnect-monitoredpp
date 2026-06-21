# Production Deployment Guide

This guide provides comprehensive instructions for building, securing, and deploying the XP SafeConnect Monitored App.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Security Configuration](#security-configuration)
- [Build Process](#build-process)
- [Deployment Methods](#deployment-methods)
- [Security Validation](#security-validation)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- Flutter SDK 3.24.5 or later
- Dart SDK (included with Flutter)
- Android SDK with API level 21+ (Android 5.0+)
- Java JDK 17
- Git

### Required Accounts/Services

- Firebase project (for crashlytics and analytics)
- Google Play Console (for production deployment)
- Code signing certificates

## Environment Setup

### 1. Flutter Environment

```bash
# Verify Flutter installation
flutter doctor

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs
```

### 2. Android Environment

Ensure the following environment variables are set:

```bash
export ANDROID_HOME=/path/to/android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

## Security Configuration

### 1. Keystore Generation

For production builds, generate a secure keystore:

```bash
keytool -genkey -v -keystore release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

### 2. Environment Variables

Set the following environment variables for production builds:

```bash
# Keystore configuration
export KEYSTORE_PATH=/path/to/release.keystore
export KEYSTORE_PASSWORD=your_keystore_password
export KEY_ALIAS=release
export KEY_PASSWORD=your_key_password

# Security keys
export SECURITY_KEY=your_32_character_security_key
export STEALTH_SECURITY_KEY=your_stealth_security_key

# Build identification
export BUILD_FINGERPRINT=unique_build_identifier
export BUILD_SIGNATURE=build_signature_hash
```

### 3. Firebase Configuration

1. Create a Firebase project
2. Download `google-services.json`
3. Place it in `android/app/`
4. Enable Crashlytics and Analytics

## Build Process

### Automated Build Script

Use the provided build script for automated, secure builds:

```bash
# Debug build
BUILD_TYPE=debug ./scripts/build-production.sh

# Release build
BUILD_TYPE=release ./scripts/build-production.sh

# Stealth build
BUILD_TYPE=stealth ./scripts/build-production.sh
```

### Manual Build Process

#### 1. Debug Build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
flutter build apk --debug
```

#### 2. Release Build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze

# Set security environment variables (see Security Configuration)
flutter build apk --release
flutter build appbundle --release
```

#### 3. Stealth Build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze

# Set stealth security environment variables
flutter build apk --release --flavor stealth
```

## Deployment Methods

### 1. Internal Distribution

For internal testing and distribution:

1. Build the APK using release configuration
2. Distribute via secure channels (encrypted email, secure file sharing)
3. Ensure recipients verify checksums

### 2. Enterprise Distribution

For enterprise deployments:

1. Use App Bundle format for Google Play for Work
2. Configure managed app configuration
3. Set up device policies via EMM provider

### 3. Direct Installation

For direct installation on target devices:

1. Enable "Unknown Sources" or "Install from Unknown Sources"
2. Transfer APK securely
3. Install and verify integrity

## Build Configurations

### Debug Configuration

```yaml
Features:
  - Debug logging enabled
  - Development API endpoints
  - Reduced security measures
  - Firebase development project

Security:
  - Debug keystore signing
  - No obfuscation
  - Readable stack traces
```

### Release Configuration

```yaml
Features:
  - Production API endpoints
  - Full security measures enabled
  - Crashlytics reporting
  - Performance optimizations

Security:
  - Production keystore signing
  - Full code obfuscation
  - Anti-tampering protection
  - Debug symbol removal
```

### Stealth Configuration

```yaml
Features:
  - Maximum obfuscation
  - App disguise functionality
  - Enhanced anti-analysis
  - Stealth communication protocols

Security:
  - Custom keystore signing
  - Maximum code obfuscation
  - Anti-reverse engineering
  - Runtime application self-protection (RASP)
```

## Security Validation

### Pre-Deployment Checks

1. **Build Integrity Verification**
   ```bash
   # Verify APK signature
   jarsigner -verify build/app/outputs/flutter-apk/app-release.apk
   
   # Check obfuscation
   ls -la build/app/outputs/mapping/release/mapping.txt
   ```

2. **Security Analysis**
   ```bash
   # Analyze APK structure
   aapt dump badging app-release.apk
   
   # Check for debug symbols
   strings app-release.apk | grep -i debug
   ```

3. **Size Analysis**
   ```bash
   # Check APK size
   ls -lh *.apk
   
   # Analyze APK contents
   unzip -l app-release.apk
   ```

### Post-Deployment Monitoring

1. **Crashlytics Monitoring**
   - Monitor crash reports
   - Track performance metrics
   - Analyze user engagement

2. **Security Monitoring**
   - Monitor for tampering attempts
   - Track unauthorized access attempts
   - Analyze device integrity reports

## CI/CD Integration

### GitHub Actions

The project includes a complete GitHub Actions workflow (`.github/workflows/build-and-deploy.yml`) that:

1. Runs security scans
2. Builds all configurations
3. Performs security validation
4. Deploys to staging/production
5. Creates releases

### Required Secrets

Configure the following secrets in your CI/CD system:

```yaml
# Android signing
ANDROID_KEYSTORE_BASE64: Base64 encoded keystore file
KEYSTORE_PASSWORD: Keystore password
KEY_ALIAS: Key alias
KEY_PASSWORD: Key password

# Security
SECURITY_KEY: Production security key
STEALTH_SECURITY_KEY: Stealth mode security key

# Notifications
SLACK_WEBHOOK: Slack webhook for notifications
```

## Troubleshooting

### Common Build Issues

#### 1. Keystore Issues

```bash
# Error: keystore not found
Solution: Verify KEYSTORE_PATH is correct and file exists

# Error: wrong password
Solution: Verify KEYSTORE_PASSWORD and KEY_PASSWORD are correct
```

#### 2. Dependency Issues

```bash
# Error: pub get failed
Solution: 
flutter clean
flutter pub cache repair
flutter pub get
```

#### 3. Code Generation Issues

```bash
# Error: build_runner failed
Solution:
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Performance Issues

#### 1. Large APK Size

- Review dependencies
- Enable resource shrinking
- Use APK Analyzer to identify large assets

#### 2. Build Time

- Use build cache
- Parallelize builds
- Optimize dependencies

### Security Issues

#### 1. Obfuscation Not Working

- Verify ProGuard rules
- Check R8 configuration
- Review mapping file generation

#### 2. Debug Information in Release

- Verify build configuration
- Check for debug flags
- Review ProGuard rules

## Best Practices

### 1. Security

- Never commit keystores to version control
- Use environment variables for sensitive data
- Regularly rotate security keys
- Monitor for security vulnerabilities

### 2. Build Management

- Use consistent build environments
- Automate build processes
- Maintain build logs
- Version all build artifacts

### 3. Distribution

- Verify checksums before distribution
- Use secure distribution channels
- Track distributed versions
- Maintain deployment logs

### 4. Monitoring

- Monitor application performance
- Track security events
- Analyze user behavior
- Respond to security incidents

## Support and Maintenance

### Regular Tasks

1. **Weekly**
   - Review crash reports
   - Monitor performance metrics
   - Check security alerts

2. **Monthly**
   - Update dependencies
   - Review security configurations
   - Analyze usage patterns

3. **Quarterly**
   - Security audit
   - Performance optimization
   - Feature assessment

### Emergency Procedures

1. **Security Incident**
   - Revoke compromised certificates
   - Push emergency updates
   - Notify affected users

2. **Critical Bug**
   - Hotfix development
   - Emergency deployment
   - User communication

## Compliance and Legal

### Data Protection

- Ensure GDPR compliance
- Implement data retention policies
- Provide user data controls
- Maintain consent records

### App Store Compliance

- Follow platform guidelines
- Implement required permissions
- Provide privacy policies
- Maintain app store metadata

This deployment guide should be reviewed and updated regularly to reflect changes in the application, security requirements, and deployment infrastructure.