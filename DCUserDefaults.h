#import <Foundation/Foundation.h>

@interface DCUserDefaults:NSObject
{
	NSString * appID;
	NSMutableDictionary * registration;
}

// Singleton
+ (DCUserDefaults *)standardUserDefaults;

// Set volatile defaults at bottom of search order
- (void)registerDefaults:(NSDictionary *)rDomain;

// Set search domain
- (NSString *)applicationIdentifier;
- (void)setApplicationIdentifier:(NSString *)identifier;

// Set values
- (id)objectForKey:			(NSString *)key;
- (int)integerForKey:		(NSString *)key;
- (BOOL)boolForKey:			(NSString *)key;
- (float)floatForKey:		(NSString *)key;
- (double)doubleForKey:		(NSString *)key;
- (NSString *)stringForKey:	(NSString *)key;
- (NSArray *)arrayForKey:	(NSString *)key;

// Retrieve values
- (void)setObject:(id)value	forKey:(NSString *)key;
- (void)setInteger:(int)i	forKey:(NSString *)key;
- (void)setBool:(BOOL)b		forKey:(NSString *)key;
- (void)setFloat:(float)f	forKey:(NSString *)key;
- (void)setDouble:(double)d	forKey:(NSString *)key;

// Reset defaults
- (void)removeDefaultForKey:(NSString *)key;

// For internal use only
- (void)setCFObject:(CFPropertyListRef)value forKey:(CFStringRef)key;
- (id)registrationObjectForKey:(NSString *)key;

@end
