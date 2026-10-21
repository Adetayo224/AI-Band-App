-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.navideck.universal_ble.** { *; }
-keep class com.llfbandit.record.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class kotlin.coroutines.** { *; }
-keepclassmembers class * { @kotlin.Metadata *; }

# Flutter embedding / plugin registrant
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-dontwarn kotlin.**
-dontwarn kotlinx.**
