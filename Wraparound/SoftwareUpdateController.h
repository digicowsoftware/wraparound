//
//  SoftwareUpdateController.h
//  Wraparound
//
//  Created by Mark Tyrrell on 6/9/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Sparkle/Sparkle.h>
#import "PreferencesWindowController.h"

@interface SoftwareUpdateController : NSObject <PreferencesModule> {
@private
    IBOutlet NSView *softwareUpdaterPreferencesView;
	IBOutlet SUUpdater *suu;
}

@end
