-keepattributes Exceptions,InnerClasses

-keepattributes Signature

-keep class io.rong.** {*;}
-keep class cn.rongcloud.** {*;}
-keep class * implements io.rong.imlib.model.MessageContent {*;}
-dontwarn io.rong.push.**
-dontnote com.xiaomi.**
-dontnote com.google.android.gms.gcm.**
-dontnote io.rong.**

-ignorewarnings

-keep class com.amazon.** {*;}
-keep class com.dooboolab.** { *; }
-keep class com.android.vending.billing.
-dontwarn com.amazon.
-keepattributes *Annotation*
-keep class com.riguz.** { *; }