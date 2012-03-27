//
//  CFRange.h
//  Wraparound
//
//  Created by Mark Tyrrell on 11/15/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

CFIndex CFRangeMax(CFRange range);

Boolean CFLocationInRange(CFIndex loc, CFRange range);

Boolean CFEqualRanges(CFRange range1, CFRange range2);

CFRange CFRangeUnion(CFRange range1, CFRange range2);
CFRange CFRangeIntersection(CFRange range1, CFRange range2);
CFStringRef CFStringFromCFRange(CFRange range);
CFRange CFRangeFromCFString(CFStringRef aString);
