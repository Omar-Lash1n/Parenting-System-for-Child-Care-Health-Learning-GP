# Flutter Local Notifications - Keep Gson TypeToken for proper deserialization
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic signature of TypeToken and its subclasses
-keepattributes Signature
-keepattributes *Annotation*

# Flutter Local Notifications Plugin classes
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Gson specific classes
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep notification-related classes
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
