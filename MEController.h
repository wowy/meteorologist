//
//  MEController.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MEWeather.h"
#import "MECity.h"
#import "MECityEditor.h"
#import "MEPrefs.h"
#import "MFAlertManager.h"

@interface MEController : NSObject //<NSTableViewDataSource, NSTableViewDelegate>
{
    NSMutableArray *cities;
    NSStatusItem *statusItem;
    NSMenu *menu;
    
    NSTimer *dataTimer, *cityTimer, *citiesTimer;
    
    BOOL isInDock;
    BOOL isInMenubar;
	int radarImageWidth;
    
    IBOutlet MECityEditor *cityEditor;
    
    IBOutlet NSTableView *cityTable;
	IBOutlet NSTableHeaderView *CityTableHeader;
	IBOutlet NSTextField *cityTableDescriptorText;
    IBOutlet NSButton *addCity;
    IBOutlet NSButton *removeCity;
    IBOutlet NSButton *editCity;
    IBOutlet NSButton *updateMenu;
    
    IBOutlet MEPrefs *prefsController;
    IBOutlet NSWindow *prefsWindow;
    
    IBOutlet NSTabView *prefTab;
    
    MECity *mainCity;
    IBOutlet MFAlertManager *alertManager;
    
    
    IBOutlet NSProgressIndicator *downloadWindowProgress;
    IBOutlet NSWindow *downloadWindow;
    IBOutlet NSTextField *downloadWindowText;
    IBOutlet NSTextField *downloadWindowName;
    IBOutlet NSTextField *downloadWindowSize;
    IBOutlet NSImageView *downloadWindowImage;
    
    IBOutlet NSTextField *versionTF;
    
    NSTimer *menuBarLoadTimer;
	
	// JRC
	NSMenuItem  *refreshMI,
				*showCityEditorMI,
				*citySwitcherMI,
				*preferencesMI,
				*quitMI;
				
	NSLock *menuDrawLock;
}

- (void)showCityController:(id)sender;
- (void)showPrefsController:(id)sender;
- (IBAction)newCity:(id)sender;
- (IBAction)editCity:(id)sender;
- (IBAction)removeCity:(id)sender;

- (IBAction)updateMenuNow:(id)sender;


- (void)notePrefsChanged;
- (void)resestablishTimers;
- (void)swicthCityEnabling;

- (void)generateMenu;
- (void)generateMenuWithNewData;
- (void)generateMenuWithNewData:(BOOL)newData newCities:(BOOL)newCities newCity:(BOOL)newCity;
- (void)addDataToMenu:(NSMenu **)theMenu forCity:(MECity **)city newData:(BOOL*)newData;

- (void)dummy;
- (NSArray *)activeCities;

- (NSMutableArray *)citiesForData:(NSMutableArray *)dataArray;
- (NSMutableArray *)dataForCities:(NSMutableArray *)cityArray;

NSFont* fontWithMaxHeight(NSString *name, int maxHeight);

- (IBAction)refreshCallback:(id)sender;
- (void)startLoadingInMenuBar;
- (void)stopLoadingInMenuBar;
- (void)updateDock;
+ (NSMutableDictionary *)bestAttributesForString:(NSString *)string size:(NSSize)size fontName:(NSString *)fontName;

@end



@interface NSString (LinkAdditions)

- (void)openLink:(id)sender;

@end
