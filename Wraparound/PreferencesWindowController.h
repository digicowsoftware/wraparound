//
//  PreferencesWindowController.h
//  Wraparound
//
//  Created by Mark Tyrrell on 6/8/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WrappedEdgeSelector.h"

@protocol PreferencesModule

@property (readonly) NSString *identifier;
@property (readonly) NSString *title;
@property (readonly) NSImage  *thumbnailImage;
@property (readonly) NSView   *preferencesView;

@end

@interface PreferencesWindowController : NSWindowController <NSToolbarDelegate> {
@private
	//Preference Modules
    NSArray *toolbarItemIdentifiers;
	NSMutableArray *additionalPreferenceModules;
	
	//Builtin Module's Views
	IBOutlet NSView *generalPreferenceView;
	IBOutlet NSView *edgesPreferenceView;
	IBOutlet NSView *applicationsPreferenceView;
	NSArray *views;
	NSUInteger currentViewIndex;
	
	IBOutlet WrappedEdgeSelector * wrappedEdgeSelector;
}

- (void)addPreferencesModule:(id <PreferencesModule>)prefModule;

- (IBAction)selectView:(id)sender;
- (IBAction)showWindow:(id)sender;

@end
