#import <Cocoa/Cocoa.h>
#import "TransparentWindow.h"
#import "FocusView.h"

@interface Controller : NSObject  {
	IBOutlet TransparentWindow *overlayWindow;
	FocusView				*_focusView;
	NSTimer					*_findSplashTimer;
    NSDictionary			*_keyMap;
    CGEventSourceRef        _eventSource;
	
    // Process Serial Numbers
	ProcessSerialNumber     _lastFrontProcess;
	ProcessSerialNumber		_wowProcess;
	
    // IBOutlets
    IBOutlet id dockMenu;
    IBOutlet id menuWindow;
    IBOutlet id prefWindow;
    IBOutlet id registerWindow;
    IBOutlet FocusView* focusView;
    IBOutlet id fishingModifierSegment;
    IBOutlet id lureModifierSegment;
    IBOutlet id poleModifierSegment;
    IBOutlet NSImageView *imageWell;
    
    @private;
	BOOL					needsToApplyLure;
	BOOL					isFishing;
    BOOL                    shouldPause;
    BOOL                    isRegistered;
}

- (BOOL)isFishing;
- (void)setIsFishing: (BOOL)fishing;

- (BOOL)shouldPause;
- (void)setShouldPause: (BOOL)pause;

- (BOOL)needsToApplyLure;
- (void)setNeedsToApplyLure: (BOOL)needsTo;

- (BOOL)isRegistered;
- (void)setIsRegistered: (BOOL)registered;

- (void)startFishing:(id)sender;
- (void)stopFishing:(id)sender;

- (IBAction)setFishingModifier:(id)sender;
- (IBAction)setLureModifier:(id)sender;
- (IBAction)setPoleModifier:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)registerProduct:(id)sender;
- (IBAction)launchWebsite:(id)sender;
@end
