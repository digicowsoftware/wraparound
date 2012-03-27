//
//  WraparoundAppDelegate.h
//  Wraparound
//
//  Created by Mark Tyrrell on 6/4/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StatusMenuController.h"
#import "PreferencesWindowController.h"

@interface WraparoundAppDelegate : NSObject <NSApplicationDelegate> {
@private
	StatusMenuController *smc;
	PreferencesWindowController *pwc;
}

- (IBAction)openPreferences:(id)sender;
- (IBAction)startWrapping:(id)sender;
- (IBAction)stopWrapping:(id)sender;

@end
