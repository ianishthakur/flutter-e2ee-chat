# R8 rules to ignore missing SLF4J logger implementations
-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }