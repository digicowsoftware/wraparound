//
//  DCApplication.m
//  Wraparound
//
//  Created by digicow on 11/2/06.
//  Copyright 2006 Digital Cow Software. All rights reserved.
//

#import "DCApplication.h"

@implementation DCApplication

+ (DCApplication *)activeApplication
{
	NSDictionary * activeApp = [[NSWorkspace sharedWorkspace] activeApplication];
	NSString * activePath = [activeApp objectForKey:@"NSApplicationPath"];
	if(!activePath) return [DCApplication application];
	return [DCApplication applicationWithPath:activePath];
}

+ (DCApplication *)applicationWithPath:(NSString *)appPath
{
	return [[[DCApplication alloc] initWithPath:appPath] autorelease];
}

+ (DCApplication *)applicationWithURL:(NSURL *)appURL {
	return [[[DCApplication alloc] initWithPath:[appURL path]] autorelease];
}

+ (DCApplication *)application
{
	return [[[DCApplication alloc] init] autorelease];
}

- (id)init
{
	return [self initWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (id)initWithPath:(NSString *)appPath
{
	if(self = [super init])
	{
		[self setPath:[NSURL URLWithString:[appPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		[self setCreatorCode:[[[[NSFileManager defaultManager] attributesOfItemAtPath:appPath error:nil] objectForKey:NSFileHFSCreatorCode] unsignedLongValue]];
		[self setIcon:[NSImage iconForFile:appPath width:16.0 height:16.0]];
		
		NSBundle * app = [NSBundle bundleWithPath:appPath];
		if(app)
		{
			[self setName:[[app infoDictionary] objectForKey:@"CFBundleExecutable"]];
			[self setIdentifier:[app bundleIdentifier]];
		} else {
			[self setName:[[appPath lastPathComponent] stringByDeletingPathExtension]];
			[self setIdentifier:nil];
		}
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if(self = [super init])
	{
		[self setName:[decoder decodeObjectForKey:@"name"]];
		[self setPath:[decoder decodeObjectForKey:@"path"]];
		[self setIdentifier:[decoder decodeObjectForKey:@"identifier"]];
		[self setCreatorCode:[[decoder decodeObjectForKey:@"code"] unsignedLongValue]];
		[self setIcon:[NSImage iconForFile:[[self path] path] width:16.0 height:16.0]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[self name] forKey:@"name"];
	[encoder encodeObject:[self path] forKey:@"path"];
	[encoder encodeObject:[self identifier] forKey:@"identifier"];
	[encoder encodeObject:[NSNumber numberWithUnsignedLong:[self creatorCode]] forKey:@"code"];
	[encoder encodeObject:[self icon] forKey:@"icon"];
}

- (void)dealloc
{
	[self setPath:nil];
	[self setName:nil];
	[self setIcon:nil];
	[self setIdentifier:nil];
	[super dealloc];
}

- (NSString *)description
{
	return [self name];
}

- (NSString *)name 
{
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)value 
{
    if(name != value) 
	{
        [name release];
        name = [value copy];
    }
}

- (NSImage *)icon 
{
    return [[icon retain] autorelease];
}

- (void)setIcon:(NSImage *)value 
{
    if(icon != value) 
	{
        [icon release];
        icon = [value copy];
    }
}

- (NSString *)identifier 
{
    return [[identifier retain] autorelease];
}

- (void)setIdentifier:(NSString *)value 
{
    if(identifier != value) 
	{
        [identifier release];
        identifier = [value copy];
    }
}

- (NSURL *)path 
{
    return [[path retain] autorelease];
}

- (void)setPath:(NSURL *)value 
{
    if(path != value) 
	{
        [path release];
        path = [value copy];
    }
}

- (unsigned long)creatorCode
{
	return code;
}

- (void)setCreatorCode:(unsigned long)value
{
	code = value;
}

- (NSComparisonResult)compare:(id)object
{
	if(![object isKindOfClass:[self class]]) return NSOrderedAscending;
	
	return [[[self name] trim] caseInsensitiveCompare:[[object name] trim]];
}

//Compares bundleID, then (if bundleid doesn't exist) CreatorCode, then (if creatorcode doesn't exist) name
- (BOOL)isEqual:(id)anObject
{
	if(![anObject isKindOfClass:[self class]]) return false;
	
	if([(NSString *)[[self identifier] trim] length] && [(NSString *)[[anObject identifier] trim] length]) return [[self identifier] isEqualToString:[anObject identifier]];
	
	if([self creatorCode] > 0 && [anObject creatorCode] > 0) return [self creatorCode] == [anObject creatorCode];
	
	return [self compare:anObject]==NSOrderedSame;
}

- (unsigned)hash
{
	return 0;
}

@end

@implementation NSString (DCTrimming)

- (NSString *)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end

@implementation NSImage (DCExtensions)

+ (NSImage *)iconForFile:(NSString *)path width:(double)w height:(double)h
{
	NSImage * im = [[NSWorkspace sharedWorkspace] iconForFile:path];
	NSSize s = NSMakeSize(w,h);
	[im setSize:s];
	return im;
}

@end
