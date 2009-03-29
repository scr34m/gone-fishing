//
//  GrabWindow.m
//  WoWFishingBot
//
//  Created by Jon Drummond on 5/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GrabWindow.h"
#import "CGSPrivate.h"

#define LEOPARD 0x1050
#define TIGER   0x1040

@implementation NSBitmapImageRep (GrabWindow)

CFArrayRef windowIDsArray = NULL;

+ (NSBitmapImageRep*)correctBitmap: (NSBitmapImageRep*)rep {
    
    /*// <rdar://problem/5557483> 10.5: NSBitmapImageRep created with CGImage initially reports bytesPerRow=bytesPerPlane=0
     When an NSBitmapImageRep is created by referencing a CGImage, using -initWithCGImage:, 
     it reports most of its properties correctly, but initially reports zero for bytesPerRow and bytesPerPlane.
     
     This is easily corrected by asking the NSBitmapImageRep for its -bitmapData, which prompts the CGImage's 
     pixel data to be unpacked and the values of those properties to be correctly established.  But the relative
     order of asking the NSBitmapImageRep for its -bitmapData and its -bytesPerRow shouldn't matter.*/
    
    // doesn't work in leopard, gotta wait until SL
    //[rep bitmapData];
    //return rep;
    
	return [NSBitmapImageRep imageRepWithData: [rep TIFFRepresentation]]; // [NSImage imageWithBitmapRep: rep] 

    NSBitmapImageRep *newRep = nil;
    if( [rep bytesPerRow] == 0 ) {
        newRep  = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                          pixelsWide: [rep pixelsWide]
                                                          pixelsHigh: [rep pixelsHigh]
                                                       bitsPerSample: [rep bitsPerSample]
                                                     samplesPerPixel: [rep samplesPerPixel]
                                                            hasAlpha: [rep hasAlpha]
                                                            isPlanar: [rep isPlanar]
                                                      colorSpaceName: [rep colorSpaceName]
                                                        bitmapFormat: NSAlphaFirstBitmapFormat | NSAlphaNonpremultipliedBitmapFormat //0 //[rep bitmapFormat]
                                                         bytesPerRow: [rep pixelsWide] * [rep samplesPerPixel] // correction
                                                        bitsPerPixel: [rep bitsPerPixel]];
        
        unsigned char *srcBuffer = [rep bitmapData];
        unsigned char *dstBuffer = [newRep bitmapData];
        unsigned long totalBytes = [rep pixelsWide]*[rep pixelsHigh]*[rep samplesPerPixel];
        //int i;
        //for ( i = 0; i < totalBytes; i++ ) {
        //    dstBuffer[totalBytes-i-1] = srcBuffer[i];
        //}
        // memcpy is orders of magnitude faster than the for-loop ^^
        memcpy(dstBuffer, srcBuffer, totalBytes);
    }
    
    if(newRep)
        return [newRep autorelease];
    return [[rep retain] autorelease];
}

+ (NSBitmapImageRep*)bitmapRepFromNSImage:(NSImage*)image {
    if(!image) return nil;
    
	NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData: [image TIFFRepresentation]];
    
	return [bitmapImageRep autorelease];
}


+ (NSBitmapImageRep*)bitmapRepWithWindow:(int)wid {
    
    // get the rect of the window, and take out the menu bar
    CGRect windowRect;
    CGSGetWindowBounds(_CGSDefaultConnection(), wid, &windowRect);
    windowRect.origin.y += 22;
    windowRect.size.height -= 22;
    
    SInt32 MacVersion;
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        if (MacVersion >= LEOPARD) { // we're in Leopard
            
            // create the CFArrrayShit with this windowID
            CGWindowID windowIDs[1] = { (CGWindowID)wid };
            if(windowIDsArray != NULL) {
                CFRelease(windowIDsArray);  // trash the CFArrayRef
                windowIDsArray = NULL;
            }
            windowIDsArray = CFArrayCreate(kCFAllocatorDefault, (const void**)windowIDs, 1, NULL);
            
            // snag the image
            CGImageRef windowImage = CGWindowListCreateImageFromArray(windowRect, windowIDsArray, kCGWindowImageBoundsIgnoreFraming);
            
            if(CGImageGetWidth(windowImage) <= 1) {
                CGImageRelease(windowImage);
                NSLog(@"An error occured while capturing the window.");
                return nil;
            }
            
            // Create a bitmap rep from the grabbed image...
            NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: windowImage];
            //[bitmapRep setColorSpaceName: NSCalibratedRGBColorSpace];
            CGImageRelease(windowImage);
            
            return [bitmapRep autorelease];
        }
        else if (MacVersion >= TIGER) {    // we're in Tiger
            
            // Pre-10.5 Method of grabbing window
            
            // create an NSImage
            NSImage *windowImage = [NSImage imageWithCGContextCaptureWindow: wid];
            
            // convert to bitmap
            return [NSBitmapImageRep bitmapRepFromNSImage: windowImage];
        }
    }
    return nil;
}

+ (NSBitmapImageRep*)bitmapRepWithRect: (NSRect)rect inWindow:(int)wid {

    // get the rect of the window
    CGRect windowRect;
    CGSGetWindowBounds(_CGSDefaultConnection(), wid, &windowRect);
    CGRect captureRect;
    captureRect.origin.x = windowRect.origin.x + rect.origin.x;
    captureRect.origin.y = windowRect.origin.y + 22 + rect.origin.y;
    captureRect.size.height = rect.size.height;
    captureRect.size.width = rect.size.width;
    
    SInt32 MacVersion;
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr) {
        if (MacVersion >= LEOPARD) { // we're in Leopard

            // we expect the array to already have been generated in a call to bitmapRepWithWindow:
            if(windowIDsArray == NULL) return nil;
            
            // snag the image
            CGImageRef windowImage = CGWindowListCreateImageFromArray(captureRect, windowIDsArray, kCGWindowImageBoundsIgnoreFraming);
            
            if(CGImageGetWidth(windowImage) <= 1) {
                CGImageRelease(windowImage);
                NSLog(@"An error occured while capturing a rect within window.");
                return nil;
            }
            
            // Create a bitmap rep from the grabbed image...
            NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: windowImage];
            //[bitmapRep setColorSpaceName: NSCalibratedRGBColorSpace];
            CGImageRelease(windowImage);
            
            
            return [NSBitmapImageRep correctBitmap: [bitmapRep autorelease]];
        }
        else if (MacVersion >= TIGER) {    // we're in Tiger
            NSImage *windowImage = [NSImage imageWithCGContextCaptureWindow: wid];
            NSImage *sub = nil;
            if(windowImage) {
                sub = [[NSImage alloc] initWithSize: rect.size];
                [sub lockFocus];
                NSRect newRect = rect;  // we're getting a Q4 rect, gotta flip it to Q1
                newRect.origin.y = windowRect.size.height - newRect.origin.y - rect.size.height - 22;
                [windowImage compositeToPoint: NSZeroPoint fromRect: newRect operation: NSCompositeCopy fraction: 1.0];
                [sub unlockFocus];
                [sub autorelease];
            }
            return [NSBitmapImageRep bitmapRepFromNSImage: sub];
        }
    }
    return nil;
}



+ (NSBitmapImageRep *)bitmapRepWithScreenShotInRect:(NSRect)cocoaRect
{
    NSImage *image = [NSImage imageWithScreenShotInRect: cocoaRect];
    // convert it to a bitmap rep and return
	return [NSBitmapImageRep bitmapRepFromNSImage: image];
}

@end


@implementation NSImage (GrabWindow)

+ (NSImage*)imageWithBitmapRep: (NSBitmapImageRep*)rep {
    NSImage *image = nil;
    if(!rep) return image;
    
    image = [[NSImage alloc] init];
    [image addRepresentation: rep];
    
    return [image autorelease];
}

+ (NSImage*)imageWithCGContextCaptureWindow: (int)wid {
    
    // get window bounds
    CGRect windowRect;
    CGSGetWindowBounds(_CGSDefaultConnection(), wid, &windowRect);
    windowRect.origin = CGPointZero;
    
    // create an NSImage fo the window, cutting off the titlebar
    NSImage *image = [[NSImage alloc] initWithSize: NSMakeSize(windowRect.size.width, windowRect.size.height - 22)];
    [image lockFocus];  // lock focus on the image for drawing
    
    // copy the contents of the window to the graphic context
    CGContextCopyWindowCaptureContentsToRect([[NSGraphicsContext currentContext] graphicsPort], 
                                             windowRect, 
                                             _CGSDefaultConnection(), 
                                             wid, 
                                             0);
    [image unlockFocus];
    return [image autorelease];
}

+ (NSImage *)imageWithScreenShotInRect:(NSRect)cocoaRect {
	PicHandle picHandle;
	GDHandle mainDevice;
	Rect rect;
	
	// Convert NSRect to Rect
	SetRect(&rect, NSMinX(cocoaRect), NSMinY(cocoaRect), NSMaxX(cocoaRect), NSMaxY(cocoaRect));
	
	// Get the main screen. No multiple screen support here.
	mainDevice = GetMainDevice();
	
	// Capture the screen into the PicHandle.
	picHandle = OpenPicture(&rect);
	CopyBits((BitMap *)*(**mainDevice).gdPMap, (BitMap *)*(**mainDevice).gdPMap,
				&rect, &rect, srcCopy, 0l);
	ClosePicture();
	
	// Convert the PicHandle into an NSImage
	// First lock the PicHandle so it doesn't move in memory while we copy
	HLock((Handle)picHandle);
	
	NSImageRep *pictImageRep = [NSPICTImageRep imageRepWithData:[NSData dataWithBytes:(*picHandle)
					length:GetHandleSize((Handle)picHandle)]];
	HUnlock((Handle)picHandle);
	
	// We can release the PicHandle now that we're done with it
	KillPicture(picHandle);
	
	// Create an image with the PICT representation
	NSImage *image = [[NSImage alloc] initWithSize: [pictImageRep size]];
	[image addRepresentation: pictImageRep];
    return [image autorelease];
}

@end

