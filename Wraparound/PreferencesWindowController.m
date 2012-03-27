//
//  PreferencesWindowController.m
//  Wraparound
//
//  Created by Mark Tyrrell on 6/8/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()

@property (copy) NSArray *toolbarItemIdentifiers;
@property (retain) NSMutableArray *additionalPreferenceModules;
@property (copy) NSArray *views;

- (void)setView:(NSUInteger)viewIndex;

@end

@implementation PreferencesWindowController

@synthesize toolbarItemIdentifiers;
@synthesize additionalPreferenceModules;
@synthesize views;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		self.toolbarItemIdentifiers = [NSArray arrayWithObjects:
									   @"General",
									   @"Edges",
									   @"Applications",
									   nil];
		self.additionalPreferenceModules = [NSMutableArray array];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	self.views = [NSArray arrayWithObjects:generalPreferenceView, edgesPreferenceView, applicationsPreferenceView, nil];
	[self.window.toolbar setSelectedItemIdentifier:[self.toolbarItemIdentifiers objectAtIndex:currentViewIndex]];
	
	for(id <PreferencesModule> prefModule in self.additionalPreferenceModules) {
		self.views = [self.views arrayByAddingObject:prefModule.preferencesView];
	}
	
	[self.window setContentSize:[[views objectAtIndex:currentViewIndex] frame].size];
	[self.window.contentView addSubview:[views objectAtIndex:currentViewIndex]];
}

- (void)addPreferencesModule:(id <PreferencesModule>)prefModule {
	[self.additionalPreferenceModules addObject:prefModule];
	
	self.toolbarItemIdentifiers = [self.toolbarItemIdentifiers arrayByAddingObject:prefModule.identifier];
	self.views = [self.views arrayByAddingObject:prefModule.preferencesView];

	[self.window.toolbar insertItemWithItemIdentifier:[prefModule identifier] atIndex:[self.window.toolbar.items count]];
}

- (void)setView:(NSUInteger)viewIndex {
	NSView *view = [views objectAtIndex:viewIndex];
	NSRect oldFrame = self.window.frame;
	NSRect newFrame = [self.window frameRectForContentRect:[view frame]];
	NSRect frame = NSMakeRect(oldFrame.origin.x, 
						  oldFrame.origin.y - (newFrame.size.height - oldFrame.size.height), 
						  newFrame.size.width,
						  newFrame.size.height);
	
	[NSAnimationContext beginGrouping];
	
	[[NSAnimationContext currentContext] setDuration:0.1];
	if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	    [[NSAnimationContext currentContext] setDuration:1.0];
	
	NSView *previousView = [views objectAtIndex:currentViewIndex];
	//[previousView setAutoresizingMask:[previousView autoresizingMask] & !NSViewHeightSizable & !NSViewWidthSizable];
	[[[self.window contentView] animator] replaceSubview:previousView with:view];
	[self.window.animator setFrame:frame display:YES];
	//[view setAutoresizingMask:[view autoresizingMask] | NSViewHeightSizable | NSViewWidthSizable];
	
	if([view isEqual:edgesPreferenceView])
		[wrappedEdgeSelector setNeedsDisplay:YES];
	
	[NSAnimationContext endGrouping];
	
	currentViewIndex = viewIndex;
}

- (IBAction)selectView:(id)sender {
	[self setView:[sender tag]];
}

- (IBAction)showWindow:(id)sender {
	[self.window makeKeyAndOrderFront:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)dealloc
{
	[generalPreferenceView release];
	[edgesPreferenceView release];
	[applicationsPreferenceView release];
	
	[toolbarItemIdentifiers release];
	[additionalPreferenceModules release];
	[views release];
    [super dealloc];
}

#pragma mark NSToolBarDelegate

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return self.toolbarItemIdentifiers;
}

-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return self.toolbarItemIdentifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	for(id <PreferencesModule> prefItem in self.additionalPreferenceModules) {
		if([prefItem.identifier isEqualToString:itemIdentifier]) {
			[toolbarItem setLabel:prefItem.title];
			[toolbarItem setPaletteLabel:prefItem.title];
			[toolbarItem setImage:prefItem.thumbnailImage];
			[toolbarItem setTarget:self];
			[toolbarItem setTag:[self.toolbarItemIdentifiers indexOfObject:itemIdentifier]];
			[toolbarItem setAction:@selector(selectView:)];
		}
	}
	return toolbarItem;
}

#pragma mark NSToolbarItemValidation
/* NSToolbarItemValidation */
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	BOOL rv = NO;
	if([self.toolbarItemIdentifiers containsObject:[theItem itemIdentifier]])
		rv = YES;
	return rv;
}

@end
