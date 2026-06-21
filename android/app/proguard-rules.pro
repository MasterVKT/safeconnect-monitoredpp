# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Security and obfuscation rules for monitoring app
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Security plugin rules - keep security classes from obfuscation for debugging
-keep class com.xpsafeconnect.monitored_app.SecurityPlugin { *; }
-keep class com.xpsafeconnect.monitored_app.RASPManager { *; }
-keep class com.xpsafeconnect.monitored_app.AntiUninstallAdmin { *; }

# Keep method channel interfaces
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler {
    public void onMethodCall(io.flutter.plugin.common.MethodCall, io.flutter.plugin.common.MethodChannel$Result);
}

# Keep data collector plugins
-keep class com.xpsafeconnect.monitored_app.*Plugin { *; }
-keep class com.xpsafeconnect.monitored_app.*Collector* { *; }

# Obfuscate everything else aggressively
-repackageclasses ''
-allowaccessmodification

# Remove debugging information
-renamesourcefileattribute SourceFile
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod

# Anti-analysis measures
-adaptclassstrings
-adaptresourcefilenames **.properties,**.xml,**.txt
-adaptresourcefilecontents **.properties,META-INF/MANIFEST.MF

# String encryption (requires additional obfuscation tools)
-dontwarn **$$serializer
-keepclassmembers class **$$serializer {
    *** INSTANCE;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Remove debug prints
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}

# Crash reporting (keep for Firebase Crashlytics)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Native libraries protection
-keepclasseswithmembernames class * {
    native <methods>;
}

# Anti-tampering - keep integrity verification methods
-keep class com.xpsafeconnect.monitored_app.** {
    public static *** verify*(...);
    public static *** check*(...);
    public static *** validate*(...);
}

# Optimize aggressively
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5

# Additional anti-reverse engineering
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Remove unused resources
-dontshrink

# Advanced obfuscation
-useuniqueclassmembernames
-keeppackagenames doNotKeepAThing

# Control flow obfuscation (available in commercial obfuscators)
# -addconfigurationdebugging

# Reflection protection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Additional security hardening
-keepattributes *Annotation*

# Obfuscate package names
-flattenpackagehierarchy ''

# Remove debug symbols
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute ""

# Anti-static analysis
-adaptclassstrings
-obfuscationdictionary dictionary.txt
-classobfuscationdictionary dictionary.txt
-packageobfuscationdictionary dictionary.txt

# Final security measures
-dontpreverify
-forceprocessing