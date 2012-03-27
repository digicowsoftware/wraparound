/* DCWrap */

#import <Cocoa/Cocoa.h>

@class WebView;
@class DCEdge;
@class DCEdgeCollection;

/*typedef enum _DCEdgeType {
	DCEdgeLeft = 0,
	DCEdgeRight = 1,
	DCEdgeTop = 3,
	DCEdgeBottom = 2
} DCEdgeType;*/

@interface DCWrap : NSObject
{
	//Timing
	BOOL isRunning, isDisabled;
	CFRunLoopSourceRef mmRunLoopSource;
//	NSTimer * t;
//	double freq;

	//Screen Sizes/Edges
	DCEdgeCollection *outerEdges;
	DCEdge *lastEdge;
//	CGPoint lastPosition;
//	CGPoint lastJumpPosition;
//	NSArray * screens;
//	CGFloat biggestX, smallestX, biggestY, smallestY;
//	int start, end;
//	BOOL activeEdges[4];
	
	//Login Item
	CFIndex liIndex;

	//Prefs Window
	IBOutlet NSWindow * window;
	IBOutlet NSSegmentedControl *wrapEdges;
	IBOutlet NSSegmentedControl *wrapAllEdges;
	IBOutlet NSSegmentedControl *wrapNoEdges;
	IBOutlet NSTableView *appList;

	//Help
	IBOutlet WebView * helpView;
	
	//Menu
	IBOutlet NSMenu * sMenu;

	//Status Item
	NSStatusItem * wrapStatusItem;
	BOOL isMenuVisible;
	
	//App Handling
	IBOutlet NSArrayController * apps;
	//EventHandlerRef appChangedHandler;
	
	//Debug
	int debugflags;
	IBOutlet NSTextField *coordinates;
	NSFileHandle *dfh;
}

//Init
- (id)init;
- (void)awakeFromNib;
- (void)dealloc;

//Actions
- (IBAction)showAbout:(id)sender;
- (IBAction)showWindow:(id)sender;
- (IBAction)chooseWrapEdges:(id)sender;
- (IBAction)chooseAllEdgesModifiers:(id)sender;
- (IBAction)chooseNoEdgesModifiers:(id)sender;
- (IBAction)toggleWrapping:(id)sender;
- (IBAction)addAppToList:(id)sender;
- (IBAction)removeAppFromList:(id)sender;
- (IBAction)toggleDebug:(id)sender;

//Bindings
- (int)appDisableMode;
- (void)setAppDisableMode:(int)val;

- (int)cornerSize;
- (void)setCornerSize:(int)val;

//- (int)CPUUsage;
//- (void)setCPUUsage:(int)val;

- (BOOL)disableInCorners;
- (void)setDisableInCorners:(BOOL)val;

- (BOOL)displayAtLaunch;
- (void)setDisplayAtLaunch:(BOOL)val;

- (BOOL)displayInMenuBar;
- (void)setDisplayInMenuBar:(BOOL)val;

- (BOOL)startAtLogin;
- (void)setStartAtLogin:(BOOL)val;

- (BOOL)isRunning;
- (void)setIsRunning:(BOOL)val;
	
//Running Status
- (void)start;
- (void)stop;
//- (void)setTimerInterval:(double)val;
- (void)setStatusItemImageForState:(BOOL)flag;

//Point-Screen Conversion
- (void)buildScreensList;
- (void)setJumpEdges;

- (void)updateLocation:(CGEventRef)event;
- (void)jumpToPoint:(CGPoint)destination;

//- (void)checkPosition:(NSTimer *)timer;
//- (void)jumpFromPoint:(CGPoint)curr onEdge:(DCEdgeType)e;

//- (int)whichEdge:(CGPoint)p;
//- (int)whichScreen:(CGPoint)p;
//- (CGPoint)warpPoint:(CGPoint)p toward:(int)direction;
//- (BOOL)isPoint:(CGPoint)p inCornerOfScreen:(int)screenNum;
//- (double)distanceFromPoint:(CGPoint)a toPoint:(CGPoint)b;

//Login Item
- (BOOL)isLoginItemInstalled;
- (void)addToLoginItems;
- (void)removeFromLoginItems;

//Delegate Methods
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag;
- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification;
- (void)activeApplicationDidChange;

//Debug
- (void)writeDebugText:(NSString *)dString;

- (BOOL)debugEnabled;
- (void)setDebugEnabled:(BOOL)val;

- (BOOL)debugToConsole;
- (void)setDebugToConsole:(BOOL)val;

- (BOOL)debugToFile;
- (void)setDebugToFile:(BOOL)val;

@end

@interface DCValueToRunningStateTransformer : NSValueTransformer{}
+ (id)transformer;
+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;
@end
