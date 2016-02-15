#import <Carbon/Carbon.h>
#import <ScreenSaver/ScreenSaver.h>

#import "Controller.h"
#import "CGSPrivate.h"
#import "PrettyError.h"
#import "GrabWindow.h"
#import "WindowExtras.h"
#import "NSWindow+Transforms.h"

// 0.333333 0.14902 0.0823529 (bobber red)
// 0.737255 0.615686 0.478431 (bobber beige)
#define RED		0.737255  
#define GREEN	0.615686   
#define BLUE	0.478431 
#define ERROR   15 /* 0.080 */
#define ERRORFLT 0.080

@interface Controller (Internal)

// defaults accessors
- (BOOL)allowFishingInBackground;

- (void)resetTimers;
- (void)resetFishingTimer;
- (void)sendKeySequence:(NSString*)key withModifier: (unsigned)modifierMask;
- (void)activateWoW;
- (void)saveFrontProcess;
- (void)restoreFrontProcess;

// sending actions
- (void)cast;
- (void)applyLure;
- (void)toggleInterface;

// warcraft state
- (BOOL)isWoWOpen;
- (BOOL)isWoWFront;
- (ProcessSerialNumber)getWoWProcessSerialNumber;
- (int)getWOWWindowID:(ProcessSerialNumber)pSN;
@end

@implementation Controller


- (void)registerUserDefaults {

    NSColor *defaultColor = [NSColor colorWithCalibratedRed: RED green: GREEN blue: BLUE alpha: 1.0];
    NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
        // General Tab
        [NSNumber numberWithInt: NSOnState],    @"keepInterfaceVisible",
        [NSNumber numberWithInt: NSOnState],    @"allowBackgroundFishing",
        
        // Hotkeys tab
        @"1",                               @"fishingAbilityHotkey",
        @"2",                               @"lureHotkey",
        @"3",                               @"fishingPoleHotkey",
        [NSNumber numberWithBool: NO],      @"fishingModifierOption",
        [NSNumber numberWithBool: NO],      @"fishingModifierControl",
        [NSNumber numberWithBool: NO],      @"fishingModifierShift",
        [NSNumber numberWithBool: NO],      @"lureModifierOption",
        [NSNumber numberWithBool: NO],      @"lureModifierControl",
        [NSNumber numberWithBool: NO],      @"lureModifierShift",
        [NSNumber numberWithBool: NO],      @"poleModifierOption",
        [NSNumber numberWithBool: NO],      @"poleModifierControl",
        [NSNumber numberWithBool: NO],      @"poleModifierShift",
        
        // Bobber tab
        [NSArchiver archivedDataWithRootObject: defaultColor],  @"bobberColor",
        [NSNumber numberWithFloat: 35.0],                       @"bobberRadius",
        [NSNumber numberWithFloat: 0.0],                        @"bobberOffsetX",
        [NSNumber numberWithFloat: 0.0],                        @"bobberOffsetY",
        [NSNumber numberWithInt: 3],                            @"bobberCatchSensitivity",
    
        // Lures tab
        [NSNumber numberWithInt: NSOffState],   @"shouldApplyLure",
        [NSNumber numberWithInt: 5],            @"lureInterval",
        
        // Timer tab
        [NSNumber numberWithInt: NSOffState],   @"enableFishingTimer",
        [NSDate distantFuture],                 @"fishingTerminateTime",
        [NSNumber numberWithInt: NSOffState],   @"shouldQuitWoW",
        nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaultValues];
    
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"LicenseData"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
}


- (id) init
{
    self = [super init];
    if (self != nil) {
        // initialize user defaults
        [self registerUserDefaults];
        
		// load in the keymap dictionary
		_keyMap = [[NSDictionary dictionaryWithContentsOfFile: [[NSBundle bundleForClass: [self class]] pathForResource: @"CGKeyCodeMap" ofType: @"plist"]] retain];
        
        [self getWoWProcessSerialNumber];
    }
    return self;
}

- (void)dealloc {
    if(_eventSource) CFRelease(_eventSource);
    [_keyMap release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self setNeedsToApplyLure: NO];
    [self setIsFishing: NO];
    [self setShouldPause: NO];
    [self setIsRegistered: YES];
        
    id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
    
    [fishingModifierSegment setSelected: [[values valueForKey: @"fishingModifierOption"] boolValue] forSegment:  0];
    [fishingModifierSegment setSelected: [[values valueForKey: @"fishingModifierControl"] boolValue] forSegment:  1];
    [fishingModifierSegment setSelected: [[values valueForKey: @"fishingModifierShift"] boolValue] forSegment:  2];
    
    [lureModifierSegment setSelected: [[values valueForKey: @"lureModifierOption"] boolValue] forSegment:  0];
    [lureModifierSegment setSelected: [[values valueForKey: @"lureModifierControl"] boolValue] forSegment:  1];
    [lureModifierSegment setSelected: [[values valueForKey: @"lureModifierShift"] boolValue] forSegment:  2];
    
    [poleModifierSegment setSelected: [[values valueForKey: @"poleModifierOption"] boolValue] forSegment:  0];
    [poleModifierSegment setSelected: [[values valueForKey: @"poleModifierControl"] boolValue] forSegment:  1];
    [poleModifierSegment setSelected: [[values valueForKey: @"poleModifierShift"] boolValue] forSegment:  2];
    
    // set up overlay window
    [overlayWindow setCanBecomeKeyWindow: NO];
    [overlayWindow setLevel: NSFloatingWindowLevel];
    if([overlayWindow respondsToSelector: @selector(setCollectionBehavior:)]) {
        [overlayWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
    }
    
    [self tabView: nil didSelectTabViewItem: [[[NSTabViewItem alloc] initWithIdentifier: @"1"] autorelease]];

    if([prefWindow respondsToSelector: @selector(setCollectionBehavior:)])
        [prefWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
    [prefWindow center];
    
    //[[imageWell window] setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
}

#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"LicenseData"];
}

- (void)prefPulse {
    int i = 0;
    for(i = 0; i< 10; i++) {
        [prefWindow setScaleX: 1 + (i+1)*0.01 Y: 1 + (i+1)*0.01];
        usleep(8000);
    }
    
    for(i = 0; i< 10; i++) {
        [prefWindow setScaleX: 1.1 - (i+1)*0.01 Y: 1.1 - (i+1)*0.01];
        usleep(8000);
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
     // pulse the prefs window
    //CGAffineTransform original;
    //CGSGetWindowTransform(_CGSDefaultConnection(), [prefWindow windowNumber], &original);
    if( [prefWindow isVisible] && [prefWindow isKeyWindow]) {
        [prefWindow makeKeyAndOrderFront: nil];
        [prefWindow display];
        if([self respondsToSelector: @selector(performSelectorInBackground:withObject:)])
            [self performSelectorInBackground: @selector(prefPulse) withObject: nil];
    }
    //CGSSetWindowTransform(_CGSDefaultConnection(), [prefWindow windowNumber], original); 
}

- (void)applicationDidResignActive:(NSNotification *)aNotification {
    [menuWindow orderOut: nil];
}

#pragma mark Accessors

//@synthesize isFishing;
- (BOOL)isFishing { return isFishing; }
- (void)setIsFishing: (BOOL)fishing {
    isFishing = fishing;
    if(self.isFishing)  [[dockMenu itemWithTag: 10] setTitle: @"Status: Fishing"];
    else                [[dockMenu itemWithTag: 10] setTitle: @"Status: Stopped"];
}

//@synthesize shouldPause;
- (BOOL)shouldPause { return shouldPause || [prefWindow isVisible]; }
- (void)setShouldPause: (BOOL)pause {
    shouldPause = pause;
}

//@synthesize needsToApplyLure;
- (BOOL)needsToApplyLure { return needsToApplyLure; }
- (void)setNeedsToApplyLure: (BOOL)needsTo {
    needsToApplyLure = needsTo;
}

//@synthesize isRegistered;
- (BOOL)isRegistered { return isRegistered; }
- (void)setIsRegistered: (BOOL)registered {
    isRegistered = registered;
}

- (NSColor*)bobberColor {
    return [NSUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"bobberColor"]];
}

- (float)bobberRadius {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"bobberRadius"] floatValue];
}

- (float)bobberOffsetX {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"bobberOffsetX"] floatValue];
}

- (float)bobberOffsetY {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"bobberOffsetY"] floatValue];
}

- (float)whiteThreshold {
	switch([[[NSUserDefaults standardUserDefaults] objectForKey: @"bobberCatchSensitivity"] intValue]) {
		case 1:	return 0.91;
		case 2:	return 0.85;
		default:
		case 3:	return 0.75;
		case 4:	return 0.65;
		case 5:	return 0.50;
	}
}

- (float)bobberCatchSensitivity {
    int num = [[[NSUserDefaults standardUserDefaults] objectForKey: @"bobberCatchSensitivity"] intValue];
    
    if(num == 1)    return 0.15;
    if(num == 2)    return 0.125;
    if(num == 4)    return 0.075;
    if(num == 5)    return 0.05;
    return 0.1;
}

- (int)lureInterval {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"lureInterval"] intValue];
}

- (BOOL)shouldApplyLures {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"shouldApplyLure"] boolValue];
}

- (BOOL)allowFishingInBackground {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"allowBackgroundFishing"] boolValue];
}

- (BOOL)shouldKeepInterfaceVisible {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"keepInterfaceVisible"] boolValue];
}

- (NSDate*)fishingTerminateTime {
    return [[NSUserDefaults standardUserDefaults] objectForKey: @"fishingTerminateTime"];
}

- (BOOL)isFishingTimerEnabled {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"enableFishingTimer"] boolValue];
}

- (BOOL)shouldQuitWoW {
    return [[[NSUserDefaults standardUserDefaults] objectForKey: @"shouldQuitWoW"] boolValue];
}

#pragma mark Fishing Control

- (void)startFishing:(id)sender {

	_wowProcess = [self getWoWProcessSerialNumber];
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"Fishy"]];
	if(![self isWoWOpen]) {
		[self stopFishing: nil];
		[[PrettyError sharedError] displayErrorMessage: @"WoW is not open."];
		return;
	}
        
    // if we are just starting to fish, set the lure to apply
    if(!self.isFishing) {
        self.needsToApplyLure = YES;
    }
	
	[self resetTimers];
	[overlayWindow makeKeyAndOrderFront: nil];
	
	// apple lures & last
	[self applyLure];
	[self cast];
	
	// queue up bobber locater & fishing timer
	[self performSelector: @selector(locateBobber:) withObject: nil afterDelay: 4.0];
	[self performSelector: @selector(startFishing:) withObject: nil afterDelay: 22.0];
	
	self.isFishing = YES;
}

- (void)stopFishing:(id)sender {
    //NSLog(@"Stop Fishing.");
	self.isFishing = NO;
    self.needsToApplyLure = NO;
	[self resetTimers];
    [NSApp setApplicationIconImage: [NSImage imageNamed: @"Fishy"]];
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	[overlayWindow orderOut: nil];
}


- (void)resetTimers {

	[focusView fadeOut];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(locateBobber:) object: nil];
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(startFishing:) object: nil];
	
	[_findSplashTimer invalidate];	_findSplashTimer = nil;
}


#pragma mark Process & Window Functions

- (BOOL)isWoWFront {
	NSDictionary *frontProcess;
	if( frontProcess = [[NSWorkspace sharedWorkspace] activeApplication] ) {
		NSString *bundleID = [frontProcess objectForKey: @"NSApplicationBundleIdentifier"];
		if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isWoWOpen {

	NSDictionary *processDict;
	NSEnumerator *enumerator = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	while(processDict = [enumerator nextObject]) {
		NSString *bundleID = [processDict objectForKey: @"NSApplicationBundleIdentifier"];
		if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			return YES;
		}
	}
	return NO;
}

- (void)activateWoW {
	//[chatWindow resignKeyWindow];
	SetFrontProcess( &_wowProcess );
    //ProcessSerialNumber curProcess = {0, 0};
    //int waitCount = 0;
    //while( !IsProcessVisible(&_wowProcess) ) {
// (GetFrontProcess(&curProcess) == noErr) && (curProcess.lowLongOfPSN != _wowProcess.lowLongOfPSN || curProcess.highLongOfPSN != _wowProcess.highLongOfPSN)) {
   //     usleep(10000);
   //     waitCount++;
   //     if(waitCount >= 10) break;
   // }
    usleep(50000);
    //NSLog(@"Waited for %d ms to activate.", waitCount*10000);
}

- (void)quitWoW {
    ProcessSerialNumber pSN = [self getWoWProcessSerialNumber];
    if( pSN.lowLongOfPSN == kNoProcess) return;
    NSLog(@"Quitting WoW");
    
    // send Quit apple event
    OSStatus status;
    AEDesc targetProcess = {typeNull, NULL};
    AppleEvent theEvent = {typeNull, NULL};
    AppleEvent eventReply = {typeNull, NULL}; 
	
    status = AECreateDesc(typeProcessSerialNumber, &pSN, sizeof(pSN), &targetProcess);
	require_noerr(status, AECreateDesc);
    
    status = AECreateAppleEvent(kCoreEventClass, kAEQuitApplication, &targetProcess, kAutoGenerateReturnID, kAnyTransactionID, &theEvent);
	require_noerr(status, AECreateAppleEvent);
    
    status = AESend(&theEvent, &eventReply, kAENoReply + kAEAlwaysInteract, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
	require_noerr(status, AESend);
    
AESend:;
AECreateAppleEvent:;
AECreateDesc:;
	
	AEDisposeDesc(&eventReply); 
    AEDisposeDesc(&theEvent);
	AEDisposeDesc(&targetProcess);
}

- (void)saveFrontProcess {
	if( ![self allowFishingInBackground]) return;
	
	NSDictionary *frontProcess;
	if( frontProcess = [[NSWorkspace sharedWorkspace] activeApplication] ) {
		// NSLog(@"Saving front process: %@", frontProcess);
		_lastFrontProcess.highLongOfPSN = [[frontProcess objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue];
		_lastFrontProcess.lowLongOfPSN	= [[frontProcess objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue];
	} else {
		_lastFrontProcess.highLongOfPSN = kNoProcess;
		_lastFrontProcess.lowLongOfPSN	= kNoProcess;
	}
}

- (void)restoreFrontProcess {
	if( [self allowFishingInBackground] ) {
		// NSLog(@"restoring front process");
		SetFrontProcess(&_lastFrontProcess);
		usleep(50000);
	}
	//if( [chatWindow isVisible]) {
	//	[NSApp activateIgnoringOtherApps: YES];
	//	[chatWindow makeKeyAndOrderFront: nil];
	//}
}

- (ProcessSerialNumber)getWoWProcessSerialNumber {

	ProcessSerialNumber pSN = {kNoProcess, kNoProcess};
	NSDictionary *processDict;
	NSEnumerator *enumerator = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	while(processDict = [enumerator nextObject]) {
		NSString *bundleID = [processDict objectForKey: @"NSApplicationBundleIdentifier"];
		if( [bundleID isEqualToString: @"com.blizzard.worldofwarcraft"] ) {
			pSN.highLongOfPSN = [[processDict objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue];
			pSN.lowLongOfPSN  = [[processDict objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue];
			_wowProcess = pSN;
			return pSN;
		}
	}
	return pSN;
}

-(int)getWOWWindowID:(ProcessSerialNumber)pSN {
	CGError err = 0;
	int count = 0;
	CGSConnection connectionID = 0;
	CGSConnection myConnectionID = _CGSDefaultConnection();
	
    err = CGSGetConnectionIDForPSN(0, &pSN, &connectionID);
    if( err == noErr ) {
	
        err = CGSGetOnScreenWindowCount(myConnectionID, connectionID, &count);
        if( (err == noErr) && (count > 0) ) {
            int windowList[count];
            int actualIDs = 0;
            int i = 0;

            err = CGSGetOnScreenWindowList(myConnectionID, connectionID, count, windowList, &actualIDs);
            for(i = 0; i < actualIDs; i++) {
				CGSWindow window = windowList[i];
				NSString *windowTitle = NULL;
                
                uint32_t windowid[1] = {window};
                CFArrayRef windowArray = CFArrayCreate ( NULL, (const void **)windowid, 1 ,NULL);
                CFArrayRef windowsdescription = CGWindowListCreateDescriptionFromArray(windowArray);
                CFDictionaryRef windowdescription = (CFDictionaryRef)CFArrayGetValueAtIndex ((CFArrayRef)windowsdescription, 0);
                if(CFDictionaryContainsKey(windowdescription, kCGWindowName))
                {
                    CFStringRef windowName = CFDictionaryGetValue(windowdescription, kCGWindowName);
                    windowTitle = (NSString*)windowName;
                }
                CFRelease(windowArray);
                
				if(err == noErr && windowTitle) {
					return window;
				}
            }
        }
    }
	return 0;
}

#pragma mark Keystroke Functions

- (void)sendKeySequence:(NSString*)keySequence withModifier: (unsigned)modifierMask {
	[self getWoWProcessSerialNumber];
	CFRelease(CGEventCreate(NULL));		// hack to make CGEventCreateKeyboardEvent work... don't ask me
	NS_DURING {
		CGInhibitLocalEvents(TRUE);
		
		// hit any specified modifier keys
		CGEventRef cmdKeyDn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)55, TRUE);
		CGEventRef cmdKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)55, FALSE);
		if(cmdKeyDn && cmdKeyUp) {
            if(modifierMask & NSCommandKeyMask)
                CGEventPostToPSN(&_wowProcess, cmdKeyDn);
        }
        
		CGEventRef altKeyDn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)58, TRUE);
		CGEventRef altKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)58, FALSE);
		if(altKeyDn && altKeyUp) {
            if(modifierMask & NSAlternateKeyMask)
                CGEventPostToPSN(&_wowProcess, altKeyDn);
        }
        
		CGEventRef sftKeyDn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)56, TRUE);
		CGEventRef sftKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)56, FALSE);
		if(sftKeyDn && sftKeyUp) {
            if(modifierMask & NSShiftKeyMask)
                CGEventPostToPSN(&_wowProcess, sftKeyDn);
        }
        
		CGEventRef ctlKeyDn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)59, TRUE);
		CGEventRef ctlKeyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)59, FALSE);
		if(ctlKeyDn && ctlKeyUp) {
            if(modifierMask & NSControlKeyMask)
                CGEventPostToPSN(&_wowProcess, ctlKeyDn);
        }
		
		// post the key events
		unsigned i;
		for(i=0; i<[keySequence length]; i++) {
			NSString *character = [keySequence substringWithRange: NSMakeRange(i,1)];
			if( [character isEqualToString: @"\\"]) {
				// NSLog(@"%@ == %@", character, @"\\");
				if(++i < [keySequence length])
					character = [NSString stringWithFormat: @"\\%@", [keySequence substringWithRange: NSMakeRange(i,1)]];
			}
			id obj = [_keyMap objectForKey: [character lowercaseString]];
			if(obj && [obj isKindOfClass: [NSNumber class]]) {
				BOOL upperCase = ![[character lowercaseString] isEqualToString: character];
				CGKeyCode keyCode = [obj unsignedIntValue];
				// NSLog(@"Stroking key %@ (%d) %d", character, keyCode, upperCase);
				CGEventRef keyDn = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keyCode, TRUE);
				CGEventRef keyUp = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)keyCode, FALSE);
				if(upperCase)	CGEventPostToPSN(&_wowProcess, sftKeyDn);
				CGEventPostToPSN(&_wowProcess, keyDn);
				CGEventPostToPSN(&_wowProcess, keyUp);
				if(upperCase)	CGEventPostToPSN(&_wowProcess, sftKeyUp);
				
				if(keyDn) CFRelease(keyDn);
                if(keyUp) CFRelease(keyUp);
			}
		}
		
		// undo the modifier keys
		if( modifierMask & NSControlKeyMask)	CGEventPostToPSN(&_wowProcess, ctlKeyUp);
		if( modifierMask & NSShiftKeyMask)		CGEventPostToPSN(&_wowProcess, sftKeyUp);
		if( modifierMask & NSAlternateKeyMask)	CGEventPostToPSN(&_wowProcess, altKeyUp);
		if( modifierMask & NSCommandKeyMask)	CGEventPostToPSN(&_wowProcess, cmdKeyUp);
		
		// release modifier events
		if(cmdKeyDn) CFRelease(cmdKeyDn);
        if(cmdKeyUp) CFRelease(cmdKeyUp);
		if(altKeyDn) CFRelease(altKeyDn); 
        if(altKeyUp) CFRelease(altKeyUp);
		if(sftKeyDn) CFRelease(sftKeyDn); 
        if(sftKeyUp) CFRelease(sftKeyUp);
		if(ctlKeyDn) CFRelease(ctlKeyDn); 
        if(ctlKeyUp) CFRelease(ctlKeyUp);
		
		CGInhibitLocalEvents(FALSE);
    } NS_HANDLER {
        NSLog(@"Error during sendKeySequence: %@", keySequence);
        CGInhibitLocalEvents(FALSE);
    } NS_ENDHANDLER
}

- (void)toggleInterface {
	if( [self shouldKeepInterfaceVisible] ) {
		[self sendKeySequence: @"z" withModifier: NSAlternateKeyMask];
	}
}

- (void)cast {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    
    unsigned modifier = 0;
    if( [[settings objectForKey: @"fishingModifierOption"] boolValue] )     modifier |= NSAlternateKeyMask;
    if( [[settings objectForKey: @"fishingModifierControl"] boolValue] )    modifier |= NSControlKeyMask;
    if( [[settings objectForKey: @"fishingModifierShift"] boolValue] )      modifier |= NSShiftKeyMask;
        
    NSString *hotkey = [settings objectForKey: @"fishingAbilityHotkey"];
    if(!hotkey || ![hotkey length]) { // invalid hotkey
        [[PrettyError sharedError] displayErrorMessage: @"Invalid Fishing hotkey."];
        NSLog(@"Invalid Fishing hotkey.");
        [self stopFishing: nil];
        return;
    }
    
	[self sendKeySequence: [hotkey substringToIndex: 1] withModifier: modifier];
}


- (void)applyLure {
	if(self.needsToApplyLure && [self shouldApplyLures]) {
		self.needsToApplyLure = NO;
        
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        // click the lure
        unsigned modifier = 0;
        if( [[settings objectForKey: @"lureModifierOption"] boolValue] )     modifier |= NSAlternateKeyMask;
        if( [[settings objectForKey: @"lureModifierControl"] boolValue] )    modifier |= NSControlKeyMask;
        if( [[settings objectForKey: @"lureModifierShift"] boolValue] )      modifier |= NSShiftKeyMask;
        
        NSString *hotkey = [settings objectForKey: @"lureHotkey"];
        if(hotkey && [hotkey length] > 0) {
            usleep(1000000);
            [self sendKeySequence: [hotkey substringToIndex: 1] withModifier: modifier];
        } else {
            [[PrettyError sharedError] displayErrorMessage: @"Invalid Lure hotkey."];
            NSLog(@"Invalid Lure hotkey.");
        }
        
        modifier = 0;
        usleep(500000);
        
        // apply it to the rod
        if( [[settings objectForKey: @"poleModifierOption"] boolValue] )     modifier |= NSAlternateKeyMask;
        if( [[settings objectForKey: @"poleModifierControl"] boolValue] )    modifier |= NSControlKeyMask;
        if( [[settings objectForKey: @"poleModifierShift"] boolValue] )      modifier |= NSShiftKeyMask;
        
        hotkey = [settings objectForKey: @"fishingPoleHotkey"];
        if(hotkey && [hotkey length] > 0) {
            [self sendKeySequence: [hotkey substringToIndex: 1] withModifier: modifier];
            usleep(6*1000000); // sleep for 6 seconds (lure cast is 5)
        } else {
            [[PrettyError sharedError] displayErrorMessage: @"Invalid Pole hotkey."];
            NSLog(@"Invalid Pole hotkey.");
        }
        
        int extraTime = SSRandomIntBetween(4.0, 8.0);
        [self performSelector: @selector(triggerLure:) withObject: nil afterDelay: (([self lureInterval] * 60.0) + extraTime)];
	}
}

#pragma mark Fishing Callbacks


- (void)triggerLure:(id)timer {
	self.needsToApplyLure = YES;
	//NSLog(@"Time to apply another lure");
}

- (void)locateBobber:(id)timer {
    
    // check fishing timer
    if([self isFishingTimerEnabled]) {
        NSString *triggerTime = [[self fishingTerminateTime] descriptionWithCalendarFormat: @"%I:%M %p" timeZone: nil locale: nil];
        NSString *currentTime = [[NSDate date] descriptionWithCalendarFormat: @"%I:%M %p" timeZone: nil locale: nil];
        
        if( [currentTime isEqualToString: triggerTime] ) {
            NSLog(@"Terminating fishing at: %@", currentTime);
            [self stopFishing: nil];
            if([self shouldQuitWoW])
                [self quitWoW];
            return;
        }
    }
    
    // check if we should pause
	if([self shouldPause]) return;
    
	// NSLog(@"Scanning for the bobber.");
	// get a handle to WoW's window
	int windowID = [self getWOWWindowID: [self getWoWProcessSerialNumber]];
	
	if(windowID) {
		// hide the WoW Interface
		if( [self shouldKeepInterfaceVisible] ) {
			[self toggleInterface];
			usleep(200000);
		}
        
		//NSBitmapImageRep *bmWoW = [NSBitmapImageRep bitmapRepWithWindow: windowID];
        NSImage *wow = [NSImage imageWithBitmapRep: [NSBitmapImageRep bitmapRepWithWindow: windowID]];
        //[[imageWell window] orderFront: nil];
        //[imageWell setImage: wow];
        //[[imageWell window] display];
        // NSLog(@"Got WoW image: %@", wow);
		
		// restore the current process state
		if( [self shouldKeepInterfaceVisible] ) { 
			[self toggleInterface];
		}
		
		// search for the bobber
		NSPoint foundPt, foundPtQ1, foundPtQ4;
        foundPt = foundPtQ1 = foundPtQ4 = NSZeroPoint;
		int numFound = 0, foundX=0, foundY=0;
        int imgWidth = [wow size].width, imgHeight = [wow size].height;
	
		NSColor *bobberColor = [NSColor clearColor];
		if(wow) {
            //NSDate *start = [NSDate date];
            //NSLog(@"Scanning image: %d x %d", [bmWoW pixelsWide], [bmWoW pixelsHigh]);
            
			// break our search color into its components
			bobberColor = [self bobberColor];
			float bobberRed	= [bobberColor redComponent];//*255;
			float bobberGreen	= [bobberColor greenComponent];//*255;
			float bobberBlue	= [bobberColor blueComponent];//*255;
			
            // -----------
            int x, y;
            // the bitmap scanning version of this code
            /*unsigned char *data = [bmWoW bitmapData];
            int samplesPerPixel = [bmWoW samplesPerPixel], bytesPerRow = imgWidth * samplesPerPixel;
            BOOL isARGB = ([bmWoW bitmapFormat] & NSAlphaFirstBitmapFormat) ? YES : NO;
            int red = isARGB ? 1 : 0, green = isARGB ? 2 : 1, blue = isARGB ? 3 : 2;
            //NSLog(@"bytesPerRow = %d; samplesPerPixel = %d", bytesPerRow, samplesPerPixel);
            */

            // figure out system architecture
            /*
            BOOL isIntel;
            SInt32 sysArch;
            if (Gestalt(gestaltSysArchitecture, &sysArch) == noErr) {
                if(sysArch == gestaltIntel) isIntel = YES;
                else                        isIntel = NO;
            }
            
            // if it's intel, swap the indexes around
            if(isIntel) {
                if( samplesPerPixel == 4 && !isARGB) {
                    blue = 1;
                    green = 2;
                    red = 3;
                } else {
                    blue = 0;
                    green = 1;
                    red = 2;
                }
             }*/
            
			[wow lockFocus];
            float red, green, blue;
            // this search is over Q4 window space
            for (y=0; y<imgHeight; y+=2) {
                
                //NSColor *color = NSReadPixel(NSMakePoint(111, 111));
                //red	= [color redComponent];
                //green = [color greenComponent];
                //blue = [color blueComponent];
                //NSLog(@"Got Red: %f, Green: %f, Blue: %f", red, green, blue);
                //break;
                
                // unsigned char *pixel = data + bytesPerRow*y;
                for (x=0; x<imgWidth; x+=2) {
					NSColor *color = NSReadPixel(NSMakePoint(x, y));
					red	= [color redComponent];
					green = [color greenComponent];
					blue = [color blueComponent];
                    
					if((red > (bobberRed - ERRORFLT) && red < (bobberRed + ERRORFLT)) 
					   && (green > (bobberGreen - ERRORFLT) && green < (bobberGreen + ERRORFLT)) 
					   && (blue > (bobberBlue - ERRORFLT) && blue < (bobberBlue + ERRORFLT)) ) {
                        
						if(!foundX && !foundY) {
							foundX = x; foundY = y;
							numFound ++;
                        } else {
							// only count this point if it's within [bobberRadius] pixels of the average
							if(   abs(x - (foundX / (numFound*1.0f))) < [self bobberRadius]*2.0f
                               && abs(y - (foundY / (numFound*1.0f))) < [self bobberRadius]*2.0f) {
								
                                foundX += x;
								foundY += y;
								numFound ++;
							} else { ; }
						}
					}
                    //pixel += samplesPerPixel + samplesPerPixel; // since we are skipping over 2 pixels at a time
                }
            }
			[wow unlockFocus];

            // NSLog(@"Completed scan in %f seconds.", [start timeIntervalSinceNow]*-1.0);
            foundPt.x = foundX / (numFound*1.0);
            foundPt.y = foundY / (numFound*1.0);
            
            foundPtQ1 = foundPtQ4 = foundPt;
            foundPtQ4.y = imgHeight - foundPtQ1.y;  // Q4 for NSImage, Q1 for NSBitmapImageRep
            
            // NSLog(@"%d matches for avg loc: %@ in Q1w, %@ in Q4w", numFound, NSStringFromPoint(foundPtQ1), NSStringFromPoint(foundPtQ4));
        } else {
            // NSLog(@"The image returned for the window appears to be invalid.");
        }
        
		if(numFound >= 3) {
			foundPtQ1.x = foundPtQ4.x = foundPtQ1.x + [self bobberOffsetX];
			foundPtQ1.y += [self bobberOffsetY];  // since it's in Q1
			foundPtQ4.y -= [self bobberOffsetY];  // since it's in Q4
            
			// get the point in the window to a point on the screen
			CGRect wowRect;
			CGSGetWindowBounds(_CGSDefaultConnection(), windowID, &wowRect);
            NSPoint screenPt = foundPtQ1;
			screenPt.x += wowRect.origin.x;
			screenPt.y += ([[overlayWindow screen] frame].size.height - (wowRect.origin.y + wowRect.size.height));
            // NSLog(@"Found pt in Q1 screen space: %@", NSStringFromPoint(screenPt));
			// now we have screen point in Q1 space
            
			// create new window bounds
			NSRect newRect = NSZeroRect;
			newRect.origin = screenPt;
			newRect = NSInsetRect(newRect, ([self bobberRadius]+20)*-1.0, ([self bobberRadius]+20)*-1.0);
			[overlayWindow setFrame: newRect display: YES];
            
            [focusView setFocusRadius: [self bobberRadius]];
			[focusView setFocusColor: bobberColor];
			[focusView setFocusPoint: NSMakePoint(newRect.size.width / 2.0, newRect.size.height / 2.0)];
			if([self isWoWFront])	[focusView fadeIn];
			else					[focusView pulse];
            [focusView setNeedsDisplay: YES];
			
			// setup the splash scan timer
			//NSDictionary *windowPtDict = [self dictionaryFromPoint: foundPtQ4];
			//NSDictionary *screenPtDict = [self dictionaryFromPoint: screenPt];
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity: 4];
			[userInfo setObject: [NSValue valueWithPoint: foundPtQ4] forKey: @"WindowPoint"];
			[userInfo setObject: [NSValue valueWithPoint: screenPt] forKey: @"ScreenPoint"];
			[userInfo setObject: [NSNumber numberWithInt: windowID] forKey: @"WindowID"];
			[userInfo setObject: [NSNumber numberWithInt: numFound] forKey: @"Count"];
			
			// and off it goes
			_findSplashTimer = [NSTimer scheduledTimerWithTimeInterval: 0.05 
																target: self 
															  selector: @selector(scanForSplash:) 
															  userInfo: userInfo
															   repeats: YES];
		} else {
			// otherwise, restart the bobber scan timer
			[self performSelector: @selector(locateBobber:) withObject: nil afterDelay: 2.0];
		}
		// NSLog(@"Search took %f seconds", [start timeIntervalSinceNow]*-1.0);
	}
}

BOOL _updateDockIcon = YES;
- (void)scanForSplash:(id)timer {
    //NSDate *start = [NSDate date];
	if([self shouldPause]) return;
    
	NS_DURING {
		BOOL wowIsFront		= [self isWoWFront];
		BOOL allowFishInBG	= [self allowFishingInBackground];
		// [overlayWindow setIsVisible: wowIsFront];
		if(!wowIsFront && !allowFishInBG)	return;
		
		// are we fishing in the background?
		BOOL fishInBG = (!wowIsFront && allowFishInBG) ? YES : NO; //[bobberFishInBG state] ? YES : NO;
		
		// get number of color matches on the bobber and WoW's WindowID
		int count	  = [[[timer userInfo] objectForKey: @"Count"] intValue];
		int windowID  = [[[timer userInfo] objectForKey: @"WindowID"] intValue];
		
		// get our bobber position
		NSPoint screenPt = [[[timer userInfo] objectForKey: @"ScreenPoint"] pointValue];
		NSPoint windowPt = [[[timer userInfo] objectForKey: @"WindowPoint"] pointValue];
		NSPoint thePoint = fishInBG ? windowPt : screenPt;
		
		// determine our bobber scan rect
		NSRect bobberArea = NSZeroRect; bobberArea.origin = thePoint;
		if(!fishInBG) bobberArea.origin.y = [[overlayWindow screen] frame].size.height - bobberArea.origin.y;
		float radius = [self bobberRadius]*-1.0;
		bobberArea = NSInsetRect(bobberArea, radius, radius);
		
		// fishing in background              ?         use CoreGraphics to get the window (medium speed)           :              use QuickDraw (fast)
		//NSBitmapImageRep *bmBobber = fishInBG ? [NSBitmapImageRep bitmapRepWithRect: bobberArea inWindow: windowID] : [NSBitmapImageRep bitmapRepWithScreenShotInRect: bobberArea];
		NSImage *wow = fishInBG ? [NSImage imageWithBitmapRep: [NSBitmapImageRep bitmapRepWithRect: bobberArea inWindow: windowID]] : [NSImage imageWithScreenShotInRect: bobberArea];
		if(!wow) return;
		
		// alternate updating the dock icon
		if(_updateDockIcon) {
			[NSApp setApplicationIconImage: wow];
			_updateDockIcon = NO;
		} else {
			_updateDockIcon = YES;
		}
        
		// scan the image for a splash
		int hits = 0, x, y;
		int imgWidth = [wow size].width, imgHeight = [wow size].height;
		/*
		 unsigned char *data = [bmBobber bitmapData];
		 int imgWidth = [bmBobber pixelsWide], imgHeight = [bmBobber pixelsHigh];
		 int samplesPerPixel = [bmBobber samplesPerPixel], bytesPerRow = imgWidth * samplesPerPixel;
		 BOOL isARGB = ([bmBobber bitmapFormat] & NSAlphaFirstBitmapFormat) ? YES : NO;
		 int red = isARGB ? 1 : 0, green = isARGB ? 2 : 1, blue = isARGB ? 3 : 2; */
		
		float whiteThreshold = [self whiteThreshold];

        [wow lockFocus];
        for (x=0; x<imgWidth; x++) {
			//unsigned char *pixel = data + bytesPerRow*x;
			for (y=0; y<imgHeight; y++) {
				NSColor *color = NSReadPixel(NSMakePoint(x, y));
                
				if(([color redComponent]   > whiteThreshold) &&
				   ([color greenComponent] > whiteThreshold) &&
				   ([color blueComponent]  > whiteThreshold) ) {
					hits++;
					//if(hits > 2)	goto done;
				}
				//  pixel += samplesPerPixel;
			}
		}
		[wow unlockFocus];
		// NSLog(@"Splash scanc took %f seconds", [start timeIntervalSinceNow]*-1.0);
		
	done:;
		if(hits)
            ; //NSLog(@"FOUND WHITE COLOR: %d count, %d hits", count, hits);
		
		BOOL enoughWhite = NO;
		//if(hits) NSLog(@"%d hits; %d count... %.2f", hits, count, count * [self bobberCatchSensitivity]);
		if(hits >= count * [self bobberCatchSensitivity]) {
			enoughWhite = YES;
			//NSLog(@"hits >= %.2f with %.3f", count * [self bobberCatchSensitivity], [self bobberCatchSensitivity]);
		}
		
		if(enoughWhite) {
			// update dock image if we haven't already
			if(_updateDockIcon) {
				[NSApp setApplicationIconImage: wow];
				// [NSApp setApplicationIconImage: [NSImage imageWithBitmapRep: [NSBitmapImageRep correctBitmap: bmBobber]]];
			}
			
			// stop the splash timer
			[_findSplashTimer invalidate];	_findSplashTimer = nil;
			[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(startFishing:) object: nil];
			
			// create a CGPoint to click
			float screenHeight = [[overlayWindow screen] frame].size.height;
			CGPoint clickPt = CGPointMake(screenPt.x, screenHeight - screenPt.y);
			
			// get ahold of the previous mouse position
//			NSPoint nsPreviousPt = [NSEvent mouseLocation];
//			nsPreviousPt.y = screenHeight - nsPreviousPt.y;
//			CGPoint previousPt = CGPointMake(nsPreviousPt.x, nsPreviousPt.y);
			
			CGInhibitLocalEvents(TRUE);
			// activate WoW if it isn't already
			[self saveFrontProcess];
			[self activateWoW];
			
			usleep(500000);
			
			NS_DURING {
				
				// post a mouse up event to move the mouse into location
//				CGPostMouseEvent(previousPt, FALSE, 2, FALSE, FALSE);
				
				// create event source
				if(!_eventSource) _eventSource = CGEventSourceCreate(kCGEventSourceStatePrivate);
				
				// configure the various events
				CGEventRef moveToBobber = CGEventCreateMouseEvent(_eventSource, kCGEventMouseMoved, clickPt, kCGMouseButtonLeft);
//				CGEventRef moveToPrevPt = CGEventCreateMouseEvent(_eventSource, kCGEventMouseMoved, previousPt, kCGMouseButtonLeft);
				CGEventRef rightClickDn = CGEventCreateMouseEvent(_eventSource, kCGEventRightMouseDown, clickPt, kCGMouseButtonRight);
				CGEventRef rightClickUp = CGEventCreateMouseEvent(_eventSource, kCGEventRightMouseUp, clickPt, kCGMouseButtonRight);
				
				// bug in Tiger... event type isn't set in the Create method
				CGEventSetType(rightClickDn, kCGEventRightMouseDown);
				CGEventSetType(rightClickUp, kCGEventRightMouseUp);
				CGEventSetType(moveToBobber, kCGEventMouseMoved);
//				CGEventSetType(moveToPrevPt, kCGEventMouseMoved);
				
				// post the mouse events
				CGEventPostToPSN(&_wowProcess, moveToBobber);
				usleep(100000);	// wait 0.1 sec
				CGEventPostToPSN(&_wowProcess, rightClickDn);
				CGEventPostToPSN(&_wowProcess, rightClickUp);
				usleep(100000); // wait 0.1 sec
//				CGEventPostToPSN(&_wowProcess, moveToPrevPt);

				// release events
				if(rightClickDn)    CFRelease(rightClickDn); 
				if(rightClickUp)    CFRelease(rightClickUp); 
				if(moveToBobber)    CFRelease(moveToBobber);
//				if(moveToPrevPt)    CFRelease(moveToPrevPt);
				
				 // old way I did it (works fine though)
				 CGDisplayMoveCursorToPoint(kCGDirectMainDisplay, clickPt);
				 
				 CGPostMouseEvent(clickPt, TRUE, 2, FALSE, TRUE);
				 CGPostMouseEvent(clickPt, FALSE, 2, FALSE, FALSE);
				 
				 // move the mosue back to where it came from
//				 CGPostMouseEvent(previousPt, TRUE, 1, FALSE);
				
			} NS_HANDLER {
				CGInhibitLocalEvents(FALSE);
			} NS_ENDHANDLER
			
			// restore state
			[self restoreFrontProcess];
			CGInhibitLocalEvents(FALSE);
			
			// start fishing again!
			[self performSelector: @selector(startFishing:) withObject: nil afterDelay: SSRandomIntBetween(2.0, 4.0)];
		}
    } NS_HANDLER;
    NS_ENDHANDLER
}

#pragma mark IBActions

- (IBAction)launchWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.savorydeviate.com/gonefishing"]];
}

- (IBAction)showPreferences:(id)sender {
    
    //[prefWindow center];
    [prefWindow orderFrontWithTransition: CGSSwap options: CGSInOut];
    [prefWindow makeKeyAndOrderFront: nil];
    
}

- (IBAction)setFishingModifier:(id)sender {
    //[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: [sender isSelectedForSegment: 0]] forKey: @"fishingModifierOption"];
    //[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: [sender isSelectedForSegment: 1]] forKey: @"fishingModifierControl"];
    //[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: [sender isSelectedForSegment: 2]] forKey: @"fishingModifierShift"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 0]] 
                                                               forKey: @"fishingModifierOption"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 1]] 
                                                               forKey: @"fishingModifierControl"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 2]] 
                                                               forKey: @"fishingModifierShift"];
}

- (IBAction)setLureModifier:(id)sender {
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 0]] 
                                                               forKey: @"lureModifierOption"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 1]] 
                                                               forKey: @"lureModifierControl"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 2]] 
                                                               forKey: @"lureModifierShift"];
}

- (IBAction)setPoleModifier:(id)sender {
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 0]] 
                                                               forKey: @"poleModifierOption"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 1]] 
                                                               forKey: @"poleModifierControl"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [NSNumber numberWithBool: [sender isSelectedForSegment: 2]] 
                                                               forKey: @"poleModifierShift"];
}

#pragma mark TabView Delegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    int newHeight = 502;
    if([[tabViewItem identifier] isEqualToString: @"1"]) {
        newHeight = 346;
    }
    if([[tabViewItem identifier] isEqualToString: @"2"]) {
        newHeight = 502;
    }
    if([[tabViewItem identifier] isEqualToString: @"3"]) {
        newHeight = 207;
    }
    if([[tabViewItem identifier] isEqualToString: @"4"]) {
        newHeight = 324;
    }
    if([[tabViewItem identifier] isEqualToString: @"5"]) {
        newHeight = 276;
    }
    
    NSRect newFrame = [prefWindow frame];
    newFrame.size.height =	newHeight + ([prefWindow frame].size.height - [[prefWindow contentView] frame].size.height);
    newFrame.origin.y +=	([[prefWindow contentView] frame].size.height - newHeight); // Origin moves by difference in two views
    newFrame.origin.x +=	([[prefWindow contentView] frame].size.width - 387)/2; // Origin moves by difference in two views, halved to keep center alignment
    
    /* // resolution independent resizing
     float vdiff = ([newView frame].size.height - [[mainWindow contentView] frame].size.height) * [mainWindow userSpaceScaleFactor];
     newFrame.origin.y -= vdiff;
     newFrame.size.height += vdiff;
     float hdiff = ([newView frame].size.width - [[mainWindow contentView] frame].size.width) * [mainWindow userSpaceScaleFactor];
     newFrame.size.width += hdiff;*/
    
    [prefWindow setFrame: newFrame display: tabView ? YES : NO animate: tabView ? YES : NO];
}

@end
