//
//  NSMediumDateFormatTransformer.m
//  Wraparound
//
//  Created by Mark Tyrrell on 6/22/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "NSMediumDateFormatTransformer.h"


@implementation NSMediumDateFormatTransformer

+ (Class)transformedValueClass {
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateStyle:NSDateFormatterMediumStyle];
	[df setTimeStyle:NSDateFormatterMediumStyle];
	return [df stringFromDate:(NSDate *)value];
}

- (id)reverseTransformedValue:(id)value {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateStyle:NSDateFormatterMediumStyle];
	[df setTimeStyle:NSDateFormatterMediumStyle];
	return [df dateFromString:(NSString *)value];
}

@end
