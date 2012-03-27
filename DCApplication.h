//
//  DCApplication.h
//  Wraparound
//
//  Created by digicow on 11/2/06.
//  Copyright 2006 Digital Cow Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DCApplication : NSObject <NSCoding>
{
	NSString * name;
	NSURL * path;
	NSImage * icon;
	NSString * identifier;
	unsigned long code;
}

+ (DCApplication *)activeApplication;
+ (DCApplication *)applicationWithPath:(NSString *)appPath;
+ (DCApplication *)applicationWithURL:(NSURL *)appURL;
+ (DCApplication *)application;
- (id)initWithPath:(NSString *)appPath;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)image;
- (NSString *)name;
- (void)setName:(NSString *)name;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)value;
- (NSURL *)path;
- (void)setPath:(NSURL *)value;
- (unsigned long)creatorCode;
- (void)setCreatorCode:(unsigned long)value;

- (NSComparisonResult)compare:(id)object;
- (BOOL)isEqual:(id)anObject;
- (unsigned)hash;

@end

@interface NSString (DCTrimming)
- (NSString *)trim;
@end

@interface NSImage (DCExtensions)
+ (NSImage *)iconForFile:(NSString *)path width:(double)w height:(double)h;
@end
