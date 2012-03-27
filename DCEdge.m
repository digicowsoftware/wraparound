//
//  DCEdge.m
//  Wraparound
//
//  Created by Mark Tyrrell on 10/16/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "DCEdge.h"
#import "CFRange.h"
#import "CompatibilityFunctions.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

@interface DCEdge () 

- (id)initWithOrigin:(CGPoint)o magnitude:(CGFloat)m angle:(CGFloat)a;

- (CGFloat)distanceFromOrigin;
- (CFRange)range;

- (DCEdge *)reversedEdge;

- (BOOL)intersects:(DCEdge *)e;
- (BOOL)linearWith:(DCEdge *)e;
- (DCEdge *)adjacentPseudoEdge;
- (DCEdge *)edgeWithRange:(CFRange)r;

@end

@implementation DCEdge

+ (DCEdge *)edgeFromPoint:(CGPoint)p withLength:(CGFloat)l atAngle:(CGFloat)a {
	NSAssert((int)a%90 == 0, @"Angle must be a multiple of 90");
	if(l <= 0)
		return nil;
	return [[[DCEdge alloc] initWithOrigin:p magnitude:l angle:a] autorelease];
}

+ (NSArray *)edgesOfRect:(CGRect)r {
	CGFloat righter = r.origin.x+r.size.width;
	CGFloat lower = r.origin.y+r.size.height;
	return [NSArray arrayWithObjects:
			//Top
			[DCEdge edgeFromPoint:r.origin 
				withLength:r.size.width
				   atAngle:0.0],
			//Right
			[DCEdge edgeFromPoint:CGPointMake(righter+(righter>0?-1:0),r.origin.y) 
				withLength:r.size.height
				   atAngle:90.0],
			//Bottom
			[DCEdge edgeFromPoint:CGPointMake(righter+(righter>0?-1:0),lower-1) 
				withLength:r.size.width
				   atAngle:180.0],
			//Left
			[DCEdge edgeFromPoint:CGPointMake(r.origin.x,lower-1) 
				withLength:r.size.height 
				   atAngle:270.0],
	 nil];	
}

//Private constructor -- don't call directly. Use convenience methods above
- (id)initWithOrigin:(CGPoint)o magnitude:(CGFloat)m angle:(CGFloat)a {
	if(self = [super init]) {
		location = o;
		magnitude = m;
		angle = a;
		
		active = NO;
	}
	return self;
}

- (DCEdge *)normalizedEdge {
	if([self angle] == 180.0 || [self angle] == 270.0)
		return [self reversedEdge];
	else 
		return self;
}

- (DCEdge *)reversedEdge {
	CGPoint n = [self location];
	switch((int)[self angle]) {
		case   0: n.x = n.x + [self length]-1; break;
		case  90: n.y = n.y + [self length]-1; break;
		case 180: n.x = n.x - [self length]+1; break;
		case 270: n.y = n.y - [self length]+1; break;
	}
	return [DCEdge edgeFromPoint:n
					  withLength:[self length]
						 atAngle:((int)[self angle]+180)%360];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@%3.0f° %@x%4.0f", 
				[self horizontal]?@"H":@"V",
				[self angle],
				NSStringFromCGPoint([self location]), 
				[self length]
			];
}

- (BOOL)active {
	return active;
}

- (CGPoint)location {
    return location;
}
- (CGFloat)length {
    return magnitude;
}

- (CGFloat)angle {
    return angle;
}

- (void)setActive:(BOOL)value {
	active = value;
}

- (CGFloat)distanceFromOrigin {
	return sqrt([self location].x * [self location].x + [self location].y * [self location].y);
}

- (BOOL)horizontal {
	return ((int)[self angle]%180) == 0;
}

- (CGFloat)min {
	CGFloat r = 0.0;
	switch((int)[self angle]) {
		case   0: r = [self location].x; break;
		case  90: r = [self location].y; break;
		case 180: r = [[self reversedEdge] location].x; break;
		case 270: r = [[self reversedEdge] location].y; break;
	}
	return r;
}

- (CGFloat)max {
	CGFloat r = 0.0;
	switch((int)[self angle]) {
		case   0: r = [[self reversedEdge] location].x; break;
		case  90: r = [[self reversedEdge] location].y; break;
		case 180: r = [self location].x; break;
		case 270: r = [self location].y; break;
	}
	return r;
}

- (CGFloat)majorCoordinate {
	if([self horizontal])
		return [self location].x;
	return [self location].y;
}

- (CGFloat)minorCoordinate {
	if(![self horizontal])
		return [self location].x;
	return [self location].y;
}

- (CFRange)range {
	return CFRangeMake([self horizontal]?[self location].x:[self location].y, [self length]);
}

- (DCEdge *)adjacentPseudoEdge {
	CGPoint p = [self location];
	switch((int)[self angle]) {
		case 0:   p.y--; break;
		case 90:  p.x++; break;
		case 180: p.y++; break;
		case 270: p.x--; break;
	}
	return [DCEdge edgeFromPoint:p withLength:[self length] atAngle:[self angle]];
}

- (NSArray *)remaindersOfIntersection:(DCEdge *)e {
	DCEdge *ea = [e adjacentPseudoEdge];
	if(![self intersects:ea])
		return nil;
	
	CFRange r1 = [[self normalizedEdge] range];
	CFRange r2 = [[e normalizedEdge] range];
	
	CFRange u = CFRangeUnion(r1, r2);
	CFRange i = CFRangeIntersection(r1, r2);
	CFRange pre = CFRangeMake(u.location,i.location-u.location);
	CFRange post = CFRangeMake(CFRangeMax(i),CFRangeMax(u)-CFRangeMax(i));
	
	NSMutableArray *edges = [NSMutableArray array];
	DCEdge *n;
	if(n=[self edgeWithRange:pre])
		[edges addObject:n];
	else if(n=[e edgeWithRange:pre])
		[edges addObject:n];
	if(n=[self edgeWithRange:post])
		[edges addObject:n];
	else if(n=[e edgeWithRange:post])
		[edges addObject:n];
	
	return [[edges copy] autorelease];
}

- (DCEdge *)edgeWithRange:(CFRange)r {
	DCEdge *e = nil, *er = [self normalizedEdge];
	CFRange i = CFRangeIntersection(r,[er range]);
	if(i.length) {
		CGPoint p = [self location];
		if([self horizontal])
			p.x = i.location;
		else
			p.y = i.location;
		e = [DCEdge edgeFromPoint:p withLength:i.length atAngle:[er angle]];
		if((int)[self angle] == 180 || (int)[self angle] == 270)
			e = [e reversedEdge];
	}
	return e;
}

- (BOOL)intersects:(DCEdge *)e {
	//Determine if linear
	if([self linearWith:e]) {
		//Determine if overlapping
		CFRange r = CFRangeIntersection([[self normalizedEdge] range],[[e normalizedEdge] range]);
		return r.length>0;
	}
	return NO;
}

- (BOOL)linearWith:(DCEdge *)e {
	return ([self horizontal] == [e horizontal] && [self minorCoordinate] == [e minorCoordinate]);
}

- (BOOL)containsPoint:(CGPoint)p {
	DCEdge *e = [self normalizedEdge];
	if([self horizontal]) {
		if(p.y == [e location].y && p.x >= [e location].x && p.x < [e location].x+[e length])
			return YES;
	} else {
		if(p.x == [e location].x && p.y >= [e location].y && p.y < [e location].y+[e length])
			return YES;
	}
	//NSLog(@"%@ is not inside %@", NSStringFromCGPoint(p), e);
	return NO;
}

- (BOOL)isEqual:(id)object {
	if(![object isKindOfClass:[self class]]) return NO;
	
	DCEdge *a = [self normalizedEdge], *b = [object normalizedEdge];
	
	if([a angle]==[b angle] && CGPointEqualToPoint([a location], [b location]) && [a length]==[b length]) return YES;
	
	return NO;
}

- (NSUInteger)hash {
	DCEdge * e = [self normalizedEdge];
	return
		([e horizontal])?1237:1231 ^
		NSUINTROTATE((int)[e location].x, NSUINT_BIT/2) ^
		NSUINTROTATE((int)[e location].y, NSUINT_BIT/3) ^
		(int)[e length];
}

- (NSComparisonResult)compare:(DCEdge *)e {
	DCEdge *a = [self normalizedEdge];
	DCEdge *b = [e normalizedEdge];
	
	if([self angle] != [e angle])
		return [self angle]<[e angle]?NSOrderedAscending:NSOrderedDescending;
	
	if([a distanceFromOrigin] != [b distanceFromOrigin])
		return [a distanceFromOrigin]<[b distanceFromOrigin]?NSOrderedAscending:NSOrderedDescending;
	
	if([a length] != [b length])
		return [a length]>[b length]?NSOrderedAscending:NSOrderedDescending;
	
	return NSOrderedSame;
}

@end
