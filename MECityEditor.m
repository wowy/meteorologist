//
//  MECityEditor.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MECityEditor.h"
#import "MEWeatherModuleParser.h"

@implementation MECityEditor

- (id)init
{
    //self = [super init];
    if(self = [super init]) 
	{
 //       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) 
 //                                             name:NSApplicationDidFinishLaunchingNotification object:NSApp];
		resultsTableData = [[MECitySearchResultsTable alloc] initWithRowCount: 25]; /* Weather.com returns 8 results */
	}
	return self;
}

- (void) dealloc
{
	[resultsTableData release];
	[super dealloc];
}

/* JRC - why not awakFromNib????*/
/*- (void)applicationDidFinishLaunching:(NSNotification *)not */
- (void) awakeFromNib
{
    NSButtonCell      *cell;
    NSPopUpButtonCell *pop;

	[window setTitle:NSLocalizedString(@"cityEditorWindowTitle",nil)];
	
	[[tabView tabViewItemAtIndex:0] setLabel:NSLocalizedString(@"serversTabTitle",@"")];
	[[tabView tabViewItemAtIndex:1] setLabel:NSLocalizedString(@"weatherItemsTabTitle",@"")];
	[[tabView tabViewItemAtIndex:2] setLabel:NSLocalizedString(@"forecastItemsTabTitle",@"")];
	
	[cityNameTitle setStringValue:NSLocalizedString(@"cityNameTitle",nil)];
	[cityDescription setStringValue:NSLocalizedString(@"cityNameDescriptionLabel",nil)];
	[weatherServersTitle setStringValue:NSLocalizedString(@"weatherServersTitle",nil)];
	[weatherDescription setStringValue:NSLocalizedString(@"weatherServersDescriptionTItle",nil)];
	[weatherModules setStringValue:NSLocalizedString(@"weatherModulesTable",nil)];
	[cityOrZipSearchTitle setStringValue:NSLocalizedString(@"cityOrZipSearchTitle",nil)];
	[search setTitle:NSLocalizedString(@"searchButtonTitle",nil)];
	
	[[[cityTable tableColumns] objectAtIndex:0] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"cityNameCellTitle",@"")] autorelease]];
	//[[cityTableHeaderView objectAtIndex:0] setHeaderCell:[[NSCell alloc] initTextCell:NSLocalizedString(@"cityNameCellTitle",@"")]];
	[onlyTheFirstEightDescription setStringValue:NSLocalizedString(@"onlyTheFirstEightDescriptionTitle",nil)];

	[cancelButton setTitle:NSLocalizedString(@"cancelButtonTitle",nil)];
	[confirmButton setTitle:NSLocalizedString(@"confirmButtonTitle",nil)];

	[currentWeatherItems setStringValue:NSLocalizedString(@"currentWeatherItemsTitle",nil)];
	[[[weatherPropertyTable tableColumns] objectAtIndex:0] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"currentWeatherItemsPropertyTitle",@"")] autorelease]];
	[[[weatherPropertyTable tableColumns] objectAtIndex:1] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"currentWeatherItemsOnTitle",@"")] autorelease]];
	[[[weatherPropertyTable tableColumns] objectAtIndex:2] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"currentWeatherItemsUnitTitle",@"")] autorelease]];
	[[[weatherPropertyTable tableColumns] objectAtIndex:3] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"currentWeatherItemsServerTitle",@"")] autorelease]];
	[cityPopUpButton setStringValue:NSLocalizedString(@"citiesListTitle",nil)];
	[applyCityPreferences setTitle:NSLocalizedString(@"ImportButtonTitle",nil)];
	
	[longTermForecastItems setStringValue:NSLocalizedString(@"longTermForecastItemsTitle",nil)];
	[[[forecastPropertyTable tableColumns] objectAtIndex:0] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"longTermForecastItemsOnTitle",@"")] autorelease]];
	[[[forecastPropertyTable tableColumns] objectAtIndex:1] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"longTermForecastItemsPropertyTitle",@"")] autorelease]];
	[[[forecastPropertyTable tableColumns] objectAtIndex:2] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"longTermForecastItemsUnitTitle",@"")] autorelease]];
	[[[forecastPropertyTable tableColumns] objectAtIndex:3] setHeaderCell:[[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"longTermForecastItemsServerTitle",@"")] autorelease]];
	
	cell = [[NSButtonCell alloc] init]; // got rid of retain based on TableViewDemo.m
    [cell setButtonType:NSSwitchButton];
    [cell setTitle:@""];
    [cell setImagePosition:NSImageOverlaps];
    [cell setControlSize:NSSmallControlSize];
    [[weatherPropertyTable tableColumnWithIdentifier:@"enabled"] setDataCell:cell];
    [cell release];
    
    pop = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
    [pop setBordered:NO];
    [pop setBezeled:NO];
    [pop setAutoenablesItems:NO];
    [pop setFont:[NSFont systemFontOfSize:11]];
    [[weatherPropertyTable tableColumnWithIdentifier:@"units"] setDataCell:pop];
    [pop release];
    
    pop = [[NSPopUpButtonCell alloc] initTextCell:@"Servers" pullsDown:YES];
    [pop setBordered:NO];
    [pop setBezeled:NO];
    [pop setAutoenablesItems:NO];
    [pop setAltersStateOfSelectedItem:NO];
    [pop setFont:[NSFont systemFontOfSize:11]];
    [[weatherPropertyTable tableColumnWithIdentifier:@"servers"] setDataCell:pop];
    [pop release];
    
    
    cell = [[NSButtonCell alloc] init];
    [cell setButtonType:NSSwitchButton];
    [cell setTitle:@""];
    [cell setImagePosition:NSImageOverlaps];
    [cell setControlSize:NSSmallControlSize];
    [[forecastPropertyTable tableColumnWithIdentifier:@"enabled"] setDataCell:cell];
    [cell release];
    
    pop = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
    [pop setBordered:NO];
    [pop setBezeled:NO];
    [pop setAutoenablesItems:NO];
    [pop setFont:[NSFont systemFontOfSize:11]];
    [[forecastPropertyTable tableColumnWithIdentifier:@"units"] setDataCell:pop];
    [pop release];
    
    pop = [[NSPopUpButtonCell alloc] initTextCell:@"Servers" pullsDown:YES];
    [pop setBordered:NO];
    [pop setBezeled:NO];
    [pop setAutoenablesItems:NO];
    [pop setAltersStateOfSelectedItem:NO];
    [pop setFont:[NSFont systemFontOfSize:11]];
    [[forecastPropertyTable tableColumnWithIdentifier:@"servers"] setDataCell:pop];
    [pop release];
    
    currentCity = nil;
    otherCities = nil;
    
    [progress setUsesThreadedAnimation:YES];
    
    [weatherPropertyTable  setAutosaveName:@"weatherPropertyTable"];
    [forecastPropertyTable setAutosaveName:@"forecastPropertyTable"];
    [(NSOutlineView *)weatherPropertyTable registerForDraggedTypes:
								[NSArray arrayWithObjects:[weatherPropertyTable autosaveName], nil]];
    [forecastPropertyTable registerForDraggedTypes:
								[NSArray arrayWithObjects:[forecastPropertyTable autosaveName], nil]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) 
								name:NSControlTextDidChangeNotification object:cityName]; 

	   
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:)
								name:NSTableViewSelectionDidChangeNotification object:cityTable];
								
	[weatherModules setEnabled:NO]; /* nasty bug when selecting from this, so we're not going to let them */
	
	[resultsTableData setEditable: NO];
	[cityTable setDataSource: resultsTableData];
	[cityTable setDelegate: resultsTableData];
}

#pragma mark -

/* In response to changes made in cityName NSTextField.  Updates searchTerm to be the same thing. */
- (void)textDidChange:(NSNotification *)aNotification
{
    [searchTerm setStringValue:[cityName stringValue]];
}

- (MECity *)editCity:(MECity *)city otherCities:(NSArray *)others withPrefsWindow:(NSWindow *)prefsWin
{
	int modalVal;
	if (currentCity)
		[currentCity autorelease]; /* JRC - was autorelease*/
    currentCity = [city retain];
    
	if (otherCities)
		[otherCities autorelease]; /* JRC - was autorelease*/
    otherCities = [others retain];
    
	/* add the "other cities" to the popup that lets you copy settings */
    [cityPopUpButton removeAllItems];
    NSEnumerator *cityEnum = [otherCities objectEnumerator];
    MECity *next;
    
    while(next = [cityEnum nextObject])
        [cityPopUpButton addItemWithTitle:[next cityName]];
        
    int count = [otherCities count];
    [cityPopUpButton setEnabled:count];
    [applyCityPreferences setEnabled:count];

	/* setup weather property table with data for the current city */
    [weatherPropertyTable setDelegate:self];
    [weatherPropertyTable setDataSource:[currentCity weatherAttributes]];
    [weatherPropertyTable reloadData];
    
	/* setup forecast table with data for the current city */
    [forecastPropertyTable setDelegate:self];
    [forecastPropertyTable setDataSource:[currentCity forecastAttributes]];
    [forecastPropertyTable reloadData];
    
	/* setup city table with no data */
    [resultsTableData deleteRows];
    [cityTable reloadData];
	
	/* setup the weather modules popup - i.e. Wunderground, NWS, Weather.com */
    [weatherModules removeAllItems];
    [weatherModules addItemsWithTitles:[MEWeather moduleNames]];
    [weatherModules selectItemAtIndex:0];
    [self weatherSourceChanged:nil];
    
	/* set our text fields based on the current city's name */
    [cityName setStringValue:[currentCity cityName]];
    [searchTerm setStringValue:[currentCity cityName]];
    
	/* select the first tab */
    [tabView selectFirstTabViewItem:nil];


	/* JRC - new way of doing things (sheet) */
	[[NSApplication sharedApplication] beginSheet:window 
									   modalForWindow:prefsWin 
									   modalDelegate:self 
									   didEndSelector:NULL 
									   contextInfo:NULL];

	modalVal = [NSApp runModalForWindow:window];
	
	[NSApp endSheet:window];
	[window orderOut:NULL];
		
	/* JRC - taken from "old way of doing things" */
	if (modalVal == NSOKButton)
	{
		[currentCity setCityName:[cityName stringValue]];
		return currentCity;
    }
    else
    {
        return nil;
    }
    
	/* run it as a modal */
/* OLD WAY!    if([NSApp runModalForWindow:window] == NSOKButton)
    {
        [currentCity setCityName:[cityName stringValue]];
        [window close];
    	return currentCity;
    }
    else
    {
        [window close];
        return nil;
    }
	*/
}

#pragma mark -
#pragma mark Delegate Methods:

/* called when the NSTableView is about to draw a particular cell for 
   weatherPropertyTable, forecastPropertyTable, and cityTable. No functionality
   seems to be defined for cityTable */
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell 
											forTableColumn:(NSTableColumn *)aTableColumn 
											row:(int)rowIndex
{
    if((aTableView == weatherPropertyTable || aTableView == forecastPropertyTable) && 
		[aCell isMemberOfClass:[NSButtonCell class]]) 
	{
        [aCell setState:[[[[aTableView dataSource] objectAtIndex:rowIndex] objectForKey:@"enabled"] boolValue]];
    }

    if((aTableView == weatherPropertyTable || aTableView == forecastPropertyTable) && 
		[aCell isMemberOfClass:[NSPopUpButtonCell class]])
    {
        NSString *key = [aTableColumn identifier];
        NSMutableDictionary *dict = [[aTableView dataSource] objectAtIndex:rowIndex];
        
        if([key isEqualToString:@"units"])
        {
            NSString *unit = [dict objectForKey:@"unit"];
            NSArray *units = [MEWeather unitsForKey:[dict objectForKey:@"property"]];
            
            [aCell addItemsWithTitles:units];
            
            NSEnumerator *itemEnum = [[aCell itemArray] objectEnumerator];
            NSMenuItem *nextItem;
            
            while(nextItem = [itemEnum nextObject])
            {
                [nextItem setEnabled:YES];
                [nextItem setAction:@selector(changeUnit:)];
                [nextItem setTarget:self];
            }
            
            nextItem = (NSMenuItem *)[aCell itemWithTitle:unit];
            if(nextItem)
            {
                //[nextItem setState:NSOnState];
                [aCell selectItem:nextItem];
            }
            else
            {
                nextItem = (NSMenuItem *)[aCell lastItem];
                [aCell selectItem:nextItem];
                unit = [nextItem title];
                [dict setObject:unit forKey:@"unit"];
            }
            
            if([unit isEqualToString:@"None"])
                [nextItem setEnabled:NO];
        }
        else if([key isEqualToString:@"servers"])
        {
            NSArray *selectedServers = [dict objectForKey:@"servers"];
            NSArray *allServers = [MEWeather moduleNamesSupportingProperty:[dict objectForKey:@"property"]];
            
            [aCell addItemsWithTitles:allServers];
            
            NSEnumerator *itemEnum = [[aCell itemArray] objectEnumerator];
            NSMenuItem *nextItem;
            
            while(nextItem = [itemEnum nextObject])
            {
                [nextItem setEnabled:YES];
                [nextItem setAction:@selector(changeServer:)];
                [nextItem setTarget:self];
            }
            
            NSEnumerator *servEnum = [selectedServers objectEnumerator];
            NSString *next;
            
            while(next = [servEnum nextObject])
            	[[aCell itemWithTitle:next] setState:NSOnState];
        }
    }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn item:(id)item
{
    if((outlineView == (NSOutlineView *)weatherPropertyTable || outlineView == (NSOutlineView *)forecastPropertyTable) && [aCell isMemberOfClass:[NSButtonCell class]])
    {
        if(![item objectForKey:@"enabled"])
        {
            [aCell setImagePosition:NSNoImage];
            [aCell setEnabled:NO];
        }
        else
        {
            [aCell setEnabled:YES];
            [aCell setImagePosition:NSImageOnly];
            [aCell setState:[[item objectForKey:@"enabled"] boolValue]];
        }
    }

    if((outlineView == (NSOutlineView *)weatherPropertyTable || outlineView == (NSOutlineView *)forecastPropertyTable) && [aCell isMemberOfClass:[NSPopUpButtonCell class]])
    {
        NSString *key = [aTableColumn identifier];
        NSMutableDictionary *dict = item;//[[outlineView dataSource] objectAtIndex:rowIndex];
        
        if(![dict objectForKey:@"enabled"])
        {
            [aCell setTitle:@""];
            return;
        }
        
        if([key isEqualToString:@"units"])
        {
            NSString *unit = [dict objectForKey:@"unit"];
            NSArray *units = [MEWeather unitsForKey:[dict objectForKey:@"property"]];
            
            [aCell addItemsWithTitles:units];
            
            NSEnumerator *itemEnum = [[aCell itemArray] objectEnumerator];
            NSMenuItem *nextItem;
            
            while(nextItem = [itemEnum nextObject])
            {
                [nextItem setEnabled:YES];
                [nextItem setAction:@selector(changeUnit:)];
                [nextItem setTarget:self];
            }
            
            nextItem = (NSMenuItem *)[aCell itemWithTitle:unit];
            if(nextItem)
            {
                //[nextItem setState:NSOnState];
                [aCell selectItem:nextItem];
            }
            else
            {
                nextItem = (NSMenuItem *)[aCell lastItem];
                [aCell selectItem:nextItem];
                unit = [nextItem title];
                [dict setObject:unit forKey:@"unit"];
            }
            
            if([unit isEqualToString:@"None"])
                [nextItem setEnabled:NO];
        }
        else if([key isEqualToString:@"servers"])
        {
            NSArray *selectedServers = [dict objectForKey:@"servers"];
            NSArray *allServers = [MEWeather moduleNamesSupportingProperty:[dict objectForKey:@"property"]];
            
            [aCell addItemsWithTitles:allServers];
            
            NSEnumerator *itemEnum = [[aCell itemArray] objectEnumerator];
            NSMenuItem *nextItem;
            
            while(nextItem = [itemEnum nextObject])
            {
                [nextItem setEnabled:YES];
                [nextItem setAction:@selector(changeServer:)];
                [nextItem setTarget:self];
            }
            
            NSEnumerator *servEnum = [selectedServers objectEnumerator];
            NSString *next;
            
            while(next = [servEnum nextObject])
            	[[aCell itemWithTitle:next] setState:NSOnState];
        }
    }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return (![item objectForKey:@"enabled"] && [[tableColumn identifier] isEqualToString:@"property"]);
}

#pragma mark -

- (void)changeUnit:(id)sender
{
    NSTableView *table;
    
    if([NSView focusView] == weatherPropertyTable)
        table = weatherPropertyTable;
    else
        table = forecastPropertyTable;

    int row = [table selectedRow];
    NSString *title = [(NSMenuItem *)sender title];
    
    NSString *key = @"unit";
    NSMutableDictionary *dict;
    
    if(table == forecastPropertyTable)
        dict = [[table dataSource] objectAtIndex:row];
    else
        dict = [(NSOutlineView *)table itemAtRow:row];
    
    NSString *unit = [dict objectForKey:key];
    
    if(!([unit isEqualToString:title]))
    {
        [sender setState:NSOnState];
        [dict setObject:title forKey:key];
    }
}

- (void)changeServer:(id)sender
{
    NSTableView *table;
    
    if([NSView focusView] == weatherPropertyTable)
        table = weatherPropertyTable;
    else
        table = forecastPropertyTable;

    int row = [table selectedRow];
    NSString *title = [sender title];
    
    NSString *key = @"servers";
    NSMutableDictionary *dict;
    
    if(table == forecastPropertyTable)
        dict = [[table dataSource] objectAtIndex:row];
    else
        dict = [(NSOutlineView *)table itemAtRow:row];
    
    NSMutableArray *servers = [dict objectForKey:key];
    
    if([servers containsObject:title])
    {
        [sender setState:NSOffState];
        [servers removeObject:title];
    }
    else
    {
        [sender setState:NSOnState];
        [servers addObject:title];
    }
}

/* @called-by: MECityEditor performSearch
			   Also in response to user clicks.
*/
- (void)tableViewSelectionDidChange:(NSNotification *)aNot
{
    if([aNot object] == cityTable)
    {
        int row = [cityTable selectedRow];
        if(row==-1)
            return;
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
		[dict addEntriesFromDictionary:[[cityTable dataSource] dataForRow:row]];
        if (dict != nil)
			[currentCity setCodeInfo:dict forServer:[weatherModules titleOfSelectedItem]];
    }
}

#pragma mark -
#pragma mark IBActions:
- (IBAction)weatherSourceActivenessChanged:(id)sender
{
    NSMutableDictionary *dict = [currentCity codeAndInfoForServer:[weatherModules titleOfSelectedItem]];
    [dict setObject:[NSNumber numberWithBool:![serverIsActive state]] forKey:@"inactive"];
    [currentCity recreateWeatherObject];
}

- (IBAction)weatherSourceChanged:(id)sender
{
    //[[cityTable dataSource] autorelease];
    //NSMutableDictionary *dict = [currentCity codeAndInfoForServer:[weatherModules titleOfSelectedItem]];
    
    Class moduleClass = [MEWeather moduleClassForName:[weatherModules titleOfSelectedItem]];
    [weatherInfos removeAllItems];
    [weatherInfos addItemsWithTitles:[moduleClass supportedInfos]];
    [weatherInfos setEnabled:[weatherInfos numberOfItems]];
    
/*    if(dict)
    {		
        [weatherInfos selectItemWithTitle:[dict objectForKey:@"info"]];
        [cityTable setDataSource:[NSMutableArray arrayWithObject:dict]];
        [serverIsActive setState:![[dict objectForKey:@"inactive"] boolValue]];
        [serverIsActive setEnabled:YES];
    }
    else
    {
        [weatherInfos selectItem:[weatherInfos lastItem]];
		[cityTable setDataSource:[NSMutableArray array]];
        [serverIsActive setEnabled:NO];
        [serverIsActive setState:NSOffState]; 
    }
    
	
    [cityTable reloadData]; */
}

/* JRC - Obsolete: Weather info removed since 1.4.0b*/
- (IBAction)weatherInfoChanged:(id)sender
{
    NSMutableDictionary *dict = [currentCity codeAndInfoForServer:[weatherModules titleOfSelectedItem]];
    NSString *weatherInfo = [dict objectForKey:@"info"];

    if(![weatherInfo isEqualToString:[weatherInfos titleOfSelectedItem]])
    {
        /*[[cityTable dataSource] release];
        [cityTable setDataSource:[[NSMutableArray array] retain]];*/
    }
    else
    {
		/*[[cityTable dataSource] release];
        [cityTable setDataSource:[[NSMutableArray arrayWithObject:dict] retain]]; */
    }
    
    [cityTable reloadData];
}

- (IBAction)performSearch:(id)sender
{
    NSString *weatherSource = [weatherModules titleOfSelectedItem];
//    NSString *weatherInfo = [weatherInfos titleOfSelectedItem];
    NSString *searchWord = [searchTerm stringValue];
    
    Class moduleClass = [MEWeather moduleClassForName:weatherSource];
    
    if(moduleClass)
    {
        [progress startAnimation:nil];
    
		// might need to retain this, but i don't think so...
		NSArray *results = [[MEWeatherModuleParser sharedInstance] performCitySearch:searchWord 
																	onServer:[moduleClass sourceName]];
        if (results == nil)
			NSLog(@"results was nil!");
		[resultsTableData deleteRows];
		
		if ([results count] == 0) {
			
			NSMutableDictionary *aDict = [NSMutableDictionary dictionaryWithCapacity:2];
			[aDict setObject:@"No Matching Cities Found." forKey:@"name"];
			[aDict setObject:@"-1" forKey:@"code"];
			
			[resultsTableData insertRowAt:0 withData:aDict];
			
			// now make it unselectable and grey
			[resultsTableData setSelectable:NO];
			[cityTable deselectRow:[cityTable selectedRow]];
		}
		else {
		
			NSEnumerator *itr = [results objectEnumerator];
			NSDictionary *aDict;
			int row=0;
		
			while (aDict = [itr nextObject]) {
				//NSString *test = [aDict objectForKey:@"name"];
				if ([(NSString *)[aDict objectForKey:@"name"] length] > 0)
					[resultsTableData insertRowAt:row++ withData:aDict]; // JRC
			}
			
			// make sure it's selectable and not grey 
			[cityTable reloadData]; // necessary to set selectable
			[resultsTableData setSelectable:YES];
			[cityTable selectRow:0 byExtendingSelection:NO];
			
			NSMutableDictionary *dict = [currentCity codeAndInfoForServer:weatherSource];
			[serverIsActive setState:![[dict objectForKey:@"inactive"] boolValue]];
			[serverIsActive setEnabled:YES];

		}
		[cityTable reloadData];
		
		[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:cityTable]];
        
        [progress stopAnimation:nil];
	}
}

- (IBAction)confirmEditing:(id)sender
{
    //do some checking
    
    NSString *theCityName = [cityName stringValue];
    
    if([theCityName isEqualToString:@""])
    {
        //error
        NSBeginAlertSheet(@"No City Name Provided",
                                  nil,
                                  nil,
                                  nil,
                                  window,
                                  nil,
                                  nil,
                                  nil,
                                  nil,
                                  @"Please enter a name for this city");
    }
    else
    {
        NSEnumerator *otherCityEnum = [otherCities objectEnumerator];
        MECity *anOtherCity;
        
        while(anOtherCity = [otherCityEnum nextObject])
            if([[anOtherCity cityName] isEqualToString:theCityName])
            {
                NSBeginAlertSheet(@"Duplicate City Name",
                                  nil,
                                  nil,
                                  nil,
                                  window,
                                  nil,
                                  nil,
                                  nil,
                                  nil,
                                  @"Please choose a city name different than one you have already chosen.");
                break;
            }
        
        if(!anOtherCity)
        {
            NSArray *mods = [[currentCity weatherReport] loadedModuleInstances];
        
            if(![mods count])
            {
                 NSBeginAlertSheet(@"No successful search performed",
                                   nil,
                                   nil,
                                   nil,
                                   window,
                                   nil,
                                   nil,
                                   nil,
                                   nil,
                                   @"Please enter your city name in the \"City Search\" field and hit the search button to find your city on the weather servers.  Meteorologist can't obtain weather info without going through this process for at least one weather server.");
            }
            else
            {
                NSEnumerator *modEnum = [mods objectEnumerator];
                MEWeatherModule *mod;
                
                while(mod = [modEnum nextObject])
                    if(![[[currentCity codeAndInfoForServer:[[mod class] sourceName]] objectForKey:@"inactive"] boolValue])
                        break;
                        
                if(!mod)
                {
                    NSBeginAlertSheet(@"No Active Weather Servers",
                                        nil,
                                        nil,
                                        nil,
                                        window,
                                        nil,
                                        nil,
                                        nil,
                                        nil,
                                        @"Although you have performed at least one search, you have disabled all your weather servers.  Please choose at least one weather server and swicth on the check box next to it.");
                }
                else
                    [NSApp stopModalWithCode:NSOKButton];
            }
        }
    }
}

- (IBAction)cancelEditing:(id)sender
{
    [NSApp stopModalWithCode:NSCancelButton];
}

- (IBAction)applyOtherCityPreferences:(id)sender
{
    NSString *otherCityName = [cityPopUpButton titleOfSelectedItem];
    
    if(otherCityName && ![otherCityName isEqualToString:@""])
    {
        MECity *thatCity = [otherCities objectAtIndex:[cityPopUpButton indexOfSelectedItem]];
        
        [currentCity setWeatherAttributes:[[thatCity weatherAttributes] duplicate]];
        [currentCity setForecastAttributes:[[thatCity forecastAttributes] duplicate]];
    }
    
    //rest table
    [weatherPropertyTable setDataSource:[currentCity weatherAttributes]];
    [weatherPropertyTable reloadData];
    
    [forecastPropertyTable setDataSource:[currentCity forecastAttributes]];
    [forecastPropertyTable reloadData];
}

- (IBAction)addWeatherGroup:(id)sender
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"Untitled" forKey:@"property"];
    [dict setObject:[NSMutableArray array] forKey:@"subarray"];
    
    int row = [weatherPropertyTable selectedRow];
    id item = nil;
    
    if(row != -1)
    {
        item = [(NSOutlineView *)weatherPropertyTable itemAtRow:row];
        int level = [(NSOutlineView *)weatherPropertyTable levelForItem:item];
        while([(NSOutlineView *)weatherPropertyTable levelForItem:item] >= level && row >= 0)
        {
            item = [(NSOutlineView *)weatherPropertyTable itemAtRow:row];
            row--;
        }
    }
    
    if(row == -1)
    {
        item = [weatherPropertyTable dataSource];
        row = 0;
    }
        
    
    if([item isKindOfClass:[NSArray class]])
    {
        [item insertObject:dict atIndex:row];
    }
    else
    {
        NSMutableArray *array = [item objectForKey:@"subarray"];
        [array addObject:dict];
    }
    
    [weatherPropertyTable reloadData];
}

- (IBAction)removeWeatherGroup:(id)sender
{
    int row = [weatherPropertyTable selectedRow];
    
    if(row == -1)
        return;
    
    id item = [(NSOutlineView *)weatherPropertyTable itemAtRow:row];
    
    if([item objectForKey:@"enabled"])
        return;
        
    id parent = item;
    int index = row;
    int level = [(NSOutlineView *)weatherPropertyTable levelForRow:row];
    
    while([(NSOutlineView *)weatherPropertyTable levelForRow:index] >= level && row>=0)
    {
        row--;
        parent = [(NSOutlineView *)weatherPropertyTable itemAtRow:row];
    }
    
    if(row == -1)
    {
        parent = [(NSOutlineView *)weatherPropertyTable dataSource];
    }
    
    NSMutableArray *subarray;
    
    if([parent isKindOfClass:[NSArray class]])
        subarray = parent;
    else
        subarray = [parent objectForKey:@"subarray"];
        
    index = [subarray indexOfObjectIdenticalTo:item];
    [subarray removeObjectAtIndex:index];
    
    NSEnumerator *itemEnum = [[item objectForKey:@"subarray"] reverseObjectEnumerator];
    id nextItem;
    
    while(nextItem = [itemEnum nextObject])
        [subarray insertObject:nextItem atIndex:index];
	//[item release]; JRC
    
    [weatherPropertyTable reloadData];
}


@end

#pragma mark -

@implementation NSTableColumn (METableColumnAdditions)

- (id)dataCellForRow:(int)row
{
    if(row != -1)
        return [[[self dataCell] copy] autorelease];
    else
        return nil;
}

@end

#pragma mark -

@implementation MECitySearchResultsTable

-(id) init
{
	return [self initWithRowCount:0];
}
	
-(id)initWithRowCount: (int)rowCount
{
    int i;

    if ((self = [super init]))
    {
        _editable = NO;
		_selectable = YES;
		
        rowData = [[NSMutableArray alloc] initWithCapacity: rowCount];
        for (i=0; i < rowCount; i++)
        {
            [rowData addObject: [NSMutableDictionary dictionary]];
       }
    }
    return self;
}

-(void)dealloc
{
	[rowData release];
	[super dealloc];
}

- (BOOL)isEditable
{
    return _editable;
}

- (void)setEditable:(BOOL)b
{
    _editable = b;
}

- (BOOL)isSelectable
{
	return _selectable;
}

- (void)setSelectable:(BOOL)b
{
	_selectable = b;
}

#pragma mark -

- (void)setData: (NSDictionary *)someData forRow: (int)rowIndex
{
    NSMutableDictionary *aRow;
    
    NS_DURING
        aRow = [rowData objectAtIndex: rowIndex];
    NS_HANDLER
        if ([[localException name] isEqual: @"NSRangeException"])
        {
            return;
        }
        else [localException raise];
    NS_ENDHANDLER
    
    [aRow addEntriesFromDictionary: someData];
}

- (NSDictionary *)dataForRow: (int)rowIndex
{
    NSDictionary *aRow;

    NS_DURING
        aRow = [rowData objectAtIndex: rowIndex];
    NS_HANDLER
        if ([[localException name] isEqual: @"NSRangeException"])
        {
            NSLog(@"Setting data out of bounds.");
            return nil;
        }
        else [localException raise];
    NS_ENDHANDLER

    return [NSDictionary dictionaryWithDictionary: aRow];
}

#pragma mark -

- (int)rowCount
{
    return [rowData count];
}

#pragma mark -
#pragma mark Table Data Source:

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [rowData count];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
    row:(int)rowIndex
{
    NSDictionary *aRow;
        
    NS_DURING
        aRow = [rowData objectAtIndex: rowIndex];
    NS_HANDLER
        if ([[localException name] isEqual: @"NSRangeException"])
        {
            return nil;
        }
        else [localException raise];
    NS_ENDHANDLER
    
    return [aRow objectForKey: [aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView 
    setObjectValue:(id)anObject 
    forTableColumn:(NSTableColumn *)aTableColumn 
    row:(int)rowIndex
{
    NSString *columnName;
    NSMutableDictionary *aRow;
    
    if ( [self isEditable] )
    {
        NS_DURING
            aRow = [rowData objectAtIndex: rowIndex];
        NS_HANDLER
            if ([[localException name] isEqual: @"NSRangeException"])
            {
                return;
            }
            else [localException raise];
        NS_ENDHANDLER
        
        columnName = [aTableColumn identifier];
        [aRow setObject:anObject forKey: columnName];
    }
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	return [self isSelectable];
}

#pragma mark -
- (void) insertRowAt:(int)rowIndex
{
    [self insertRowAt: rowIndex withData: [NSMutableDictionary dictionary]];
}

- (void) insertRowAt:(int)rowIndex withData:(NSDictionary *)someData
{
	#ifdef NSDEBUG
	NSLog(@"Inserting at row: %i",rowIndex);
	#endif
    [rowData insertObject: someData atIndex: rowIndex];
}

- (void) deleteRowAt:(int)rowIndex
{    
    [rowData removeObjectAtIndex: rowIndex];
}

- (void) deleteRows
{
	[rowData removeAllObjects];
}

@end