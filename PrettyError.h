/* PrettyError */

#import <Cocoa/Cocoa.h>

@interface PrettyError : NSObject
{
    IBOutlet id errorText;
    IBOutlet id errorWindow;
	
	@private
	NSDictionary *attributes;
}
+ (PrettyError*)sharedError;
- (void)displayErrorMessage:(NSString*)error;

@end
