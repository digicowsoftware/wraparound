//
//  DCScreen.m
//  Wraparound
//
//  Created by Mark Tyrrell on 8/27/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "DCScreen.h"
#import "DCEdge.h"

NSInteger _num;

@interface DCScreen () 

+ (NSInteger)screenIterator;

@end

@implementation DCScreen

+ (void)initialize {
	[DCScreen resetScreenIteration];
}

+ (void)resetScreenIteration {
	_num = 0;
}

+ (NSInteger)screenIterator {
	return _num++;
}

+ (DCScreen *)screenWithScreen:(NSScreen *)s {
	return [[[DCScreen alloc] initWithScreen:s] autorelease];
}

- (id)initWithScreen:(NSScreen *)s {
	if(self = [super init]) {
		CGFloat msh = [([[NSScreen screens] count]?[[NSScreen screens] objectAtIndex:0]:[NSScreen mainScreen]) frame].size.height;
		NSRect f = [s frame];
		frame = CGRectMake(
						   f.origin.x,
						   ((f.origin.y>=0)?		(msh-f.size.height):	(f.size.height-msh))
							-f.origin.y,
						   f.size.width,
						   f.size.height);
		number = [DCScreen screenIterator];
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (CGRect)frame {
	return frame;
}

- (NSInteger)screenNumber {
	return number;
}

- (NSString *)description {
	return NSStringFromCGRect(frame);
}

@end
