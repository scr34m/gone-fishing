//
//  WindowExtras.m
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "WindowExtras.h"


@implementation NSWindow (WindowExtras)
- (NSPoint)windowToScreenCoordinates:(NSPoint)point {
	NSPoint result;
	NSRect screenFrame = [[self screen] frame];

	//result = [self convertBaseToScreen:point]; // Doesn't work... it looks like the y co-ordinate is not inverted as necessary

	result.x = screenFrame.origin.x + _frame.origin.x + point.x;
	result.y = screenFrame.origin.y + screenFrame.size.height - (_frame.origin.y + point.y);

	return result;
}

- (NSPoint)screenToWindowCoordinates:(NSPoint)point { // Untested
	NSPoint result;
	NSRect screenFrame = [[self screen] frame];
	NSLog(@"screenToWindowCoordinates has not been tested");
	result.x = point.x - (screenFrame.origin.x + _frame.origin.x);
	result.y = screenFrame.origin.y + screenFrame.size.height - _frame.origin.y - point.y;

	return point; // To be completed
}



- (void)orderFrontWithTransition: (CGSTransitionType)type 
					     options: (CGSTransitionOption)options {
	
	if( [self isVisible] ) {
		[self orderFront: nil];
        //NSLog(@"Window already visible. Ordering front.");
		return;
	}
	float color[3]		= {0.0, 0.0, 0.0};
	BOOL transparent	= YES;
	float duration		= 0.75;
    
    [self setAlphaValue: 0.0];
    [self orderFront: nil];
    [self display];
	
	// setup the transition
	int handle;
	CGSTransitionSpec spec;
	handle = -1;	// assign our transition handle
	
	// specify our specifications
	spec.unknown1=0;
	spec.type = type;
	spec.option = options | ((transparent) ? (1<<7) : 0);	// "(1<<7)" is the transparent mask
	spec.backColour = color;
	spec.wid = [self windowNumber];					// windowNumber. 0 for whole desktop ;)
	
	// Let’s get a connection
	CGSConnection cgs= _CGSDefaultConnection();
	
	// Create a transition
	CGSNewTransition(cgs, &spec, &handle);
    [self setAlphaValue: 1.0];
	[self orderFront: nil];
	CGSInvokeTransition(cgs, handle, duration);
	usleep((useconds_t)(duration*1000000));	// wait for transition to finish
	CGSReleaseTransition(cgs, handle);
	handle=0;					 
}

- (void)orderOutWithTransition: (CGSTransitionType)type 
					   options: (CGSTransitionOption)options {
	
	if( ![self isVisible] ) {
		[self orderOut: nil];
		return;
	}
	
	float color[3]		= {0.0, 0.0, 0.0};
	BOOL transparent	= YES;
	float duration		= 0.75;
	
	// setup the transition
	int handle;
	CGSTransitionSpec spec;
	handle = -1;	// assign our transition handle
	
	// specify our specifications
	spec.unknown1=0;
	spec.type = type;
	spec.option = options | ((transparent) ? (1<<7) : 0);	// "(1<<7)" is the transparent mask
	spec.backColour = color;
	spec.wid = [self windowNumber];					// windowNumber. 0 for whole desktop ;)
	
	// Let’s get a connection
	CGSConnection cgs= _CGSDefaultConnection();
	
	// Create a transition
	CGSNewTransition(cgs, &spec, &handle);
	[self orderOut: nil];
	CGSInvokeTransition(cgs, handle, duration);
	usleep((useconds_t)(duration*1000000));	// wait for transition to finish
	CGSReleaseTransition(cgs, handle);
	handle=0;
}
@end
