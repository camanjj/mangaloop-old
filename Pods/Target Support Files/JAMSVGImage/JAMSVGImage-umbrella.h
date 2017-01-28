#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JAMStyledBezierPath.h"
#import "JAMStyledBezierPathFactory.h"
#import "JAMSVGGradientParts.h"
#import "JAMSVGParser.h"
#import "JAMSVGImage.h"
#import "UIImage+SVG.h"
#import "JAMSVGButton.h"
#import "JAMSVGImageView.h"
#import "JAMSVGUtilities.h"

FOUNDATION_EXPORT double JAMSVGImageVersionNumber;
FOUNDATION_EXPORT const unsigned char JAMSVGImageVersionString[];

