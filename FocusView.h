//
//  FocusView.h
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FocusView : NSView {
	NSPoint		focusPoint;
	NSColor*	focusColor;
	float		focusRadius;
	NSTimer		*_timer;
	
	@private
	BOOL		_pulse;
	float		opacity;
}
- (void)clear;
- (void)fadeOut;
- (void)fadeIn;
- (void)pulse;

//@property (assign) NSPoint focusPoint;
- (NSPoint)focusPoint;
- (void)setFocusPoint: (NSPoint)point;

//@property (retain) NSColor *focusColor;
- (NSColor*)focusColor;
- (void)setFocusColor: (NSColor*)color;

//@property (assign) float focusRadius;
- (float)focusRadius;
- (void)setFocusRadius: (float)radius;

//@property (assign) float opacity;
- (float)opacity;
- (void)setOpacity: (float)opac;

@end
