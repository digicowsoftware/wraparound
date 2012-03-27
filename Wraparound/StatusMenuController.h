//
//  StatusMenuController.h
//  Wraparound
//
//  Created by Mark Tyrrell on 6/7/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusMenuController : NSObject {
@private
	BOOL wrappingEnabled;
	
    NSStatusItem *statusItem;
	NSMenu *statusMenu;
}

@property (nonatomic) BOOL statusItemEnabled;
@property (nonatomic) BOOL wrappingEnabled;

@end
