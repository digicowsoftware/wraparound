#import "DCUserDefaults.h"

@implementation DCUserDefaults:NSObject

#pragma mark -
#pragma mark Creation/Destruction Methods

+ (DCUserDefaults *)standardUserDefaults
{
	static DCUserDefaults * sharedInstance = nil;
	
	if (sharedInstance == nil)
		sharedInstance = [[self alloc] init];
	
	return sharedInstance;
}

- (id) init {
    static DCUserDefaults * sharedInstance = nil;
	
    if(sharedInstance) 
	{
        [self autorelease];
		self = [sharedInstance retain];
    } 
	else if(self = [super init]) 
	{
		sharedInstance = [self retain];
		
		appID = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"] retain];
		registration = [[NSMutableDictionary alloc] init];
	}
	
    return self;
}

- (void)dealloc
{
	[appID release];
	[registration release];
	[super dealloc];
}

#pragma mark -
#pragma mark Registration Domain

- (void)registerDefaults:(NSDictionary *)rDomain
{
	NSMutableDictionary * d = [NSMutableDictionary dictionary];
	[d addEntriesFromDictionary:[registration objectForKey:appID]];
	[d addEntriesFromDictionary:rDomain];
	[registration setObject:[[d copy] autorelease] forKey:appID];
}

#pragma mark -
#pragma mark Set/Retrieve Search Domain

- (NSString *)applicationIdentifier
{
	return [[appID retain] autorelease];
}

- (void)setApplicationIdentifier:(NSString *)identifier
{
	[appID autorelease];
	appID = [identifier retain];
}

#pragma mark -
#pragma mark Retrieve Defaults

- (id)objectForKey:(NSString *)key
{
	CFPropertyListRef d = CFPreferencesCopyValue((CFStringRef)key,
												 (CFStringRef)appID,
												 kCFPreferencesCurrentUser,
												 kCFPreferencesAnyHost);
	if(d == NULL)
		return [self registrationObjectForKey:key];
	id d2 = [(id)d copy];
	CFRelease(d);
	return [d2 autorelease];
}

- (int)integerForKey:(NSString *)key
{
	id n = [self objectForKey:key];
	if([n respondsToSelector:@selector(intValue)])
		return [n intValue];
	return 0;
}

- (BOOL)boolForKey:(NSString *)key
{
	id n = [self objectForKey:key];
	if([n respondsToSelector:@selector(boolValue)])
		return [n boolValue];
	return NO;
}

- (float)floatForKey:(NSString *)key
{
	id n = [self objectForKey:key];
	if([n respondsToSelector:@selector(floatValue)])
		return [n floatValue];
	return 0.0;
}

- (double)doubleForKey:(NSString *)key
{
	id n = [self objectForKey:key];
	if([n respondsToSelector:@selector(doubleValue)])
		return [n doubleValue];
	return 0.0;
}

- (NSString *)stringForKey:(NSString *)key
{
	id s = [self objectForKey:key];
	if([s isKindOfClass:[NSString class]])
		return (NSString *)s;
	return nil;
}

- (NSArray *)arrayForKey:(NSString *)key
{
	id a = [self objectForKey:key];
	if([a isKindOfClass:[NSArray class]])
		return (NSArray *)a;
	return nil;
}

#pragma mark -
#pragma mark Set Defaults

- (void)setObject:(id)value forKey:(NSString *)key
{
	//Assert that value is one of: NSString, NSData, NSNumber, NSDate, NSArray, NSDictionary
	NSParameterAssert([value isKindOfClass:[NSString		class]] || 
					  [value isKindOfClass:[NSData			class]] ||
					  [value isKindOfClass:[NSNumber		class]] ||
					  [value isKindOfClass:[NSDate			class]] ||
					  [value isKindOfClass:[NSArray			class]] ||
					  [value isKindOfClass:[NSDictionary	class]]);
	
	[self setCFObject:(CFPropertyListRef)value forKey:(CFStringRef)key];
}

- (void)setInteger:(int)i forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithInt:i] forKey:key];
}

- (void)setBool:(BOOL)b forKey:(NSString *)key
{
	[self setCFObject:b?kCFBooleanTrue:kCFBooleanFalse forKey:(CFStringRef)key];
}

- (void)setFloat:(float)f forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithFloat:f] forKey:key];
}

- (void)setDouble:(double)d forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithDouble:d] forKey:key];
}

#pragma mark -
#pragma mark Unset Defaults

- (void)removeDefaultForKey:(NSString *)key
{
	[self setCFObject:NULL forKey:(CFStringRef)key];
}

#pragma mark -
#pragma mark Internal

- (void)setCFObject:(CFPropertyListRef)value forKey:(CFStringRef)key
{
	CFPreferencesSetValue(key,
						  value,
						  (CFStringRef)appID,
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef)appID,
							 kCFPreferencesCurrentUser,
							 kCFPreferencesAnyHost);
}

- (id)registrationObjectForKey:(NSString *)key
{
	return [[registration objectForKey:[self applicationIdentifier]] objectForKey:key];
}

@end
