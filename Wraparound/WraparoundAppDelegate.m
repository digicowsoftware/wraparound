//
//  WraparoundAppDelegate.m
//  Wraparound
//
//  Created by Mark Tyrrell on 6/4/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "WraparoundAppDelegate.h"

@interface WraparoundAppDelegate()

@property (retain,nonatomic) StatusMenuController *smc;
@property (retain,nonatomic) PreferencesWindowController *pwc;

@end

//Resend Cocoa notification for CG monitor configuration changes
void DisplayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo) {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DisplayConfigurationDidChange" object:[NSString stringWithFormat:@"%d", display] userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:flags] forKey:@"flags"]];
}

@implementation WraparoundAppDelegate

@synthesize smc, pwc;

- (StatusMenuController *)smc {
	if(!smc) {
		smc = [[StatusMenuController alloc] init];
	}
	return smc;
}

- (PreferencesWindowController *)pwc {
	if(!pwc) {
		pwc = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
	}
	return pwc;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//Register for CG monitor config changes so that we can re-send them as Cocoa notifications
	CGDisplayRegisterReconfigurationCallback(&DisplayReconfigurationCallback, NULL);
	
	//Set default preferences
	NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
	[u registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
						 [NSNumber numberWithBool:YES], @"showIconInMenuBar",
						 [NSNumber numberWithBool:YES], @"wrappingEnabled",
						 [NSNumber numberWithBool:NO ], @"startAtLogin",
						 [NSNumber numberWithBool:YES], @"disableInCorners",
						 [NSNumber numberWithInt:0],	@"wrapActivationMethod",
						 nil]];
	
	//Initialize the Status Menu Controller and set its required attributes
	self.smc.statusItemEnabled = [u boolForKey:@"showIconInMenuBar"];
	self.smc.wrappingEnabled   = [u boolForKey:@"wrappingEnabled"];
	
	//Find out if we have a Software Update Controller and initialize it if we do
	//Also, add it to the Preference Window Controller
	Class sucClass;
	if((sucClass = NSClassFromString(@"SoftwareUpdateController"))) {
		id suc = [[sucClass alloc] init];
		[self.pwc addPreferencesModule:suc];
		[suc release];
	}
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
	[self openPreferences:self];
	return YES;
}

- (IBAction)openPreferences:(id)sender {
	[self.pwc showWindow:self];
}

- (IBAction)showDebugOptions:(id)sender {
	
}

- (IBAction)startWrapping:(id)sender {
	self.smc.wrappingEnabled = YES;
}

- (IBAction)stopWrapping:(id)sender {
	self.smc.wrappingEnabled = NO;
}

- (void)dealloc {
	[smc release];
	[super dealloc];
}

@end
