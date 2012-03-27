//
//  StatusMenuController.m
//  Wraparound
//
//  Created by Mark Tyrrell on 6/7/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "StatusMenuController.h"

@interface StatusMenuController() 

@property (readonly) NSImage *menuIcon;
@property (readonly) NSMenu  *statusMenu;
@property (retain,nonatomic) NSStatusItem *statusItem;

- (NSStatusItem *)getStatusItem;

@end

@implementation StatusMenuController

@synthesize statusItem;
@synthesize wrappingEnabled;

- (NSMenu *)statusMenu {
	if(!statusMenu) {
		statusMenu = [[NSMenu alloc] initWithTitle:@"Wraparound"];
	}
	return statusMenu;
}

- (void)setStatusItem:(NSStatusItem *)st {
	if(!st) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	}
	[statusItem release];
	statusItem = [st retain];
}


- (BOOL)statusItemEnabled {
	return !!(self.statusItem);
}

- (void)setStatusItemEnabled:(BOOL)statusItemState {
	if(!!(self.statusItem) != statusItemState) {
		self.statusItem = statusItemState?[self getStatusItem]:nil;
	}
}

- (void)setWrappingEnabled:(BOOL)wrappingState {
	if(wrappingEnabled != wrappingState) {
		wrappingEnabled = wrappingState;
		
		[self.statusItem setImage:self.menuIcon];
		
		[self.statusMenu removeItemAtIndex:0];
		if(wrappingEnabled) {
			[self.statusMenu insertItemWithTitle:@"Stop" action:@selector(stopWrapping:) keyEquivalent:@"" atIndex:0];
		} else {
			[self.statusMenu insertItemWithTitle:@"Start" action:@selector(startWrapping:) keyEquivalent:@"" atIndex:0];
		}
		[self.statusItem setMenu:self.statusMenu];
	}
}

- (NSImage *)menuIcon {
	NSImage *t = nil;
	if(self.wrappingEnabled) {
		t = [NSImage imageNamed:@"MenuIcon.tiff"];
	} else {
		t = [NSImage imageNamed:@"MenuIconGray.tiff"];
	}
	return t;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		
		//Menu
		//Start/Stop Menu Item
		[self.statusMenu addItemWithTitle:@"Start" action:@selector(start:) keyEquivalent:@""];
		
		//Preferences Menu Item
		[self.statusMenu addItemWithTitle:@"Preferences…" action:@selector(openPreferences:) keyEquivalent:@""];
		
		//Separator
		[self.statusMenu addItem:[NSMenuItem separatorItem]];
		
		//Quit Menu Item
		[[self.statusMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""] setTarget:[NSApplication sharedApplication]];
    }
    
    return self;
}

- (NSStatusItem *)getStatusItem {
	NSStatusItem *si = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	[si setHighlightMode:YES];
	[si setImage:self.menuIcon];
	[si setMenu:self.statusMenu];
	return si;
}

- (void)dealloc
{
	self.statusItem = nil;
	[statusMenu release];
    [super dealloc];
}

@end
