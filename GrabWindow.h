//
//  GrabWindow.h
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (GrabWindow)
//+ (NSImage*)imageWithWindow:(int)wid;
//+ (NSImage*)imageWithRect: (NSRect)rect inWindow:(int)wid;
+ (NSImage*)imageWithCGContextCaptureWindow: (int)wid;
+ (NSImage*)imageWithBitmapRep: (NSBitmapImageRep*)rep;
+ (NSImage *)imageWithScreenShotInRect:(NSRect)rect;
@end

@interface NSBitmapImageRep (GrabWindow)
+ (NSBitmapImageRep*)correctBitmap: (NSBitmapImageRep*)rep;
+ (NSBitmapImageRep*)bitmapRepFromNSImage:(NSImage*)image;
+ (NSBitmapImageRep*)bitmapRepWithWindow:(int)wid;
+ (NSBitmapImageRep*)bitmapRepWithRect: (NSRect)rect inWindow:(int)wid;
+ (NSBitmapImageRep*)bitmapRepWithScreenShotInRect:(NSRect)rect;
@end