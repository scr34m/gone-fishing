//
//  WindowExtras.h
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CGSPrivate.h"

@interface NSWindow (WindowExtras)

- (NSPoint)windowToScreenCoordinates:(NSPoint)point;
- (NSPoint)screenToWindowCoordinates:(NSPoint)point;

- (void)orderFrontWithTransition: (CGSTransitionType)type 
					     options: (CGSTransitionOption)options;
- (void)orderOutWithTransition: (CGSTransitionType)type 
					   options: (CGSTransitionOption)options;
@end
