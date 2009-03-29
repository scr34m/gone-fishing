//
//  FocusView.m
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "FocusView.h"
#import "RoundedBezierPath.h"
#import "ColorOnScreen.h"


@implementation FocusView

- (id) init {
	self = [super init];
	if (self != nil) {
		[self setFocusColor: [NSColor clearColor]];
        [self setOpacity: 1.0];
	}
	return self;
}

- (void) dealloc {
    [self setOpacity: 0.0];
	[focusColor release];	focusColor = nil;
	[_timer invalidate];	_timer = nil;
    
	[super dealloc];
}


- (BOOL)acceptsFirstResponder {
	return NO;
}

- (BOOL)isOpaque {
	return NO;
}

- (void)drawRect: (NSRect)rect {
	[[NSColor clearColor] set];
	[NSBezierPath fillRect: [self frame]];
	
	if(![self focusPoint].x && ![self focusPoint].y)	return;
	
	NSColor *color = [[self focusColor] colorWithAlphaComponent: [self opacity]];
	[color set];
	
	// NSLog(@"drawRect at %@", NSStringFromPoint(_focusPoint));
	NSRect focusBox = NSZeroRect;
	focusBox.origin = [self focusPoint];
	float radius = ([self focusRadius]+7)*-1.0;
	NSBezierPath *focusPath = [NSBezierPath bezierPathWithRoundRectInRect: NSInsetRect(focusBox, radius, radius) radius: 15.0 ];
	[focusPath setLineWidth: 5.0];
	
	[focusPath stroke];
    
	//float radius2 = ([self focusRadius]+1)*-1.0;
	//NSBezierPath *realPath = [NSBezierPath bezierPathWithRect: NSInsetRect(focusBox, radius2, radius2)];
	//[realPath setLineWidth: 1.0];
	//[realPath stroke];
    
	[super drawRect: rect];
}

/*
 - (void)mouseUp:(NSEvent*)event {
 if( [event type] & NSLeftMouseUp ) {
 ;
 }
 }
 
 - (void)mouseDown:(NSEvent*)event {
 //DLog(@"SketchView: mouseDown");
 NSPoint pt = [event locationInWindow];
 if( [event type] & NSLeftMouseDown ) {
 [self setFocusPoint: pt];
 }
 }*/
/*
 - (void)mouseMoved:(NSEvent *)event {
 NSPoint pt = [event locationInWindow];
 NSLog(@"Mouse moved!");
 [self setFocusPoint: pt];
 [self setFocusColor: [NSColor colorOnScreenAtPoint: pt]];
 }*/
/*
 - (void)mouseDragged:(NSEvent*)event {
 //DLog(@"SketchView: mouseDragged");
 NSPoint pt = [event locationInWindow];
 if(	[event type] & NSLeftMouseDragged ) {
 [self setFocusPoint: pt];
 }
 }*/

- (void)stepFadeOut:(id)timer {
	// NSLog(@"stepFadeOut:");
    [self setOpacity: [self opacity] - 0.05];
	if([self opacity] <= 0.0) {
		[self clear];
		_pulse = NO;
	} else {
		[NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(stepFadeOut:) userInfo: nil repeats: NO];
	}
	[self setNeedsDisplay: YES];
}

- (void)stepFadeIn:(id)timer {
    [self setOpacity: [self opacity] + 0.05];
	if([self opacity] >= 1.0) {
        [self setOpacity: 1.0];
		if(_pulse)	[self fadeOut];
	} else {
		[NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(stepFadeIn:) userInfo: nil repeats: NO];
	}
	[self setNeedsDisplay: YES];
}

- (void)fadeOut {
	
	if( [[self focusColor] alphaComponent] == 0.0 )	return;
    
    [self setOpacity: 1.0];
	[NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(stepFadeOut:) userInfo: nil repeats: NO];
}

- (void)fadeIn {
    [self setOpacity: 0.0];
	[NSTimer scheduledTimerWithTimeInterval: 0.05 target: self selector: @selector(stepFadeIn:) userInfo: nil repeats: NO];
}

- (void)pulse {
	_pulse = YES;
	[self fadeIn];
}

- (void)clear {
	[self setFocusColor: [NSColor clearColor]];
	[self setFocusPoint: NSZeroPoint];
    [self setOpacity: 0.0];
}

- (NSPoint)focusPoint { return focusPoint; }
- (void)setFocusPoint: (NSPoint)point {
    [self setOpacity: 1.0];
	focusPoint = point;
	[self setNeedsDisplay: YES];
}

- (NSColor*)focusColor { return focusColor; }
- (void)setFocusColor: (NSColor*)color {
    [self setOpacity: 1.0];
	[focusColor release];
	focusColor = [color retain];
	[self setNeedsDisplay: YES];
}

- (float)focusRadius { return focusRadius; }
- (void)setFocusRadius: (float)radius {
	focusRadius = radius;
	if(focusRadius < 0) focusRadius = 0;
}

- (float)opacity { return opacity; }
- (void)setOpacity: (float)opac {
    opacity = opac;
}

@end
