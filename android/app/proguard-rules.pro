# Keep OkHttp (required by uCrop)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep Okio
-keep class okio.** { *; }
-dontwarn okio.**

# Keep uCrop
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep Glide (used internally)
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# Lefu SDK
-keep class com.lefu.ppbase.** { *; }
-keep class com.peng.ppscale.** { *; }
-keep class com.lefu.ppcalculate.** { *; }
-keep class com.besthealth.** { *; }
-keep class com.lefu.gson.** { *; }
-keep class com.lefu.bluetooth.** { *; }