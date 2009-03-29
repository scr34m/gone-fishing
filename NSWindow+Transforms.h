//
//  NSWindow+Transforms.h
//  JDImageView
//
//  Created by Jon Drummond on 11/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CGSPrivate.h"
#import <AppKit/NSWindow.h>

@interface NSWindow (Transforms)

- (NSPoint)windowToScreenCoordinates:(NSPoint)point;
- (NSPoint)screenToWindowCoordinates:(NSPoint)point;

- (void)rotate:(double)radians;
- (void)rotate:(double)radians about:(NSPoint)point;

- (void)scaleX:(double)x Y:(double)y;
- (void)setScaleX:(double)x Y:(double)y;
- (void)scaleX:(double)x Y:(double)y about:(NSPoint)point concat:(BOOL)concat;

- (void)reset;

@end