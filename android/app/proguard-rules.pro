# Keep ML Kit text recognition classes and ignore optional language variants
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Some language-specific options may not be packaged; suppress missing class warnings
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep Flutter plugin registrant
-keep class io.flutter.plugins.** { *; }
