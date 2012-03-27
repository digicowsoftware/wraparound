//
//  IrregularRightPolygon.h
//  Wraparound
//
//  Created by Mark Tyrrell on 7/4/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IrregularRightPolygon : NSObject {
@private
	NSArray *componentRects;
	
    NSRect bounds;
	NSArray *edges;
}

@property (readonly) NSRect bounds;
@property (readonly) NSArray *edges;

- (void)addRect:(NSRect)rect;

- (CGPoint)maxXFromPoint:(CGPoint)p;
- (CGPoint)minXFromPoint:(CGPoint)p;
- (CGPoint)maxYFromPoint:(CGPoint)p;
- (CGPoint)minYFromPoint:(CGPoint)p;

@end
