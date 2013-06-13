//
//  MECityEditor.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MECity.h"

/* Special Thanks to: Adam Vandenberg for this code.
					  http://flangy.com/dev/osx/tableviewdemo/
*/
@interface  MECitySearchResultsTable : NSObject //<NSTableViewDataSource, NSTableViewDelegate,
														// NSOutlineViewDataSource, NSOutlineViewDelegate>
{
	NSMutableArray *rowData;
	BOOL _editable, _selectable;
}

- (id)initWithRowCount:(int)rowCount;

- (int)rowCount;

- (BOOL)isEditable;
- (void)setEditable:(BOOL)b;
- (BOOL)isSelectable;
- (void)setSelectable:(BOOL)b;

- (void)setData:(NSDictionary*)someData forRow: (int)rowIndex;
- (NSDictionary *)dataForRow: (int)rowIndex;

- (void) insertRowAt:(int)rowIndex;
- (void) insertRowAt:(int)rowIndex withData: (NSDictionary *)someData;
- (void) deleteRowAt:(int)rowIndex;
- (void) deleteRows;
@end

@interface MECityEditor : NSObject 
{
	IBOutlet NSWindow  *window;
	IBOutlet NSTabView *tabView;
    
	IBOutlet NSTextField *cityName;
	IBOutlet NSTextField *cityNameTitle;
	IBOutlet NSTextField *cityDescription;
	IBOutlet NSTextField *weatherServersTitle;
	IBOutlet NSTextField *weatherDescription;
	IBOutlet NSTextField *cityOrZipSearchTitle;
	IBOutlet NSTextField *onlyTheFirstEightDescription;
	IBOutlet NSTableHeaderView *cityTableHeaderView;
	
	IBOutlet NSTextField *currentWeatherItems;
	IBOutlet NSTableHeaderView *currentWeatherItemsTable;
	
	IBOutlet NSPopUpButton       *weatherModules;
	IBOutlet NSPopUpButton       *weatherInfos;
	IBOutlet NSTextField         *searchTerm;
	IBOutlet NSButton            *search;
	IBOutlet NSProgressIndicator *progress;
	
	IBOutlet NSTableView *cityTable;
	
	IBOutlet NSTextField *longTermForecastItems;
	IBOutlet NSTableHeaderView *longTermForecastItemsTable;
	
	IBOutlet NSOutlineView *weatherPropertyTable;
	IBOutlet NSTableView   *forecastPropertyTable;
	IBOutlet NSPopUpButton *cityPopUpButton;
	IBOutlet NSButton      *applyCityPreferences;
	
	IBOutlet NSButton *confirmButton;
	IBOutlet NSButton *cancelButton;
	
	MECity  *currentCity;
	NSArray *otherCities;
	
	IBOutlet NSButton *serverIsActive;
	
	/*JRC*/
	MECitySearchResultsTable *resultsTableData;
}

- (MECity *)editCity:(MECity *)city otherCities:(NSArray *)others withPrefsWindow:(NSWindow *)prefsWin;

- (IBAction)weatherSourceActivenessChanged:(id)sender;
- (IBAction)weatherSourceChanged:(id)sender;
- (IBAction)weatherInfoChanged:(id)sender;

- (IBAction)performSearch:(id)sender;
- (IBAction)confirmEditing:(id)sender;
- (IBAction)cancelEditing:(id)sender;

- (IBAction)applyOtherCityPreferences:(id)sender;

- (IBAction)addWeatherGroup:(id)sender;
- (IBAction)removeWeatherGroup:(id)sender;

@end



@interface NSTableColumn (METableColumnAdditions)

- (id)dataCellForRow:(int)row;

@end