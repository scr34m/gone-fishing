//
//  RoundedRectangle.h
//  Reflection
//
//  Created by Jon Drummond on 3/31/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath(RoundedRectangle)
+ (NSBezierPath*)bezierPathWithRoundRectInRect:(NSRect)aRect radius:(float)radius;
+ (NSBezierPath *) bezierPathWithRoundedRect: (NSRect) aRect cornerRadius: (double) cRadius;
@end
