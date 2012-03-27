//
//  DCEdgeCollection.m
//  Wraparound
//
//  Created by Mark Tyrrell on 10/16/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "DCEdgeCollection.h"
#import "DCEdge.h"

#define ISBETWEEN(x,y,z) (((x<z?x:z) <= y)&&(y <= (x>z?x:z)))

@interface DCEdgeCollection ()

- (void)setEdges:(NSSet *)value;

- (void)addEdge:(DCEdge *)e;
- (void)removeEdge:(DCEdge *)n;

- (NSArray *)edgesWithAngle:(CGFloat)angle;

@end


@implementation DCEdgeCollection

- (NSSet *)edges {
    return [[edges copy] autorelease];
}

- (void)setEdges:(NSSet *)value {
    if (edges != value) {
        [edges release];
        edges = [value copy];
    }
}

+ (DCEdgeCollection *)collection {
	return [[DCEdgeCollection alloc] init];
}

- (id)init {
	if(self = [super init]) {
		edges = [[NSSet alloc] init];
	}
	return self;
}

- (void)dealloc {
	[edges release];
	[super dealloc];
}

- (void)addEdge:(DCEdge *)n {
	NSMutableSet *e = [[[self edges] mutableCopy] autorelease];
	
	if(![e containsObject:n])
		[e addObject:n];
	
	[self setEdges:e];
}

- (void)removeEdge:(DCEdge *)n {
	NSMutableSet *e = [[[self edges] mutableCopy] autorelease];
	
	if([e containsObject:n])
		[e removeObject:n];
	
	[self setEdges:e];
}

- (void)addEdgesFromRect:(CGRect)r {
	DCEdge *e1, *e2, *e3;
	NSSet * orig = [self edges];
	
	//Get the edges of the new rect
	NSEnumerator * newEdges = [[DCEdge edgesOfRect:r] objectEnumerator];
	while(e1 = [newEdges nextObject]) {
		
		//If our edges array is empty, ignore the logic, and just add it
		if([orig count]) {
			BOOL didIntersect = NO;
			
			//Get all the existing edges
			NSEnumerator * ex = [orig objectEnumerator];
			while(e2 = [ex nextObject]) {
				NSEnumerator *ice;
				
				//Will be nil if the edges have no points in common
				NSArray * ep = [e1 remaindersOfIntersection:e2];
				if(ice = [ep objectEnumerator]) {
					
					//If new edge does intersect an existing edge, mark it...
					didIntersect = YES;
					//Remove the existing edge from the array...
					[self removeEdge:e2];
					//And add all the remainders of the intersection
					while(e3 = [ice nextObject])
						[self addEdge:e3];
				}
			}
			
			//If (and only if) new edge intersected no existing edges, add it
			if(!didIntersect)
				[self addEdge:e1];
		} else
			[self addEdge:e1]; //Adding first edge to empty array
	}
}

- (void)setEdgesEnabled:(BOOL)enabled atAngle:(CGFloat)angle {
	NSEnumerator *en = [[self edges] objectEnumerator];
	DCEdge *e;
	while(e = [en nextObject])
		if([e angle] == angle)
			[e setActive:enabled];
}

- (NSArray *)edgesWithAngle:(CGFloat)angle {
	NSMutableArray *a = [NSMutableArray array];
	NSEnumerator *en = [[self edges] objectEnumerator];
	DCEdge *e;
	while(e = [en nextObject]) {
		if([e angle] == angle)
			[a addObject:e];
	}
	return [[a copy] autorelease];
}

- (DCEdge *)edgeContainingPoint:(CGPoint)p {
	if(eCache)
		if(CGPointEqualToPoint(p, pCache))
		   return eCache;
	
	DCEdge *e;
	NSEnumerator *en = [[self edges] objectEnumerator];
	while(e = [en nextObject]) {
		if([e containsPoint:p]) {
			pCache = p;
			eCache = e;
			return e;
		}
	}
	return nil;
}

- (DCEdge *)edgeOppositePoint:(CGPoint)p {
	DCEdge *e = nil, *f = [self edgeContainingPoint:p];
	NSMutableArray *candidateEdges = [NSMutableArray array];
	NSEnumerator *en = [[[[self edgesWithAngle:((int)[f angle]+180)%360] mutableCopy] autorelease] objectEnumerator];
	while(e = [en nextObject]) {
		CGPoint pointInDestinationEdge = CGPointMake([f horizontal]?p.x:[e location].x, [f horizontal]?[e location].y:p.y);
		if([e containsPoint:pointInDestinationEdge])
			[candidateEdges addObject:e];
	}
	return [[candidateEdges sortedArrayUsingSelector:@selector(compare:)] lastObject];
}

- (BOOL)isPoint:(CGPoint)p nearCorner:(CGFloat)distance {
	DCEdge *e = [self edgeContainingPoint:p];
	NSInteger adj = 1;
	switch((int)[e angle]) {
		case 180:
			//e = [e normalizedEdge];
			adj = -1;
		case 0:
			if(ISBETWEEN([e min],p.x,[e min]+distance))
				if([self edgeContainingPoint:CGPointMake([e min],[e location].y+adj)])
					return YES;
			if(ISBETWEEN([e max]-distance,p.x,[e max]))
				if([self edgeContainingPoint:CGPointMake([e max],[e location].y+adj)])
					return YES;
			break;
		case 90:
			adj = -1;
		case 270: 
			//e = [e normalizedEdge];
			if(ISBETWEEN([e min],p.y,[e min]+distance))
				if([self edgeContainingPoint:CGPointMake([e location].x+adj,[e min])])
					return YES;
			if(ISBETWEEN([e max]-distance,p.y,[e max]))
				if([self edgeContainingPoint:CGPointMake([e location].x+adj,[e max])])
					return YES;
			break;
	}
	return NO;
}

- (NSString *)description {
	DCEdge *e1;
	NSMutableString *s = [NSMutableString stringWithString:@"Detected Edges:\n[\n"];
	NSEnumerator *e = [[[[self edges] allObjects] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
	while(e1 = [e nextObject])
		[s appendFormat:@"\t%@\n", e1];
	[s appendString:@"]"];
	return s;
}

@end
