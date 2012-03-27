//
//  WrappedEdgeSelector.m
//  Wraparound
//
//  Created by Mark Tyrrell on 6/20/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "WrappedEdgeSelector.h"


@implementation WrappedEdgeSelector

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Drawing code here.
	NSRect f = [self bounds];
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:f];
	
	[[NSColor colorWithDeviceRed:243.0/255.0 green:242.0/255.0 blue:243.0/255.0 alpha:1.0] set];
	[path fill];
	
	[[NSColor blackColor] set];
	[path setLineWidth:1.0];
	[path stroke];
	
	//Invisible box that we're going to construct all of our screen 
	NSRect contentRect = NSMakeRect(f.origin.x+0.1*f.size.width, f.origin.y+0.1*f.size.height, 0.8*f.size.width, 0.8*f.size.height);
	
	//Calculate the superframe containing all screens
	NSArray *screens = [NSScreen screens];
	NSRect superframe = NSMakeRect(0.0,0.0,0.0,0.0);
	for(NSScreen *screen in screens) {
		superframe = NSUnionRect(superframe, [screen frame]);
	}
	
	//Are we scaling to make H or V fit?
	CGFloat scale = 1.0/MAX(superframe.size.width/contentRect.size.width, superframe.size.height/contentRect.size.height);
	NSRect scaledSuperFrame = NSMakeRect(0.0, 0.0, scale*superframe.size.width, scale*superframe.size.height);
	scaledSuperFrame.origin.x = contentRect.origin.x + (contentRect.size.width-scaledSuperFrame.size.width)/2.0;
	scaledSuperFrame.origin.y = contentRect.origin.y + (contentRect.size.height-scaledSuperFrame.size.height)/2.0;
	
	CGFloat menuHeight = 20.0;
	CGFloat scaledMenuHeight = MAX(menuHeight*scale,6.0);
	scaledMenuHeight = scaledMenuHeight; //Take this out later; just supressing warning right now
}

/*- (void)savethisforlater {
	
	NSLog(@"ContentRect:       %@", NSStringFromRect(contentRect));
	NSLog(@"Superframe:        %@", NSStringFromRect(superframe));
	NSLog(@"Scale Factor:      %f", scale);
	NSLog(@"Scaled Superframe: %@", NSStringFromRect(scaledSuperFrame));
	
	
	BOOL isMenuBarScreen = YES;
	for(NSScreen *screen in screens) {
		NSRect sf = [screen frame];
		//Normalize the screen to a (0,0) bottom left corner
		sf.origin.x -= NSMinX(superframe);
		sf.origin.y -= NSMinY(superframe);
		
		//Scale the screen to fit in scaledSuperFrame
		sf.origin.x = sf.origin.x*scale			+1.0;
		sf.origin.y = sf.origin.y*scale			+1.0;
		sf.size.width = sf.size.width*scale		-2.0;
		sf.size.height = sf.size.height*scale	-2.0;
		
		//Move screen into scaledSuperFrame
		sf.origin.x += scaledSuperFrame.origin.x;
		sf.origin.y += scaledSuperFrame.origin.y;
		
		//Move the rect to even numbers, then offset them by half a pixel
		sf = NSIntegralRect(sf);
		sf.origin.x += 0.5;
		sf.origin.y += 0.5;

		NSBezierPath *screenRect = [NSBezierPath bezierPathWithRect:sf];
		[[[NSColorList colorListNamed:@"System"] colorWithKey:@"keyboardFocusIndicatorColor"] set];
		[screenRect fill];
		
		[[NSColor blackColor] set];
		[screenRect setLineWidth:1.0];
		[screenRect stroke];
		
		if(isMenuBarScreen) {
			NSRect menuBarRect = NSMakeRect(sf.origin.x, sf.origin.y+sf.size.height-scaledMenuHeight, sf.size.width, scaledMenuHeight);
			NSBezierPath *menuRect = [NSBezierPath bezierPathWithRect:menuBarRect];
			[[NSColor whiteColor] set];
			[menuRect fill];
			[[NSColor blackColor] set];
			[menuRect setLineWidth:1.0];
			[menuRect stroke];
		}
		
		isMenuBarScreen = NO;
	}
}*/

@end
