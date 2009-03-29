#import "CenteredTextFieldCell.h"

@implementation CenteredTextFieldCell

// stolen with love from http://www.cocoadev.com/index.pl?VerticallyCenteringTableViewItems

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSAttributedString *drawString = [self attributedStringValue];
	NSSize drawSize = [drawString size];
	
	//DLog(@"%@ - %@", [drawString string], NSStringFromSize(drawSize));
	//DLog(@"Content Size: %@, Cell Frame: %@", NSStringFromSize( [self cellSize]), NSStringFromSize(cellFrame.size));
	
	
	NSRange range;
	NSDictionary *attributes = [drawString attributesAtIndex:0 effectiveRange:&range];
	NSFont *theFont = [attributes objectForKey: NSFontAttributeName];
	//DLog(@"%@ (%f)", [theFont fontName], [theFont pointSize]);
	//DLog(@"Asc: %f, Desc: %f, xHeight: %f", [theFont ascender], [theFont descender], [theFont xHeight]);
	
	NSSize contentSize = [self cellSize];
	NSLayoutManager *lm = [[NSLayoutManager alloc] init];
	float lineHeight = [lm defaultLineHeightForFont: theFont];
	float drawHeight = (drawSize.height > cellFrame.size.height) ? cellFrame.size.height : drawSize.height;
	float offset = ((drawHeight - lineHeight) / 2.0);
	//DLog(@"Default Line Height: %f - drawHeight: %f", lineHeight, drawHeight);
	//DLog(@"Set offset: %f", offset);
    cellFrame.origin.y += (((cellFrame.size.height - drawSize.height) / 2.0) - offset );
    cellFrame.size.height = contentSize.height;
	
	[drawString drawInRect: cellFrame];
	
	[lm release];
}
@end
