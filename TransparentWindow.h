//
//  TransparentWindow.h
//  Reflection
//
//  Created by Jon Drummond on 3/31/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	JXMouseNone			= 0,
	JXMouseDown			= 1,
	JXMouseUp			= 2,
	JXMouseMoved		= 4
} JXProcessMouseEventType;


@interface TransparentWindow : NSWindow
{
	BOOL						_canBecomeKeyWindow;
	JXProcessMouseEventType		_mouseEvents;
}
- (id)initWithContentRect: (NSRect)contentRect
				styleMask: (unsigned int)styleMask
				  backing: (NSBackingStoreType)bufferingType
					defer: (BOOL)deferCreation;
					
- (void) setCanBecomeKeyWindow:(BOOL)key;
- (void) setProcessesMouseEventTypes: (JXProcessMouseEventType)types;
- (JXProcessMouseEventType)processesMouseEventTypes;
@end

@interface NSObject (TransparentWindowDelegate)
- (void)mouseDown: (NSEvent*)event inWindow: (NSWindow*)window;
- (void)mouseUp: (NSEvent*)event inWindow: (NSWindow*)window;
- (void)mouseMoved: (NSEvent*)event inWindow: (NSWindow*)window;

@end