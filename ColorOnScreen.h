//
//  ColorOnScreen.h
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (ColorOnScreen)

+ (NSColor *)colorOnScreenAtPoint:(NSPoint)point;
+ (NSColor *)colorFromRGBColor:(RGBColor)color;

@end