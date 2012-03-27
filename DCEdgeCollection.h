//
//  DCEdgeCollection.h
//  Wraparound
//
//  Created by Mark Tyrrell on 10/16/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCEdge;


@interface DCEdgeCollection : NSObject {
	NSSet *edges;

	CGPoint pCache;
	DCEdge *eCache;
}

- (NSSet *)edges;

+ (DCEdgeCollection *)collection;

- (void)addEdgesFromRect:(CGRect)r;

- (DCEdge *)edgeContainingPoint:(CGPoint)p;
- (DCEdge *)edgeOppositePoint:(CGPoint)p;

- (void)setEdgesEnabled:(BOOL)enabled atAngle:(CGFloat)angle;
- (BOOL)isPoint:(CGPoint)p nearCorner:(CGFloat)distance;

@end
