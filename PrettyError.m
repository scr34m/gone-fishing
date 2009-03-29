#import "PrettyError.h"
#import "HUDWindow.h"
#import "CenteredTextFieldCell.h"

@implementation PrettyError

static PrettyError *sharedError = nil;

+ (PrettyError*)sharedError
{
    @synchronized(self) {
        if (sharedError == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedError;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedError == nil) {
            sharedError = [super allocWithZone: zone];
			
            return sharedError;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
 
- (id)retain
{
    return self;
}
 
- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}
 
- (void)release
{
    //do nothing
}
 
- (id)autorelease
{
    return self;
}

- (id)init {
	self = [super init];
	
	[NSBundle loadNibNamed: @"PrettyErrorWindow" owner: self];
	
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset: NSMakeSize(-5, -5)];
	[shadow setShadowColor: [NSColor shadowColor]];
	[shadow setShadowBlurRadius: 10.0];
	
	NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paraStyle setAlignment: NSCenterTextAlignment];
	
	attributes = [[NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont fontWithName:@"Arial Black" size: 64],			NSFontAttributeName,
		[NSColor colorWithCalibratedWhite: 0.9 alpha: 1.0],		NSForegroundColorAttributeName, 
		paraStyle,												NSParagraphStyleAttributeName,
		shadow,													NSShadowAttributeName,
		nil] retain];
	
	return self;
}

- (void)awakeFromNib {
	[errorWindow setTitle: @""];
	[errorWindow setAlphaValue: 0.0];
	[errorWindow setMovableByWindowBackground: NO];
    [errorWindow setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
	[(HUDWindow*)errorWindow setCanBecomeKeyWindow: NO];
	
	CenteredTextFieldCell *errorCell = [[CenteredTextFieldCell alloc] initTextCell: @""];
	[errorCell setAlignment: NSCenterTextAlignment];
	[errorText setCell: errorCell];
	[errorCell release];
}

- (void)beginFade:(NSTimer*)timer {

	[NSTimer scheduledTimerWithTimeInterval: 0.025
									 target: self
								   selector: @selector(fadeWindow:)
								   userInfo: nil
									repeats: YES];
}

- (void)fadeWindow:(NSTimer*)timer {
	[errorWindow setAlphaValue: [errorWindow alphaValue] - 0.02];
	
	if( [errorWindow alphaValue] <= 0.0) {
		[timer invalidate];
		[errorWindow orderOut: nil];
	}
}

- (void)displayErrorMessage:(NSString*)error {
	
	NSAttributedString *myString = [[[NSAttributedString alloc] initWithString: error
																	attributes: attributes] autorelease];
	float strWidth = [myString size].width + 40;
	NSRect winFrame = [errorWindow frame];
	winFrame.size.width = strWidth;
	
	[errorText setAttributedStringValue: myString];
	
	[errorWindow setFrame: winFrame display: NO];
	[errorWindow center];
	[errorWindow orderFront: nil];
	[errorWindow setAlphaValue: 1.0];					
	[errorWindow display];
	
	[self performSelector: @selector(beginFade:) withObject: nil afterDelay: 0.5];
	/*[NSTimer scheduledTimerWithTimeInterval: 0.5
									 target: self
								   selector: @selector(beginFade:)
								   userInfo: nil
									repeats: NO];*/
									
				
}


@end
