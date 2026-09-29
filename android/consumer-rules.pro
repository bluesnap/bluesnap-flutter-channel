# Applied to apps that depend on this plugin (R8 in release builds).

# The Cardinal Mobile SDK (3-D Secure, pulled in by bluesnap-android) bundles a
# relocated json-smart whose optional ASM bean accessors are not shipped.
# AGP 8+ fails R8 on missing classes unless they are declared.
-dontwarn com.cardinalcommerce.dependencies.internal.minidev.asm.**

# DataConverter.toMap serializes SDK result objects (SdkResult, BillingContactInfo,
# ShippingContactInfo and their ContactInfo superclass) with Gson reflection. Their
# field names become the map keys returned to Dart, so R8 must not rename them.
-keepclassmembers class com.bluesnap.androidapi.models.** { <fields>; }
