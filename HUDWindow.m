//
//  HUDWindow.m
//  HUDWindow
//
//  Created by Matt Gemmell on 12/02/2006.
//  Copyright 2006 Magic Aubergine. All rights reserved.
//

#import "HUDWindow.h"

@interface HUDWindow(Extras)
- (void)setupCloseWidget;
@end

@implementation HUDWindow

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)styleMask 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag 
{
    if (self = [super initWithContentRect: contentRect 
                                styleMask: NSBorderlessWindowMask 
                                  backing: bufferingType 
                                    defer: flag]) {

        forceDisplay = NO;
        [self setAlphaValue: 1.0];
		[self setOpaque: NO];
		[self setHasShadow: NO];
		[self setMovableByWindowBackground: YES];
		[self setupCloseWidget];
        [self setBackgroundColor: [self sizedHUDBackground]];
		
		// NSPanel stuff
		// [self setFloatingPanel: YES];
		// [self setBecomesKeyOnlyIfNeeded: NO];
		
		// TransparentWindow stuff
		[self setProcessesMouseEventTypes: JXMouseMoved]; //JXMouseUp | JXMouseDown];
		[self setCanBecomeKeyWindow: YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(windowDidResize:) 
                                                     name:NSWindowDidResizeNotification 
                                                   object:self];
        
        return self;
    }
    return nil;
}
- (BOOL) canBecomeKeyWindow {
	return YES;
}
- (void)dealloc
{
    [closeButton release];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResizeNotification object: self];    
    [super dealloc];
}

- (void)awakeFromNib
{
	[self setupCloseWidget];
}

//- ( BOOL ) canBecomeKeyWindow {
//	return NO;
//}

- (BOOL)closeButtonActive {
	return [closeButton superview] ? YES : NO;
}
- (void)hideCloseButton {
	if(closeButton)	{ 
		//[closeButton setHidden: YES];
		[closeButton removeFromSuperview];
	}
}
- (void)showCloseButton {
	if(closeButton)	{
		//[closeButton setHidden: NO];
		[closeButton removeFromSuperview];
		[[self contentView] addSubview: closeButton];
	}
}

- (void)setupCloseWidget
{
	if(closeButton) return;
	
    closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(3.0, [self frame].size.height - 16.0, 13.0, 13.0)];
	
	[closeButton setKeyEquivalent: @"\E"];
    [closeButton setBezelStyle:NSRoundedBezelStyle];
    [closeButton setButtonType:NSMomentaryChangeButton];
    [closeButton setBordered:NO];
    [closeButton setImage: [[[NSImage alloc] initWithContentsOfFile: [[NSBundle bundleForClass: [self class]] pathForResource: @"hud_titlebar-close" ofType: @"tiff"]] autorelease]];
    [closeButton setTitle:@""];
    [closeButton setImagePosition:NSImageBelow];
    [closeButton setFocusRingType:NSFocusRingTypeNone];
	
    [closeButton setAction:@selector(orderOut:)];
    [closeButton setTarget:self];
}

- (void)setCloseButtonAction:(SEL)selector forTarget:(id)target {
	if(!closeButton) {
		[self setupCloseWidget];
	}
	
	[closeButton setTarget: target];
	[closeButton setAction: selector];
	[closeButton setKeyEquivalent: @"\E"];
	//[closeButton setHidden: NO];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
    [self setBackgroundColor:[self sizedHUDBackground]];
    if (forceDisplay) {
        [self display];
    }
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animationFlag
{
    forceDisplay = YES;
    [super setFrame:frameRect display:displayFlag animate:animationFlag];
    forceDisplay = NO;
}

- (NSColor *)sizedHUDBackground
{
    float alpha = 0.75;
    float titlebarHeight = 19.0;
    NSImage *bg = [[NSImage alloc] initWithSize:[self frame].size];
    [bg lockFocus];
    
    // Make background path
    NSRect bgRect = NSMakeRect(0, 0, [bg size].width, [bg size].height - titlebarHeight);
    int minX = NSMinX(bgRect);
    int midX = NSMidX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int midY = NSMidY(bgRect);
    int maxY = NSMaxY(bgRect);
    float radius = 10.0;
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    [bgPath lineToPoint:NSMakePoint(maxX, maxY)];
    [bgPath lineToPoint:NSMakePoint(minX, maxY)];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
    
    // Composite background color into bg
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:0.05 alpha:alpha];
	[bgColor set];
    [bgPath fill];
    
    // Make titlebar path
    NSRect titlebarRect = NSMakeRect(0, [bg size].height - titlebarHeight, [bg size].width, titlebarHeight);
    minX = NSMinX(titlebarRect);
    midX = NSMidX(titlebarRect);
    maxX = NSMaxX(titlebarRect);
    minY = NSMinY(titlebarRect);
    midY = NSMidY(titlebarRect);
    maxY = NSMaxY(titlebarRect);
    NSBezierPath *titlePath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [titlePath moveToPoint:NSMakePoint(minX, minY)];
    [titlePath lineToPoint:NSMakePoint(maxX, minY)];
    
    // Right edge and top-right curve
    [titlePath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [titlePath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, minY) 
                                      radius:radius];
    
    [titlePath closePath];
    
    // Titlebar
    NSColor *titlebarColor = ([[self title] length]) ? [NSColor colorWithCalibratedWhite:0.25 alpha:alpha] : bgColor;
    [titlebarColor set];
    [titlePath fill];
    
    // Title
    NSFont *titleFont = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
    NSMutableParagraphStyle *paraStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paraStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [paraStyle setAlignment:NSCenterTextAlignment];
    [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
    NSMutableDictionary *titleAttrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        titleFont,				NSFontAttributeName,
        [NSColor whiteColor],	NSForegroundColorAttributeName,
        paraStyle,				NSParagraphStyleAttributeName,
        nil];
    
    NSSize titleSize = [[self title] sizeWithAttributes:titleAttrs];
    // We vertically centre the title in the titlbar area, and we also horizontally 
    // inset the title by 19px, to allow for the 3px space from window's edge to close-widget, 
    // plus 13px for the close widget itself, plus another 3px space on the other side of 
    // the widget.
    NSRect titleRect = NSInsetRect(titlebarRect, 19.0, (titlebarRect.size.height - titleSize.height) / 2.0);
    [[self title] drawInRect: titleRect withAttributes: titleAttrs];
    [bg unlockFocus];
    
    return [NSColor colorWithPatternImage: [bg autorelease]];
}

- (void)setTitle:(NSString *)value {
    [super setTitle:value];
    [self windowDidResize:nil];
}


@end
