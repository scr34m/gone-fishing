//
//  HUDWindow.h
//  HUDWindow
//
//  Created by Matt Gemmell on 12/02/2006.
//  Copyright 2006 Magic Aubergine. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TransparentWindow.h"

@interface HUDWindow : TransparentWindow {
    BOOL forceDisplay;
	NSButton *closeButton;
}

- (NSColor *)sizedHUDBackground;

- (void)setCloseButtonAction:(SEL)selector forTarget:(id)target;
- (BOOL)closeButtonActive;
- (void)hideCloseButton;
- (void)showCloseButton;
@end
