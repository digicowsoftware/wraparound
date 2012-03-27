//
//  DCEdge.h
//  Wraparound
//
//  Created by Mark Tyrrell on 10/16/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

// DCEdge represents an arbitrary vector in a 2D plane

#import <Cocoa/Cocoa.h>

@interface DCEdge : NSObject {
	CGPoint location;
	CGFloat magnitude;
	CGFloat angle;
	
	BOOL active;
}

- (BOOL)active;
- (CGPoint)location;
- (CGFloat)length;
- (CGFloat)angle;

- (void)setActive:(BOOL)value;

- (BOOL)horizontal;
- (DCEdge *)normalizedEdge;
- (CGFloat)min;
- (CGFloat)max;
- (CGFloat)majorCoordinate;
- (CGFloat)minorCoordinate;

+ (DCEdge *)edgeFromPoint:(CGPoint)p withLength:(CGFloat)l atAngle:(CGFloat)a;
+ (NSArray *)edgesOfRect:(CGRect)r;

- (NSArray *)remaindersOfIntersection:(DCEdge *)e;

- (BOOL)containsPoint:(CGPoint)p;

@end
