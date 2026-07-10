#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.maskedsyntax.Steepr.watchkitapp";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "BrandGreen" asset catalog color resource.
static NSString * const ACColorNameBrandGreen AC_SWIFT_PRIVATE = @"BrandGreen";

/// The "SteeprLogo" asset catalog image resource.
static NSString * const ACImageNameSteeprLogo AC_SWIFT_PRIVATE = @"SteeprLogo";

#undef AC_SWIFT_PRIVATE
