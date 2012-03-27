//
//  SoftwareUpdateController.m
//  Wraparound
//
//  Created by Mark Tyrrell on 6/9/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "SoftwareUpdateController.h"

@interface SoftwareUpdateController() 

@property (retain) IBOutlet NSView *softwareUpdaterPreferencesView;
@property (retain) IBOutlet SUUpdater *suu;

@end

@implementation SoftwareUpdateController

@synthesize softwareUpdaterPreferencesView, suu;

- (id)init
{
    self = [super init];
    if (self) {
		NSString * nibName = @"SoftwareUpdate";
		
		//Load our nib
		if(![NSBundle loadNibNamed:nibName owner:self]) {
			NSLog(@"Failed to load nib (%@)", nibName);
		}
    }
    
    return self;
}

- (NSString *)identifier {
	return self.title;
}

- (NSString *)title {
	return @"Updates";
}

- (NSImage *)thumbnailImage {
	return [NSImage imageNamed:@"Updates.tiff"];
}

- (NSView *)preferencesView {
	return self.softwareUpdaterPreferencesView;
}

- (void)dealloc
{
	self.softwareUpdaterPreferencesView = nil;
	self.suu = nil;
    [super dealloc];
}

@end
