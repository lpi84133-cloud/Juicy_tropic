-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

-dontwarn com.google.android.play.core.**

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
