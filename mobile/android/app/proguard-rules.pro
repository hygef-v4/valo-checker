# Flutter's own keep rules are applied automatically by the Flutter Gradle
# plugin. Rules below cover plugins used by ValoCheck.

# flutter_secure_storage (Tink/keystore-backed crypto)
-keep class com.google.crypto.tink.** { *; }

# Silence harmless warnings from optional Play Core split-install references.
-dontwarn com.google.android.play.core.**
