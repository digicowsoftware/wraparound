#import "DCWrap.h"
#import <Carbon/Carbon.h>
#import <WebKit/WebKit.h>
#import "DCEdge.h"
#import "DCEdgeCollection.h"
#import "DCApplication.h"
#import "LoginItemsAE.h"
#import "CompatibilityFunctions.h"
#import "DebuggingFunctions.h"
#import "UserDefaultsSymbols.h"

#define DCLog(...) [self writeDebugText:[NSString stringWithFormat:__VA_ARGS__]]

@interface DCWrap ()

- (void)addApplication:(NSString *)filename;
- (void)updateLocation:(CGEventRef)event;

@end

@interface NSScreen (DCAdditions)

- (CGRect)flippedFrame;

@end

OSStatus MyActiveApplicationDidChange(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
	OSStatus result = eventNotHandledErr;
	UInt32 eventClass = GetEventClass(inEvent);
	UInt32 eventKind = GetEventKind(inEvent);
	
	// We only handle active app chnaged events...
	if((eventClass == kEventClassApplication) && (eventKind == kEventAppFrontSwitched))
	{
		ProcessSerialNumber newFrontProcess;
		
		// Get the new process ID out
		if(GetEventParameter(inEvent, kEventParamProcessID, typeProcessSerialNumber, NULL, sizeof(ProcessSerialNumber), NULL, &newFrontProcess) == noErr)
			[((DCWrap *)inUserData) activeApplicationDidChange]; // Put your custom objective-C callback here
		
		result = noErr; // Tell the dispatcher that we handled the event...
	}
	
	return result;
}

NSString* NSStringFromCGPoint(CGPoint p) {
	return NSStringFromPoint(NSPointFromCGPoint(p));
}

NSString* NSStringFromCGRect(CGRect r) {
	return NSStringFromRect(NSRectFromCGRect(r));
}

/*BOOL DCValueInRange(CGFloat a, CGFloat b, CGFloat range) {
	if(a < b+range && a > b-range)
		return YES;
	return NO;
}*/

CGEventRef mouseMovedCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	static BOOL inUpdate = NO;
	if(!inUpdate) {
		inUpdate = YES;
		[(DCWrap *)refcon updateLocation:event];
	}
	inUpdate = NO;
	return NULL;
}

@implementation DCWrap

//Init
+ (void)initialize
{
	[NSValueTransformer setValueTransformer:[DCValueToRunningStateTransformer transformer] forName:@"DCValueToRunningState"];
}

- (id)init
{
	if(self = [super init])
	{		
		//Register default preferences
		NSMutableDictionary * defaultPrefs = [[[NSMutableDictionary alloc] initWithObjectsAndKeys:
			[NSKeyedArchiver archivedDataWithRootObject:[NSArray array]],	UDApplicationList,
		    [NSNumber numberWithInt: 0  ],		UDAppDisableMode,
											   
			[NSNumber numberWithInt: 0x5 ],		UDWrapEdges,		//Bitmask Top 0b0001, Right 0b0010, Bottom 0b0100, Left 0b1000
			[NSNumber numberWithInt: 0  ],		UDAllEdgesModifiers,//Bitmask (system modifier values)
			[NSNumber numberWithInt: 0  ],		UDNoEdgesModifiers,	//Bitmask (system modifier values)
											   
			[NSNumber numberWithBool:NO ],		UDDisableInCorners,
			[NSNumber numberWithInt: 20 ],		UDCornerSize,
											   
			[NSNumber numberWithBool:YES],		UDShowAtLaunch,
			[NSNumber numberWithBool:YES],		UDShowStatusItem,
											   
		    [NSNumber numberWithBool:NO ],		UDDebugEnabled,
											   
//			[NSNumber numberWithBool:NO],		@"Wrap Top",
//			[NSNumber numberWithBool:NO ],		@"Wrap Bottom",
//			[NSNumber numberWithBool:YES],		@"Wrap Left",
//			[NSNumber numberWithBool:YES],		@"Wrap Right",
//			[NSNumber numberWithDouble:20.0],	@"CPU Usage",
//			[NSNumber numberWithInt: 2  ],		@"JumpAxisLockLength",
//			[NSNumber numberWithBool:NO ],		@"JumpLocksAxis",
			nil] autorelease];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
		
		BOOL indebug = isBeingDebugged();
		[self setDebugToConsole:indebug];
		[self setDebugToFile:!indebug];
		[self setDebugEnabled:[[NSUserDefaults standardUserDefaults] boolForKey:UDDebugEnabled]];
	}
	return self;
}

- (void)awakeFromNib
{
	CFMachPortRef tap = CGEventTapCreate(kCGSessionEventTap, 
										 kCGHeadInsertEventTap, 
										 kCGEventTapOptionListenOnly, 
										 1<<kCGEventMouseMoved | 1<<kCGEventLeftMouseDragged | 1<<kCGEventRightMouseDragged | 1<<kCGEventOtherMouseDragged, 
										 mouseMovedCallback, 
										 self);
	mmRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0);
	CFRelease(tap);
	
	[appList registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,nil]];
	id appListData = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:UDApplicationList]];
	if([appListData isKindOfClass:[NSArray class]])	
		[apps setContent:[[appListData mutableCopy] autorelease]];
	
	NSString * webPath = [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html"];
	[[helpView mainFrame] loadHTMLString:[NSString stringWithContentsOfFile:webPath encoding:NSUTF8StringEncoding error:nil] baseURL:[NSURL fileURLWithPath:[webPath stringByStandardizingPath]]];
	
	//Setup views
	NSUInteger edges = [[NSUserDefaults standardUserDefaults] integerForKey:UDWrapEdges];
	[wrapEdges setSelected:edges & 1<<0 forSegment:0]; //Top
	[wrapEdges setSelected:edges & 1<<2 forSegment:1]; //Bottom
	[wrapEdges setSelected:edges & 1<<3 forSegment:2]; //Left
	[wrapEdges setSelected:edges & 1<<1 forSegment:3]; //Right
	
	NSUInteger pos = [[NSUserDefaults standardUserDefaults] integerForKey:UDAllEdgesModifiers];
	if(pos & kCGEventFlagMaskShift)	{ //Shift
		[wrapAllEdges setSelected:YES forSegment:0];
		[wrapNoEdges   setEnabled:NO  forSegment:0];
	}
	if(pos & kCGEventFlagMaskCommand) { //Command
		[wrapAllEdges setSelected:YES forSegment:1];
		[wrapNoEdges   setEnabled:NO  forSegment:1];
	}
	if(pos & kCGEventFlagMaskAlternate) { //Option
		[wrapAllEdges setSelected:YES forSegment:2];
		[wrapNoEdges   setEnabled:NO  forSegment:2];
	}
	if(pos & kCGEventFlagMaskControl) { //Control
		[wrapAllEdges setSelected:YES forSegment:3]; 
		[wrapNoEdges   setEnabled:NO  forSegment:3];
	}
	
	NSUInteger neg = [[NSUserDefaults standardUserDefaults] integerForKey:UDNoEdgesModifiers];
	if(neg & kCGEventFlagMaskShift)	{ //Shift
		[wrapNoEdges  setSelected:YES forSegment:0];
		[wrapAllEdges  setEnabled:NO  forSegment:0];
	}
	if(neg & kCGEventFlagMaskCommand) { //Command
		[wrapNoEdges  setSelected:YES forSegment:1];
		[wrapAllEdges  setEnabled:NO  forSegment:1];
	}
	if(neg & kCGEventFlagMaskAlternate) { //Option
		[wrapNoEdges  setSelected:YES forSegment:2];
		[wrapAllEdges  setEnabled:NO  forSegment:2];
	}
	if(neg & kCGEventFlagMaskControl) { //Control
		[wrapNoEdges  setSelected:YES forSegment:3]; 
		[wrapAllEdges  setEnabled:NO  forSegment:3];
	}
	
	//[self setTimerInterval:1.0/[[NSUserDefaults standardUserDefaults] integerForKey:@"CPU Usage"]];
	[self setDisplayInMenuBar:[[NSUserDefaults standardUserDefaults] boolForKey:UDShowStatusItem]];
	[self start];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:UDShowAtLaunch] || (GetCurrentKeyModifiers() & optionKey))
		[self showWindow:nil];
}

- (void)dealloc
{
	//if(isRunning) [t release];
	if(isMenuVisible) [wrapStatusItem release];
	CFRelease(mmRunLoopSource);
	[outerEdges release];
	//[screens release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Actions

- (IBAction)showAbout:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:sender];
}

- (IBAction)showWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:nil];
}

- (IBAction)chooseWrapEdges:(id)sender
{
	NSUInteger tr[4] = {1<<0,1<<2,1<<3,1<<1};
	NSUInteger x = 0;
	for(int i=0;i<4;i++)
		if([sender isSelectedForSegment:i])
			x |= tr[i];
	
	[[NSUserDefaults standardUserDefaults] setInteger:x forKey:UDWrapEdges];
	[self setJumpEdges];
}

- (IBAction)chooseAllEdgesModifiers:(id)sender {
	NSInteger x = 0;
	NSUInteger tr[4] = {kCGEventFlagMaskShift,kCGEventFlagMaskCommand,kCGEventFlagMaskAlternate,kCGEventFlagMaskControl};
	for(int i=0;i<4;i++) {
		if([sender isSelectedForSegment:i]) {
			x |= tr[i];
			[wrapNoEdges setEnabled:NO forSegment:i];
		} else {
			[wrapNoEdges setEnabled:YES forSegment:i];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:x forKey:UDAllEdgesModifiers];
}

- (IBAction)chooseNoEdgesModifiers:(id)sender {
	NSInteger x = 0;
	NSUInteger tr[4] = {kCGEventFlagMaskShift,kCGEventFlagMaskCommand,kCGEventFlagMaskAlternate,kCGEventFlagMaskControl};
	for(int i=0;i<4;i++) {
		if([sender isSelectedForSegment:i]) {
			x |= tr[i];
			[wrapAllEdges setEnabled:NO forSegment:i];
		} else {
			[wrapAllEdges setEnabled:YES forSegment:i];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setInteger:x forKey:UDNoEdgesModifiers];
}

- (IBAction)toggleWrapping:(id)sender
{
	if(isRunning) [self stop];
	else [self start];
}

- (IBAction)addAppToList:(id)sender
{
	NSOpenPanel * o = [NSOpenPanel openPanel];
	[o setCanChooseDirectories:NO];
	[o setCanChooseFiles:YES];
	[o setAllowsMultipleSelection:YES];
	[o beginSheetForDirectory:@"/Applications" file:nil types:[NSArray arrayWithObjects:@"app",@"APPL",nil] modalForWindow:window modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	if(returnCode == NSCancelButton) return;
	
	NSEnumerator * e = [[panel filenames] objectEnumerator];
	NSString * filename;
	while(filename = [e nextObject])
		[self addApplication:filename];
}

- (void)addApplication:(NSString *)filename {
	DCApplication * app = [DCApplication applicationWithPath:filename];
	if(![[apps content] containsObject:app])
		[apps addObject:app];
	else
		DCLog(@"'%@' %@", [app name], NSLocalizedString(@"is already in Wraparound's application list",@"Debug String"));
	[[apps content] sortUsingSelector:@selector(compare:)];
	[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[apps content]] forKey:UDApplicationList];
}

- (IBAction)removeAppFromList:(id)sender
{
	[apps remove:sender];
	[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[apps content]] forKey:UDApplicationList];
}

- (IBAction)toggleDebug:(id)sender {
	if([self debugEnabled]) {
		[self setDebugEnabled:NO];
		[coordinates setStringValue:@""];
	} else {
		[self setDebugEnabled:YES];
	}
}

#pragma mark -
#pragma mark Bindings

- (int)appDisableMode
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:UDAppDisableMode];
}

- (void)setAppDisableMode:(int)val
{
	[[NSUserDefaults standardUserDefaults] setInteger:val forKey:UDAppDisableMode];
	[self activeApplicationDidChange];
}

- (int)cornerSize
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:UDCornerSize];
}

- (void)setCornerSize:(int)val
{
	[[NSUserDefaults standardUserDefaults] setInteger:val forKey:UDCornerSize];
}

/*- (int)CPUUsage
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"CPU Usage"];
}

- (void)setCPUUsage:(int)val
{
	[[NSUserDefaults standardUserDefaults] setInteger:val forKey:@"CPU Usage"];
	[self setTimerInterval:1.0/val];
}*/

- (BOOL)disableInCorners
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:UDDisableInCorners];
}

- (void)setDisableInCorners:(BOOL)val
{
	[[NSUserDefaults standardUserDefaults] setBool:val forKey:UDDisableInCorners];
}

- (BOOL)displayAtLaunch
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:UDShowAtLaunch];
}

- (void)setDisplayAtLaunch:(BOOL)val
{
	[[NSUserDefaults standardUserDefaults] setBool:val forKey:UDShowAtLaunch];
}

- (BOOL)displayInMenuBar
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:UDShowStatusItem];
}

- (void)setDisplayInMenuBar:(BOOL)val
{
	[[NSUserDefaults standardUserDefaults] setBool:val forKey:UDShowStatusItem];
	
	if(val && !isMenuVisible)
	{
		wrapStatusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
		[self setStatusItemImageForState:YES];
		[wrapStatusItem setHighlightMode:YES];
		[wrapStatusItem setMenu:sMenu];
		[wrapStatusItem setEnabled:YES];
		isMenuVisible = YES;
	}
	else if(!val && isMenuVisible)
	{
		[[NSStatusBar systemStatusBar] removeStatusItem:wrapStatusItem];
		[wrapStatusItem release];
		wrapStatusItem = nil;
		isMenuVisible = NO;
	}
}

- (BOOL)startAtLogin
{
	return [self isLoginItemInstalled];
}

- (void)setStartAtLogin:(BOOL)val
{
	BOOL isInstalled = [self isLoginItemInstalled];
	if(val && !isInstalled) [self addToLoginItems];
	else if(!val && isInstalled) [self removeFromLoginItems];
}

- (BOOL)isRunning
{
	return isRunning;
}

- (void)setIsRunning:(BOOL)val
{
	[self setStatusItemImageForState:val];
	isRunning = val;
}

#pragma mark -
#pragma mark Running Status

- (void)start
{
	if(isRunning || isDisabled) return;
	[self buildScreensList];
	
	DCLog(@"Starting...");
	//[self writeDebugText:[NSString stringWithFormat:@"%@ [@%0.2f sec]", NSLocalizedString(@"Starting...", @"Debug Text"), freq]];
//	if(!t)
//		t = [NSTimer scheduledTimerWithTimeInterval:freq target:self selector:@selector(checkPosition:) userInfo:nil repeats:YES];
	
	CFRunLoopAddSource(CFRunLoopGetMain(), mmRunLoopSource, kCFRunLoopDefaultMode);
	
	
	[self setIsRunning:YES];
}

- (void)stop
{
	if(!isRunning) return;
	
	DCLog(NSLocalizedString(@"Stopping...", @"Debug Text"));
//	[t invalidate];
//	t = nil;
	
	CFRunLoopRemoveSource(CFRunLoopGetMain(), mmRunLoopSource, kCFRunLoopDefaultMode);
	
	[self setIsRunning:NO];
}

/*- (void)setTimerInterval:(double)val
{
	freq = val;
	if(isRunning)
	{
		[self stop];
		[self start];
	}
}*/

- (void)setDisabled:(BOOL)state withStatus:(int)code
{
	static int wasRunning;
	static int codes = 0;
	if(state) codes |=  (1 << code);
	else	  codes &= ~(1 << code);
	
	isDisabled = (BOOL)codes;
	[self setStatusItemImageForState:!isDisabled];
	if(isDisabled)
	{
		wasRunning = isRunning;
		[self stop];
	} else if(wasRunning) {
		[self start];
	}
}

- (void)setStatusItemImageForState:(BOOL)flag
{
	[wrapStatusItem setImage:[NSImage imageNamed:flag?@"stat.tiff":@"stat-disabled.tiff"]];
}


#pragma mark -
#pragma mark Point-Screen Conversion

- (void)setJumpEdges
{
	/*activeEdges[DCEdgeTop] = [[NSUserDefaults standardUserDefaults] boolForKey:@"Wrap Top"];
	activeEdges[DCEdgeBottom] = [[NSUserDefaults standardUserDefaults] boolForKey:@"Wrap Bottom"];
	activeEdges[DCEdgeLeft] = [[NSUserDefaults standardUserDefaults] boolForKey:@"Wrap Left"];
	activeEdges[DCEdgeRight] = [[NSUserDefaults standardUserDefaults] boolForKey:@"Wrap Right"];*/
	
	NSUInteger x = [[NSUserDefaults standardUserDefaults] integerForKey:UDWrapEdges];
	[outerEdges setEdgesEnabled:x&(1<<0) atAngle:  0.0];
	[outerEdges setEdgesEnabled:x&(1<<1) atAngle: 90.0];
	[outerEdges setEdgesEnabled:x&(1<<2) atAngle:180.0];
	[outerEdges setEdgesEnabled:x&(1<<3) atAngle:270.0];
}

- (void)buildScreensList {
	NSEnumerator * e = [[NSScreen screens] objectEnumerator];
	NSScreen *s;
	int i = 0;
	[outerEdges release];
	outerEdges = [[DCEdgeCollection alloc] init];
	while(s = [e nextObject]) {
		CGRect ff = [s flippedFrame];
		DCLog(@"%@ %d: %@", NSLocalizedString(@"Screen", @"Debug Text"), i++, NSStringFromCGRect(ff));
		[outerEdges addEdgesFromRect:ff];
	}
	[self setJumpEdges];
	
	DCLog(@"%@", outerEdges);
	DCLog(@"-----------------------------");
}

/*- (void)buildScreensList
{
	[DCScreen resetScreenIteration];
	
	CGRect r;// = CGRectZero;
	NSMutableArray *scr = [NSMutableArray array];
	NSEnumerator * e = [[NSScreen screens] objectEnumerator]; id o;
	
	[outerEdges release];
	outerEdges = [[DCEdgeCollection alloc] init];
	while(o = [e nextObject])
	{
		DCScreen *s = [DCScreen screenWithScreen:o];
		[outerEdges addEdgesFromRect:[s frame]];
		[scr addObject:s];
		r = CGRectUnion(r, [s frame]);
		
		[self writeDebugText:[NSString stringWithFormat:@"%@ %d: %@", NSLocalizedString(@"Screen", @"Debug Text"), [s screenNumber], NSStringFromCGRect([s frame])]];
	}
	[self setJumpAxes];
	
	 //Unioning screen rects erroneously adds an additional row/column
	r.size.width--;
	r.size.height--;
	
	biggestX  = CGRectGetMaxX(r);
	smallestX = CGRectGetMinX(r);
	biggestY  = CGRectGetMaxY(r);
	smallestY = CGRectGetMinY(r);
	
	[self writeDebugText:[NSString stringWithFormat:@"%@: (%0.f, %0.f)", NSLocalizedString(@"X Axis Boundaries", @"Debug Text"), smallestX, biggestX]];
	[self writeDebugText:[NSString stringWithFormat:@"%@: (%0.f, %0.f)", NSLocalizedString(@"Y Axis Boundaries", @"Debug Text"), smallestY, biggestY]];
	[self writeDebugText:[NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last", @"Debug Text"), NSStringFromCGPoint(lastPosition)]];
	NSLog(@"%@", outerEdges);
	[self writeDebugText:@"-----------------------------"];
	
	[screens release];
	screens = [scr copy];
}*/
	 
- (void)updateLocation:(CGEventRef)event {
	CGPoint curr = CGEventGetLocation(event);
	curr.x = (int)curr.x;curr.y = (int)curr.y;
	
	if([self debugEnabled])
		[coordinates setStringValue:[NSString stringWithFormat:@"(% 6.0f,% 6.0f)", curr]];
	
	DCEdge *e;
	if(e = [outerEdges edgeContainingPoint:curr]) {
		if([e isEqual:lastEdge]) {
			lastEdge = nil;
			return;
		}
		
		CGEventFlags currFlags = CGEventGetFlags(event);
		/*
		 Compare to:
		 kCGEventMaskAlphaShift		0x00010000		    10000000000000000	1<<16 ** NOT USED **
		 kCGEventFlagMaskShift		0x00020000		   100000000000000000	1<<17
		 kCGEventFlagMaskControl	0x00040000		  1000000000000000000	1<<18
		 kCGEventFlagMaskAlternate	0x00080000		 10000000000000000000	1<<19
		 kCGEventFlagMaskCommand	0x00100000		100000000000000000000	1<<20
		*/
		
		BOOL disableCorners = [[NSUserDefaults standardUserDefaults] boolForKey:UDDisableInCorners];
		CGFloat cornerDistance = (CGFloat)[[NSUserDefaults standardUserDefaults] integerForKey:UDCornerSize];
		NSUInteger pos = [[NSUserDefaults standardUserDefaults] integerForKey:UDAllEdgesModifiers];
		NSUInteger neg = [[NSUserDefaults standardUserDefaults] integerForKey:UDNoEdgesModifiers];
		
		//Ignore this event if the disable mod key is down
		if(currFlags & neg) {
			DCLog(@"\tDisabled via mod key", NSStringFromCGPoint(curr));
			return;
		}
		
		//Ignore this event if we're in a corner and corners are disabled
		if(disableCorners && [outerEdges isPoint:curr nearCorner:cornerDistance]) {
			DCLog(@"\t%@ is in a corner", NSStringFromCGPoint(curr));
			return;
		}
		
		//Ignore this event if we're on a disabled edge
		if(!([e active] || (currFlags & pos))) {
			DCLog(@"\t%@ is on a disabled edge", NSStringFromCGPoint(curr));
			return;
		}
		
		//Jump!
		CGPoint destination = curr;
		lastEdge = [outerEdges edgeOppositePoint:curr];
		CGPoint opp = [lastEdge location];
		if([e horizontal])
			destination.y = opp.y;
		else
			destination.x = opp.x;
		[self jumpToPoint:destination];
	}
}

- (void)jumpToPoint:(CGPoint)destination {
	DCLog(@"Jumping to %@", NSStringFromCGPoint(destination));
	CGEventRef event;
	if(event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, destination, 0)) {
		CGEventSetType(event,kCGEventMouseMoved);
		CGEventPost(kCGHIDEventTap,event);
		CFRelease(event);
	}
}

/*- (void)checkPosition:(NSTimer *)timer
{
	CGEventRef currEvent = CGEventCreate(NULL);
	CGPoint curr = CGEventGetLocation(currEvent);
	CFRelease(currEvent);
	
	static BOOL didJump = NO;
	
	int sn = [self whichScreen:curr];
	int en;
	BOOL samePoint = CGPointEqualToPoint(curr,lastPosition);
	
	
	//Ignore this event if we're not on a screen 
	if(sn == -1)
		[self writeDebugText:[NSString stringWithFormat:@">> %@ is not onscreen", NSStringFromCGPoint(curr)]];
	
	//Ignore this event if we're not on an edge
	else if((en = [self whichEdge:curr]) < 0)
		;//[self writeDebugText:[NSString stringWithFormat:@">> %@ is not on an edge", NSStringFromCGPoint(curr)]];
	
	//Ignore this event if we're at the same point as last time
	else if(samePoint)
		;//[self writeDebugText:[NSString stringWithFormat:@">> %@ has not moved", NSStringFromCGPoint(curr)]];
	
	
	else {
		//We're on an edge and have moved. Dataset is now small enough that we can log
		[self writeDebugText:@"<"];
		if(didJump) {
			[self writeDebugText:[NSString stringWithFormat:@"\t%@ -> %@", NSStringFromCGPoint(lastPosition), NSStringFromCGPoint(curr)]];
			didJump = NO;
		}
		
		CGEventFlags currFlags = CGEventGetFlags(event);
		//UInt32 currFlags = GetCurrentEventKeyModifiers();
		
		//Ignore this event if the disable mod key is down
		if(currFlags & (1<<[[NSUserDefaults standardUserDefaults] integerForKey:@"Negative Override Modifier"]))
			[self writeDebugText:[NSString stringWithFormat:@"\tDisabled via mod key", NSStringFromCGPoint(curr)]];
		
		//Ignore this event if we're in a corner and corners are disabled
		else if([[NSUserDefaults standardUserDefaults] boolForKey:@"Disable in Corners"] && [self isPoint:curr inCornerOfScreen:sn])
			[self writeDebugText:[NSString stringWithFormat:@"\t%@ is in a corner", NSStringFromCGPoint(curr)]];
		
		//Ignore this event if we're on a disabled edge
		else if(!(activeEdges[en] || (currFlags & (1<<[[NSUserDefaults standardUserDefaults] integerForKey:@"Positive Override Modifier"]))))
			[self writeDebugText:[NSString stringWithFormat:@"\t%@ is on a disabled edge", NSStringFromCGPoint(curr)]];
		
		//Ignore this event if we haven't moved from the last destination axis
		else if((en == DCEdgeLeft || en == DCEdgeRight ) && curr.x == lastPosition.x && DCValueInRange(curr.y, lastJumpPosition.y, [[NSUserDefaults standardUserDefaults] integerForKey:@"JumpAxisLockLength"]))
			[self writeDebugText:[NSString stringWithFormat:@"\t%@ is in V line with %@ (%d)", NSStringFromCGPoint(curr), NSStringFromCGPoint(lastPosition), [[NSUserDefaults standardUserDefaults] integerForKey:@"JumpAxisLockLength"]]];
		else if((en == DCEdgeTop  || en == DCEdgeBottom) && curr.y == lastPosition.y && DCValueInRange(curr.x, lastJumpPosition.x, [[NSUserDefaults standardUserDefaults] integerForKey:@"JumpAxisLockLength"]))
			[self writeDebugText:[NSString stringWithFormat:@"\t%@ is in H line with %@ (%d)", NSStringFromCGPoint(curr), NSStringFromCGPoint(lastPosition), [[NSUserDefaults standardUserDefaults] integerForKey:@"JumpAxisLockLength"]]];
		
		//Might's well jump
		else {
			//Go ahead, jump
			[self jumpFromPoint:curr onEdge:en];
			NSString *debugString = [NSString stringWithFormat:@"\t%@ %d: %@ -> %@", NSLocalizedString(@"Edge", @"Debug Text"), en, NSStringFromCGPoint(curr), NSStringFromCGPoint(lastPosition)];
			[self writeDebugText:debugString];
			lastJumpPosition = lastPosition;
			didJump = YES;
			[self writeDebugText:@"/J>"];
			return;
		}
		[self writeDebugText:@"/>"];
	}
	
	lastPosition = curr;
}*/

/*- (void)jumpFromPoint:(CGPoint)curr onEdge:(DCEdgeType)e {
	//Calculate the destination of this jump
	CGPoint destination = CGPointMake(0,0);
	switch(e) {
		case DCEdgeLeft:
			destination.x = biggestX;
			destination.y = curr.y;
			break;
		case DCEdgeRight:
			destination.x = smallestX;
			destination.y = curr.y;
			break;
		case DCEdgeTop:
			destination.x = curr.x;
			destination.y = biggestY;
			break;
		case DCEdgeBottom:
			destination.x = curr.x;
			destination.y = smallestY;
			break;
	}
	
	CGEventRef ev = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, destination, 0);
	CGEventSetType(ev,kCGEventMouseMoved);
	CGEventPost(kCGHIDEventTap,ev);
	CFRelease(ev);
	
	lastPosition = destination;
}*/

/*- (int)whichEdge:(CGPoint)p {
	for(int i=0; i<=3; i++)
		if([self whichScreen:[self warpPoint:p toward:i]] < 0)
			return i;
	return -1;	
}*/

/*- (int)whichScreen:(CGPoint)p
{
	//p.y--;
	int i;
	for(i=0; i < [screens count]; i++) {
		BOOL inRect = CGRectContainsPoint([(DCScreen *)[screens objectAtIndex:i] frame], p);
		//[self writeDebugText:[NSString stringWithFormat:@"P: %@ R: %@ S: %d In: %d", NSStringFromCGPoint(p), NSStringFromRect([(DCScreen *)[screens objectAtIndex:i] frame]), i, inRect]];
		if(inRect)
			return i;
	}
	return -1;
}*/

/*- (CGPoint)warpPoint:(CGPoint)p toward:(int)direction
{
	switch(direction)
	{
		case DCEdgeLeft: p.x--; break; //Left edge
		case DCEdgeRight: p.x++; break; //Right edge
		case DCEdgeTop: p.y--; break; //Top edge
		case DCEdgeBottom: p.y++; break; //Bottom edge
	}
	return p;
}*/

/*- (BOOL)isPoint:(CGPoint)p inCornerOfScreen:(int)screenNum
{
	int cornerRange;
	if((cornerRange = [[NSUserDefaults standardUserDefaults] integerForKey:@"Corner Size"]) < 1) return NO;

	CGRect f = [(DCScreen *)[screens objectAtIndex:screenNum] frame];
	CGPoint corner = CGPointMake(p.x>CGRectGetMidX(f)?CGRectGetMaxX(f):CGRectGetMinX(f), p.y>CGRectGetMidY(f)?CGRectGetMaxY(f):CGRectGetMinY(f));
	return [self distanceFromPoint:p toPoint:corner]<=cornerRange;
}*/

/*- (double)distanceFromPoint:(CGPoint)a toPoint:(CGPoint)b
{
	double x = (a.x-b.x), y = (a.y-b.y);
	return sqrt(x*x+y*y);
}*/

#pragma mark -
#pragma mark Login Item

- (BOOL)isLoginItemInstalled
{
/*	NSArray * loginItems = nil;
	if(LIAECopyLoginItems((CFArrayRef *)(&loginItems)) == noErr)
	{
		NSEnumerator * n = [loginItems objectEnumerator];
		NSDictionary * d;
		int i=0;
		while(d = [n nextObject])
		{
			NSString * liPath = [(NSURL *)[d objectForKey:@"URL"] path], * myPath = [[NSBundle mainBundle] bundlePath];
			if([liPath isEqualToString:myPath])
			{
				liIndex = i;
				return YES;
			}
			i++;
		}
	}
	return NO;*/
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	if(!appPath) {
		NSLog(@"Wraparound couldn't locate itself for for login item handling");
		return NO;
	}
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url;// = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems, 
															NULL);
	
	if (loginItems)
	{
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		CFArrayRef l = LSSharedFileListCopySnapshot(loginItems, &seedValue);
		if(!l) {
			NSLog(@"Could not get login items");
			return NO;
		}
		NSArray * loginItemsArray = [(NSArray *)l copy];
		CFRelease(l);
		for(int i=0; i<[loginItemsArray count]; i++)
		{
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr)
				if ([[(NSURL*)url path] compare:appPath] == NSOrderedSame)
				{
					[loginItemsArray release];
					return YES;
				}
			CFRelease(url);
		}
		[loginItemsArray release];
		CFRelease(loginItems);
	}
	return NO;
}

/*- (IBAction)toggleLoginItem:(id)sender
{
	if(![self isLoginItemInstalled] && ([sender state]==NSOnState))
		[self addToLoginItems];
	else if([self isLoginItemInstalled] && ([sender state]==NSOffState))
		[self removeFromLoginItems];
	
	[loginItemButton setState:[self isLoginItemInstalled]?NSOnState:NSOffState];
}*/

- (void)addToLoginItems
{
/*	NSURL * url = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	if(![self isLoginItemInstalled])
		if(LIAEAddURLAtEnd((CFURLRef)url, 1) != noErr)
			NSLog(NSLocalizedString(@"Wraparound failed to be added to Login items", @"Error Message"));*/
	
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	// We are adding it to the current user only.
	// If we want to add it all users, use
	// kLSSharedFileListGlobalLoginItems instead of
	// kLSSharedFileListSessionLoginItems
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems,
															NULL);
	if (loginItems) 
	{
		//Insert an item to the list.
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
																	 kLSSharedFileListItemLast, 
																	 NULL, 
																	 NULL,
																	 url, 
																	 NULL, 
																	 NULL);
		if(item)
		{
			CFRelease(item);
		}
		CFRelease(loginItems);
	}
}

- (void)removeFromLoginItems
{
/*	if([self isLoginItemInstalled] && liIndex >= 0)
		if(LIAERemove(liIndex) != noErr)
			NSLog(@"%@: %d", NSLocalizedString(@"Wraparound failed to be removed from Login items", @"Error Message"), liIndex);*/
	
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url;// = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
															kLSSharedFileListSessionLoginItems, 
															NULL);
	
	if (loginItems)
	{
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		CFArrayRef l = LSSharedFileListCopySnapshot(loginItems, &seedValue);
		NSArray * loginItemsArray = [(NSArray *)l copy];
		CFRelease(l);
		for(int i=0; i<[loginItemsArray count]; i++)
		{
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr)
			{
				NSString * urlPath = [(NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame)
				{
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
				CFRelease(url);
			}
		}
		[loginItemsArray release];
		CFRelease(loginItems);
	}
}

#pragma mark -
#pragma mark Delegate Methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Install Carbon event handler to hear about App-Changed events
	EventTypeSpec myEventTypes[1] = {{kEventClassApplication, kEventAppFrontSwitched}};
	InstallEventHandler(GetApplicationEventTarget(), 
						NewEventHandlerUPP(MyActiveApplicationDidChange),  
						1, myEventTypes, 
						self, 
						NULL);
	//[self activeApplicationDidChange];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	[self showWindow:nil];
	return NO;
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
	DCLog(@"-----------------------------\n");
	DCLog(NSLocalizedString(@"Screen Parameters Altered", @"Debug Text"));
	//[screens release];
	[self buildScreensList];
}

- (void)activeApplicationDidChange
{
	int appLimitType = [[NSUserDefaults standardUserDefaults] integerForKey:UDAppDisableMode];
	if(!appLimitType) 
	{
		[self setDisabled:NO withStatus:0];
	} else {
		BOOL inList = [[apps content] containsObject:[DCApplication activeApplication]];
		switch(appLimitType)
		{
			case 1:	[self setDisabled: inList withStatus:0]; break;
			case 2: [self setDisabled:!inList withStatus:0]; break;
		}
	}
}

#pragma mark -
#pragma mark TableView DataSource (Drag and Drop)

- (BOOL)tableView:(NSTableView *)tv 
writeRowsWithIndexes:(NSIndexSet *)rowIndexes         
	 toPasteboard:(NSPasteboard*)pboard
{
	return YES;
}
- (NSDragOperation)tableView:(NSTableView*)tv 
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView 
	   acceptDrop:(id <NSDraggingInfo>)info 
			  row:(NSInteger)row 
	dropOperation:(NSTableViewDropOperation)operation
{
	NSURL *url = [NSURL URLWithString:[[info draggingPasteboard] stringForType:(NSString *)kUTTypeFileURL]];
	NSString *file = [url path]; // path to some file
	CFStringRef fileExtension = (CFStringRef) [file pathExtension];
	CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
	if (UTTypeConformsTo(fileUTI, kUTTypeApplication)) {
		[self addApplication:[url path]];
		return YES;
	}
	return NO;
}


#pragma mark -
#pragma mark Debug

- (void)writeDebugText:(NSString *)dString
{
	static BOOL firsttime = YES;
	if(!(debugflags & (1 << 4))) return;
	
	//Write to file
	if(debugflags & (1 << 5)) {
		if(!dfh) {
			NSString * dPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/Wraparound.log"];
			if(![[NSFileManager defaultManager] fileExistsAtPath:dPath])
				[[NSString stringWithString:@""] writeToFile:dPath atomically:YES];
			dfh = [[NSFileHandle fileHandleForWritingAtPath:dPath] retain];
			[dfh seekToEndOfFile];
		}
		[dfh writeData:[[NSString stringWithFormat:@"[%@] %@\n", [NSDate date], dString] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	//Write to console
	if(debugflags & (1 << 7)) NSLog(@"%@", dString);
	
	firsttime = NO;
}

- (BOOL)debugEnabled
{
	return (BOOL)(debugflags & (1 << 4));
}

- (void)setDebugEnabled:(BOOL)val
{
	if(val) {
		debugflags |=  (1 << 4);
		
		NSDictionary * info = [[NSBundle mainBundle] infoDictionary];
		DCLog(@"-----------------------------\n");
		DCLog(@"%@ %@ (%@) %@", [info objectForKey:@"CFBundleName"],
								[info objectForKey:@"CFBundleShortVersionString"],
								[info objectForKey:@"CFBundleVersion"],
								NSLocalizedString(@"Debug Session",@"Debug String"));
		if([self isRunning])
			[self buildScreensList];
	} else {
		debugflags &= ~(1 << 4);
		[dfh closeFile];
		[dfh release];
		dfh = nil;
	}
	[[NSUserDefaults standardUserDefaults] setBool:val forKey:UDDebugEnabled];
}

- (BOOL)debugToConsole
{
	return (BOOL)(debugflags & (1 << 7));
}

- (void)setDebugToConsole:(BOOL)val
{
	if(val) debugflags |=  (1 << 7);
	else	debugflags &= ~(1 << 7);
}

- (BOOL)debugToFile
{
	return (BOOL)(debugflags & (1 << 5));
}

- (void)setDebugToFile:(BOOL)val
{
	if(val) debugflags |=  (1 << 5);
	else	debugflags &= ~(1 << 5);
}

@end

#pragma mark -
@implementation DCValueToRunningStateTransformer

+ (id)transformer
{
	id t = [[DCValueToRunningStateTransformer alloc] init];
	[t autorelease];
	return t;
}

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	return [value boolValue]?NSLocalizedString(@"Stop", @"Menu Label"):NSLocalizedString(@"Start", @"Menu Label");
}

- (id)reverseTransformedValue:(id)value
{
	return [NSNumber numberWithBool:[value isEqualToString:NSLocalizedString(@"Stop", @"Menu Label")]];
}

@end

@implementation NSScreen (DCAdditions)

- (CGRect)flippedFrame {
	CGFloat msh = [([[NSScreen screens] count]?[[NSScreen screens] objectAtIndex:0]:[NSScreen mainScreen]) frame].size.height;
	NSRect f = [self frame];
	CGRect r = CGRectMake(
					   f.origin.x,
					   //((f.origin.y>=0)? (msh-f.size.height): (f.size.height-msh))-f.origin.y,
					   msh-(f.origin.y+f.size.height),
					   f.size.width,
					   f.size.height);
	return r;
}

@end
