//
//  CFRange.m
//  Wraparound
//
//  Created by Mark Tyrrell on 11/15/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import "CFRange.h"

#if !defined(MIN)
	#define MIN(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __a : __b; })
#endif

#if !defined(MAX)
	#define MAX(A,B)	({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a < __b ? __b : __a; })
#endif

inline CFIndex CFRangeMax(CFRange range) {
    return (range.location + range.length);
} //Done

inline Boolean CFLocationInRange(CFIndex loc, CFRange range) {
	return (range.location <= loc && loc < CFRangeMax(range));
} //Done

inline Boolean CFEqualRanges(CFRange range1, CFRange range2) {
	return (range1.location == range2.location && range1.length == range2.length);
} //Done

CFRange CFRangeUnion(CFRange range1, CFRange range2) {
	return CFRangeMake(MIN(range1.location, range2.location),
					   MAX(CFRangeMax(range1), CFRangeMax(range2)));
} //Done

CFRange CFRangeIntersection(CFRange range1, CFRange range2) {
	CFIndex loc = 0, len = 0;
	if(CFLocationInRange(range1.location, range2) || CFLocationInRange(range2.location, range1)) {
		loc = MAX(range1.location, range2.location);
		len = MIN(CFRangeMax(range1), CFRangeMax(range2));
	}
	return CFRangeMake(loc, len);
} //Done

CFStringRef CFStringFromCFRange(CFRange range) {
	return CFStringCreateWithFormat(kCFAllocatorDefault, 
									NULL, 
									(CFStringRef)@"{%f, %f}", range.location, range.length);
} //Done

CFRange CFRangeFromCFString(CFStringRef aString) {
	CFIndex loc = 0;
	CFIndex len = 0;
	return CFRangeMake(loc, len);
}
