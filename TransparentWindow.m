//
//  TransparentWindow.m
//  Reflection
//
//  Created by Jon Drummond on 3/31/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TransparentWindow.h"


@implementation TransparentWindow

- (id)initWithContentRect: (NSRect)contentRect
				styleMask: (unsigned int)styleMask
				  backing: (NSBackingStoreType)bufferingType
					defer: (BOOL)deferCreation {
	
	if ((self = [super initWithContentRect: contentRect
								 styleMask: NSBorderlessWindowMask 
								   backing: bufferingType
								     defer: deferCreation])) {
										   
		[self setBackgroundColor: [NSColor clearColor]];
        [self setAlphaValue: 1.0];
		[self setOpaque: NO];
		[self setHasShadow: NO];
		[self setMovableByWindowBackground: NO];
		[self setCanBecomeKeyWindow: YES];
		
		[self setProcessesMouseEventTypes: JXMouseNone];
	}
	
	return self;
}

- (BOOL) canBecomeKeyWindow {
	return _canBecomeKeyWindow;
}

- (void) setCanBecomeKeyWindow:(BOOL)key {
	_canBecomeKeyWindow = key;
}

- (void) setProcessesMouseEventTypes: (JXProcessMouseEventType)types {
	_mouseEvents = types;
	if( _mouseEvents == JXMouseNone) {
		[self setIgnoresMouseEvents: YES];
		[self setAcceptsMouseMovedEvents: NO];
		return;
	}
	
	if( (_mouseEvents & JXMouseDown) ||  (_mouseEvents & JXMouseUp)) {
		[self setIgnoresMouseEvents: NO];
		
	}
	if( _mouseEvents & JXMouseMoved ) {
		[self setIgnoresMouseEvents: NO];
		[self setAcceptsMouseMovedEvents: YES];
	}
}

- (JXProcessMouseEventType)processesMouseEventTypes {
	return _mouseEvents;
}

- (void)mouseDown:(NSEvent*)event {
	if( (_mouseEvents & JXMouseDown))	{
		if( [[self delegate] respondsToSelector: @selector(mouseDown:inWindow:)] )
			[[self delegate] mouseDown: event inWindow: self];
	}
	[super mouseDown: event];
}

- (void)mouseUp:(NSEvent*)event {
	if( (_mouseEvents & JXMouseUp))	{
		if( [[self delegate] respondsToSelector: @selector(mouseUp:inWindow:)] )
			[[self delegate] mouseUp: event inWindow: self];
	}
	[super mouseUp: event];
}

- (void)mouseMoved:(NSEvent*)event {
	if( (_mouseEvents & JXMouseMoved))	{
		if( [[self delegate] respondsToSelector: @selector(mouseMoved:inWindow:)] ) {
			[[self delegate] mouseMoved: event inWindow: self];
		}
	}
	[super mouseMoved: event];
}

@end
