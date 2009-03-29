//
//  ColorOnScreen.m
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ColorOnScreen.h"

@implementation NSColor (ColorOnScreen)

+ (NSColor *)colorOnScreenAtPoint:(NSPoint)point
{
	RGBColor color;
	NSPoint newPoint;
	
	// Move the origin point to the top left instead of the bottom left
	newPoint = point;
	newPoint.y = [[NSScreen mainScreen] frame].size.height - point.y;
	
	// Here's where the magic happens. This grabs the color of the screen at a specific point
	GetCPixel(newPoint.x, newPoint.y, &color);
	
	return [self colorFromRGBColor:color];
}

+ (NSColor *)colorFromRGBColor:(RGBColor)color
{
	float red, green, blue;
	
	// 65535 is the max for the color
	// so we divide it by that to find the float value (0.0-1.0)
	red = (float)color.red/65535;
	green = (float)color.green/65535;
	blue = (float)color.blue/65535;
	
	return [self colorWithCalibratedRed:red green:green blue:blue alpha:1.0];
}

@end