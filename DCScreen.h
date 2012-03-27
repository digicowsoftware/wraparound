//
//  DCScreen.h
//  Wraparound
//
//  Created by Mark Tyrrell on 8/27/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DCScreen : NSObject {
	CGRect frame;
	NSInteger number;
}

+ (void)resetScreenIteration;

+ (DCScreen *)screenWithScreen:(NSScreen *)s;
- (id)initWithScreen:(NSScreen *)s;

- (CGRect)frame;
- (NSInteger)screenNumber;

@end
