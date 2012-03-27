//
//  NSValueEqualsTwoTransformer.m
//  Wraparound
//
//  Created by Mark Tyrrell on 7/1/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "NSValueEqualsTwoTransformer.h"


@implementation NSValueEqualsTwoTransformer

+ (Class)transformedValueClass {
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)value {
	return [NSNumber numberWithBool:[value intValue]==2];
}

@end
