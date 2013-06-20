//
//  MEController.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MEController.h"

@implementation NSMutableArray (CityControllerTableDS)

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString *key = [aTableColumn identifier];

    if([key isEqualToString:@"cityName"])
        return [[self objectAtIndex:rowIndex] cityName];
    else if([key isEqualToString:@"active"])
    {
        NSButtonCell *aCell = [[NSButtonCell alloc] init];
    
        [aCell setButtonType:NSSwitchButton];
        [aCell setTitle:@""];
        [aCell setImagePosition:NSImageOverlaps];
        [aCell setState:[[self objectAtIndex:rowIndex] isActive]];
        
        return aCell;
    }
    else if([key isEqualToString:@"city"])
        return [[self objectAtIndex:rowIndex] objectForKey:key];
    else if([key isEqualToString:@"property"])
    {
        NSString *value = [[self objectAtIndex:rowIndex] objectForKey:key];
        if([value hasPrefix:@"Forecast - "])
            value = [value substringFromIndex:11];
        return NSLocalizedString(value,@"");
    }
    /*else if([key isEqualToString:@"enabled"])
    {
        NSButtonCell *aCell = [[[NSButtonCell alloc] init] autorelease];
    
        [aCell setButtonType:NSSwitchButton];
        [aCell setTitle:@""];
        [aCell setImagePosition:NSImageOverlaps];
        [aCell setState:[[[self objectAtIndex:rowIndex] objectForKey:key] boolValue]];
        
        return aCell;
    }*/
    else
        return nil;
} // tableView

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString *key = [aTableColumn identifier];
    if([key isEqualToString:@"enabled"])
    {
        NSMutableDictionary *dict = [self objectAtIndex:rowIndex];
        [dict setObject:[NSNumber numberWithBool:![[dict objectForKey:key] boolValue]] forKey:key];
    }
} // tableView

- (BOOL)tableView:(NSTableView*)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
    NSArray *selectedRows;
    NSEnumerator *rowEnum;
    NSNumber *aRow;
    
    if(row<0)
        return NO;
    
    selectedRows = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:[tableView autosaveName]]];

    rowEnum = [selectedRows objectEnumerator];

    while(aRow = [rowEnum nextObject])
    {
        int index = [aRow intValue];
        
        id obj = [self objectAtIndex:index];
        [self replaceObjectAtIndex:index withObject:[NSNull null]];
        
        [self insertObject:obj atIndex:row];
        [self removeObject:[NSNull null]];
    }
    
    if([[self lastObject] isMemberOfClass:[MECity class]])
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MECityOrderChanged" object:nil];
    
    [tableView reloadData];
    return YES;
} // tableView

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationMove;
} // tableView

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    NSString *type = [tableView autosaveName];

    [pboard declareTypes:[NSArray arrayWithObjects:type,nil] owner:self];
    [pboard setData:[NSArchiver archivedDataWithRootObject:rows] forType:type];
    [pboard setString:[rows description] forType: NSStringPboardType];
    return YES;
} // tableView


- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item)
        return [[item objectForKey:@"subarray"] objectAtIndex:index];
    else
        return [self objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return (![item objectForKey:@"enabled"]);
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(!item)
        return [self count];
    else
        return [[item objectForKey:@"subarray"] count];
} // outlineView

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *key = [tableColumn identifier];

    if([key isEqualToString:@"city"])
        return [item objectForKey:key];
    else if([key isEqualToString:@"property"])
    {
        NSString *value = [item objectForKey:key];
        if([value hasPrefix:@"Forecast - "])
            value = [value substringFromIndex:11];
        return NSLocalizedString(value,@"");
    }
    else
        return nil;
} // outlineView

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *key = [tableColumn identifier];
    if([key isEqualToString:@"enabled"] && [item objectForKey:@"enabled"])
        [item setObject:[NSNumber numberWithBool:![[item objectForKey:key] boolValue]] forKey:key];
    else if([key isEqualToString:@"property"] && ![item objectForKey:@"enabled"])
    {
        [item setObject:object forKey:@"property"];
    }
} // outlineView

- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    return NSDragOperationMove;
} // outlineView

- (BOOL)outlineView:(NSOutlineView*)outlineView
         acceptDrop:(id <NSDraggingInfo>)info
               item:(id)item
         childIndex:(NSInteger)index
{
    NSArray *selectedRows;
    NSEnumerator *rowEnum;
    NSNumber *aRow;
    
    if(index<0 || index==NSNotFound)
        return NO;
    
    selectedRows = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:[outlineView autosaveName]]];

    rowEnum = [selectedRows objectEnumerator];

    while(aRow = [rowEnum nextObject])
    {
        int ind = [aRow intValue];
        
        id obj = [outlineView itemAtRow:ind];
        
        
        //find the real item
        int level;
        
        if(!item)
            item = self;
        
        //find the parent
        id parent = obj;
        int parentIndex = ind;
        level = [outlineView levelForItem:obj];
        
        while([outlineView levelForItem:parent] >= level && parentIndex>=0)
        {
            parentIndex--;
            parent = [outlineView itemAtRow:parentIndex];
        }
        
        if(parentIndex == -1)
        {
            parent = self;
        }
        
        NSMutableArray *subArray;
        
        if([parent isKindOfClass:[NSArray class]])
            subArray = parent;
        else
            subArray = [parent objectForKey:@"subarray"];
        
        [subArray replaceObjectAtIndex:[subArray indexOfObjectIdenticalTo:obj] withObject:[NSNull null]]; 
        
        if([item isKindOfClass:[NSArray class]])
            [item insertObject:obj atIndex:index];
        else
            [[item objectForKey:@"subarray"] insertObject:obj atIndex:index];

        [subArray removeObject:[NSNull null]];
    }
    
    [outlineView reloadData];
    return YES;

} // outlineView

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    NSString *type = [outlineView autosaveName];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[items count]];
    
    NSEnumerator *itemEnum = [items objectEnumerator];
    id item;
    
    while(item = [itemEnum nextObject])
        [array addObject:[NSNumber numberWithInt:[outlineView rowForItem:item]]];

    [pboard declareTypes:[NSArray arrayWithObjects:type,nil] owner:self];
    [pboard setData:[NSArchiver archivedDataWithRootObject:array] forType:type];
    [pboard setString:[items description] forType: NSStringPboardType];
    
    return YES;
} // outlineView

@end


@implementation MEController

- (void)updateLocalImages
{
    NSArray *imageArray = [NSArray arrayWithObjects:@"MB-Flurries.tiff",
                @"MB-Hazy.tiff",@"MB-Alert.tiff",@"MB-Cloudy.tiff",
                @"MB-Moon.tiff",@"MB-Moon-Cloud-1.tiff",@"MB-Moon-Cloud-2.tiff",
                @"MB-Moon.tiff",@"MB-Rain.tiff",@"MB-Sleet.tiff",
                @"MB-Snow.tiff",@"MB-Sun-Cloud-1.tiff",@"MB-Sun-Cloud-2.tiff",
                @"MB-Sun.tiff",@"MB-Thunderstorm.tiff",@"MB-Unknown.tiff",
                @"MB-Cloudy.tiff",@"MB-Wind.tiff",@"MB-Unavailable.tiff",
                                                    
                @"Loading-1.tiff",@"Loading-2.tiff",@"Loading-3.tiff",
                @"Loading-4.tiff",@"Loading-5.tiff",@"Loading-6.tiff",
                @"Loading-7.tiff",@"Loading-8.tiff",
                                                    
                @"MoonPhase-1.tiff",@"MoonPhase-2.tiff",@"MoonPhase-3.tiff",
                @"MoonPhase-4.tiff",@"MoonPhase-5.tiff",@"MoonPhase-6.tiff",
                @"MoonPhase-7.tiff",@"MoonPhase-8.tiff",@"MoonPhase-9.tiff",
                @"MoonPhase-10.tiff",@"MoonPhase-11.tiff",@"MoonPhase-12.tiff",
                @"MoonPhase-13.tiff",@"MoonPhase-14.tiff",@"MoonPhase-15.tiff",
                @"MoonPhase-16.tiff",@"MoonPhase-17.tiff",@"MoonPhase-18.tiff",
                @"MoonPhase-19.tiff",@"MoonPhase-20.tiff",@"MoonPhase-21.tiff",
                @"MoonPhase-22.tiff",@"MoonPhase-23.tiff",@"MoonPhase-24.tiff",
                @"MoonPhase-25.tiff",@"MoonPhase-26.tiff",
                
                @"Television-Day-Screen.tiff",@"Television-Day.tiff",
                @"Television-Night-Screen.tiff",@"Television-Night.tiff",
                @"Television.tiff",
                
                @"Temperature-1.tiff",@"Temperature-2.tiff",
                @"Temperature-3.tiff",@"Temperature-4.tiff",
                @"Temperature-5.tiff",@"Temperature-6.tiff",
                @"Temperature-7.tiff",@"Temperature-8.tiff",
                @"Temperature-9.tiff",
                                                    
                @"Moon-Cloud-1.tiff",@"Moon-Cloud-2.tiff",@"Sun-Cloud-1.tiff",
                @"Sun-Cloud-2.tiff",
                
                @"Cloudy.tiff",@"Alert.tiff",@"Sun.tiff",@"Hazy.tiff",
                @"Moon.tiff",@"Rain.tiff",@"Snow.tiff",@"Flurries.tiff",
                @"Sleet.tiff",@"Thunderstorm.tiff",@"Unknown.tiff",@"Wind.tiff",
                
                nil];
                                                    
    NSString *local = [[NSBundle mainBundle] resourcePath];
    
    NSFileManager *man = [NSFileManager defaultManager];
    NSEnumerator  *imageEnum = [imageArray objectEnumerator];
    NSString      *next;
    
    BOOL foundAll = YES;
    
    while(next = [imageEnum nextObject]) {
        if(![man fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",local,next]]) {
            foundAll = NO;
            NSLog(@"Missing image: %@/%@",local,next);
            //break;
        }
    }
    if (foundAll) {
		if([[MEPrefs sharedInstance] logMessagesToConsole])
		{
     	   NSLog(@"All images found inside of the Meteorologist resources folder");
		}
	}
    else {
        NSRunAlertPanel(@"Missing Icons",@"Meteorologist is missing some icons.  Please download Meteorologist again.",nil,nil,nil);
        //NSAlert(@"Meteorologist is missing some icons.  Please download");
    }
} // updateLocalImages

void catchException(NSException *exception)
{
    NSLog(@"%@: %@: %@",[exception name],[exception reason],[[exception userInfo] description]);
} // catchException

- (void)applicationDidFinishLaunching:(NSNotification *)not
{
	menuDrawLock = [[NSLock alloc] init];
	radarImageWidth = 0;

	[[prefTab tabViewItemAtIndex:0] setLabel:NSLocalizedString(@"weatherTabTitle",@"")];
	[[prefTab tabViewItemAtIndex:1] setLabel:NSLocalizedString(@"citiesTabTitle",@"")];
	[[prefTab tabViewItemAtIndex:2] setLabel:NSLocalizedString(@"updatingTabTitle",@"")];
	[[prefTab tabViewItemAtIndex:3] setLabel:NSLocalizedString(@"alertsTabTitle",@"")];
	[[prefTab tabViewItemAtIndex:4] setLabel:NSLocalizedString(@"aboutTabTitle",@"")];
	
	[[[cityTable tableColumns] objectAtIndex:0] setHeaderCell:[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"citiesTabHeaderActiveText",@"")]];
	[[[cityTable tableColumns] objectAtIndex:1] setHeaderCell:[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"citiesTabHeaderNameText",@"")]];
	[[[cityTable tableColumns] objectAtIndex:2] setHeaderCell:[[NSTableHeaderCell alloc] initTextCell:NSLocalizedString(@"citiesTabHeaderServersText",@"")]];
	[cityTableDescriptorText setStringValue:NSLocalizedString(@"citiesTabDescriptonText",nil)];
	[addCity setTitle:NSLocalizedString(@"addCityTitle",nil)];
	[editCity setTitle:NSLocalizedString(@"editCityTitle",nil)];
	[removeCity setTitle:NSLocalizedString(@"removeCityTitle",nil)];
	[updateMenu setTitle:NSLocalizedString(@"updateMenuTitle",nil)];
	
	[downloadWindow setTitle:NSLocalizedString(@"downloadWindowTitle",nil)];
	[downloadWindowText setStringValue:NSLocalizedString(@"downloadWindowTextText",nil)];
	[downloadWindowName setStringValue:NSLocalizedString(@"downloadWindowNameText",nil)];
	[downloadWindowSize setStringValue:NSLocalizedString(@"downloadWindowSizeText",nil)];
	

    NSSetUncaughtExceptionHandler(catchException);

    [self updateLocalImages];

    NSPopUpButtonCell *pop = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
    [pop setBordered:NO];
    [pop setBezeled:NO];
    [pop setAutoenablesItems:NO];
    [pop setAltersStateOfSelectedItem:NO];
    [[cityTable tableColumnWithIdentifier:@"activeServers"] setDataCell:pop];

    NSButtonCell *cell = [[NSButtonCell alloc] init];
    [cell setButtonType:NSSwitchButton];
    [cell setTitle:@""];
    [cell setImagePosition:NSImageOverlaps];
    [[cityTable tableColumnWithIdentifier:@"active"] setDataCell:cell];
    [cell setTarget:self];
    [cell setAction:@selector(swicthCityEnabling)];
    
    [cityTable setAutosaveName:@"cityTable"];
    [cityTable registerForDraggedTypes:[NSArray arrayWithObjects:[cityTable autosaveName], nil]];
    [cityTable setTarget:self];
    [cityTable setDoubleAction:@selector(editCity:)];
    
    isInDock = [prefsController displayInDock];
    isInMenubar = [prefsController displayInMenubar];
    
    if(isInDock) {
		if([[MEPrefs sharedInstance] logMessagesToConsole])
		{
			NSLog(@"Meteo configured to load in dock");
		}
    }
    
    if(isInMenubar)
    {
		if([[MEPrefs sharedInstance] logMessagesToConsole])
		{
			NSLog(@"Meteo configured to load in menubar");
		}
		statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[statusItem setTitle:@"Loading..."];
		[statusItem setHighlightMode:YES];
		
		NSMenu *tempMenu = [[NSMenu alloc] init];
		[[tempMenu addItemWithTitle:@"Please wait while Meteo fetches the weather" action:@selector(dummy) keyEquivalent:@""] setTarget:self];
		[statusItem setMenu:tempMenu];
		quitMI = (NSMenuItem *)[tempMenu addItemWithTitle:NSLocalizedString(@"Quit",@"") 
												   action:@selector(terminate:) 
											keyEquivalent:@""];
		[quitMI setTarget:NSApp];
    }

    cities = [[NSUserDefaults standardUserDefaults] objectForKey:@"cities"];
    if(!cities)
        cities = [[NSMutableArray alloc] init];
    else
        cities = [self citiesForData:cities];
    
    [cityTable setDataSource:cities];
    
    if([cities count] == 0)
	{
		[cities addObject:[[MECity alloc] initWithCityAndInfoCodes:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"Cupertino, CA",@"name",@"USCA0273",@"code",nil],@"Weather.com",nil]
															forCity:@"Cupertino, CA"]];
        [self showCityController:nil];
	}
        
    menu = nil; // where's this allocated?
    
    dataTimer = nil;
    cityTimer = nil;
    citiesTimer = nil;
    
    mainCity = nil;

    [self notePrefsChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notePrefsChanged) name:@"MEPrefsChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteCityOrderChanged) name:@"MECityOrderChanged" object:nil];
    
    if([prefsController killOtherMeteo])
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MEOtherMeteoWasLaunched" object:nil userInfo:nil deliverImmediately:YES];
        
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(otherMeteoWasLaunched:) name:@"MEOtherMeteoWasLaunched" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(generateMenuWithNewData) name:@"com.apple.system.config.network_change" object:nil];

	if ([cities count] < 1) {
		[editCity setEnabled:NO];
		[removeCity setEnabled:NO];
		//NSLog(@"Deactivating...");
	}
	
	if ([NSApp isHidden]) // fixes a bug where Meteo wasn't selected if it was a hidden startup item
		[NSApp unhideWithoutActivation];
        
    [versionTF setStringValue:[NSString stringWithFormat:@"%@ %@ (%@ %@)",NSLocalizedString(@"Version",@"Version as displayed in \"About\""),[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"],NSLocalizedString(@"build",@"build as displayed in \"About\""),[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]]];
		
} // applicationDidFinishLaunching

- (void)otherMeteoWasLaunched:(NSNotification *)not
{
    NSLog(@"otherMeteoWasLaunched()");
    [NSApp terminate:nil];
} // otherMeteoWasLaunched

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSLog(@"applicationShouldTerminate()");
    [prefsController checkUnsavedPrefs];
    [prefsController outletAction:nil];

    [[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:@"cities"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [NSApp setApplicationIconImage:[NSImage imageNamed:@"meteo"]]; // JRC - Not sure what the point is...

    return YES;
} // applicationShouldTerminate

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return menu;
} // applicationDockMenu

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(aTableView == cityTable && [aCell isMemberOfClass:[NSPopUpButtonCell class]])
    {
        if([[aTableColumn identifier] isEqualToString:@"activeServers"])
        {
            MEWeather *weather = [[cities objectAtIndex:rowIndex] weatherReport];
            NSArray *mods = [weather loadedModuleInstances];
            
            NSEnumerator *modEnum = [mods objectEnumerator];
            MEWeatherModule *mod;
            
            while(mod = [modEnum nextObject])
            {
                [aCell addItemWithTitle:[[mod class] sourceName]];
                [[aCell lastItem] setEnabled:![mod supplyingOldData]];
            }
        }
    }
} // tableView

- (void)showCityController:(id)sender
{
	[prefTab selectTabViewItemAtIndex:1];
	[prefsWindow makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
} // showCityController

- (void)showPrefsController:(id)sender
{
	[prefTab selectTabViewItemAtIndex:0];
	[prefsWindow makeKeyAndOrderFront:nil];
	[NSApp activateIgnoringOtherApps:YES];
} // showPrefsController

- (IBAction)newCity:(id)sender
{
	MECity *newCity = [cityEditor editCity:[MECity defaultCity] otherCities:[NSMutableArray arrayWithArray:cities] withPrefsWindow:prefsWindow];
    
	if(newCity)
	{
		[cities addObject:newCity];
		[editCity setEnabled:YES];
		[removeCity setEnabled:YES];
		[cityTable reloadData];
        
		[[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:@"cities"];
		[[NSUserDefaults standardUserDefaults] synchronize];
        
		[self generateMenu];
    }
} // newCity

- (IBAction)editCity:(id)sender
{
    int row = [cityTable selectedRow];
    
    if(row != -1)
    {
        [dataTimer invalidate];
        [cityTimer invalidate];
        [citiesTimer invalidate];
        
        dataTimer = nil;
        cityTimer = nil;
        citiesTimer = nil;
    
        MECity *cityToEdit = [cities objectAtIndex:row];
        NSMutableArray *otherCities = [NSMutableArray arrayWithArray:cities];
        [otherCities removeObjectAtIndex:row];
        
        MECity *newCity = [cityEditor editCity:[cityToEdit copy]
								   otherCities:otherCities
							   withPrefsWindow:prefsWindow];
    
        if(newCity)
        {
            if(cityToEdit == mainCity)
                mainCity = nil;
        
            [cities replaceObjectAtIndex:row withObject:newCity];
            [cityTable reloadData];
            
            //replace city written to file
            [[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:@"cities"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self generateMenu];
        }
        
        [self resestablishTimers];
    }
} // editCity

- (IBAction)removeCity:(id)sender
{
    int row = [cityTable selectedRow];
    
    if(row != -1)
    {
        if(mainCity == [cities objectAtIndex:row])
            mainCity = nil;
    
        [cities removeObjectAtIndex:row];
		if ([cities count] < 1) {
			[editCity setEnabled:NO];
			[removeCity setEnabled:NO];
		}
        [cityTable reloadData];
        [[NSUserDefaults standardUserDefaults] setObject:[self dataForCities:cities] forKey:@"cities"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self generateMenu];
    }
} // removeCity

- (IBAction)updateMenuNow:(id)sender
{
    [self generateMenuWithNewData:NO newCities:NO newCity:(YES && ([prefsController cycleMode] & 2))];
} // updateMenuNow

- (void)swicthCityEnabling
{
    int row = [cityTable selectedRow];
    
    if(row != -1)
    {
        MECity *city = [(NSMutableArray *)[cityTable dataSource] objectAtIndex:row];
        [city setActive:![city isActive]];
    }
} // swicthCityEnabling

- (void)notePrefsChanged
{
	[self generateMenu];
	[cityTable reloadData];
    
	[self resestablishTimers];
} // notePrefsChanged

- (void)noteCityOrderChanged
{
	mainCity = nil;
	[self notePrefsChanged];
} // noteCityOrderChanged

- (void)resestablishTimers
{
	//set up timers and such
	[dataTimer invalidate];
	[cityTimer invalidate];
	[citiesTimer invalidate];
    
	dataTimer = nil;
	cityTimer = nil;
	citiesTimer = nil;
    
	int minTillUpdate = 15;
	int mode = [prefsController cycleMode];
    
	if(mode & 1)
	{
		minTillUpdate = [prefsController autoUpdateTime];
		dataTimer = [NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
													 target:self
												   selector:@selector(newDataTimerFired) 
												   userInfo:nil 
													repeats:NO];
        [dataTimer setTolerance:2*60];
	}
	if(mode & 2)
	{
		minTillUpdate = [prefsController cycleUpdateTime];
		cityTimer = [NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
													 target:self
												   selector:@selector(newCityTimerFired) 
												   userInfo:nil 
													repeats:NO];
        [cityTimer setTolerance:2*60];
	}
	if(mode & 4)
	{
		minTillUpdate = [prefsController changeUpdateTime];
		citiesTimer = [NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
													   target:self
													 selector:@selector(newCitiesTimerFired) 
													 userInfo:nil 
													  repeats:NO];
        [citiesTimer setTolerance:2*60];
	}
} // resestablishTimers

- (void)newDataTimerFired
{
#ifdef DEBUG
	NSLog(@"ME: New Data Timer Fired (downloading new data)");
#endif
	[dataTimer invalidate];
	dataTimer = nil;

	[self generateMenuWithNewData];
    
	if([prefsController cycleMode] & 1) // & 1 ???
	{
		int minTillUpdate = [prefsController autoUpdateTime];
		dataTimer = [NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
													 target:self
												   selector:@selector(newDataTimerFired) 
												   userInfo:nil 
													repeats:NO];
        [dataTimer setTolerance:2*60];
	}
} // newDataTimerFired

- (void)newCityTimerFired
{
#ifdef DEBUG
	NSLog(@"ME: New City Timer Fired (selecting new main city)");
#endif
	[cityTimer invalidate];
	cityTimer = nil;

	[self generateMenuWithNewData:NO newCities:NO newCity:YES];
    
	if([prefsController cycleMode] & 2) // & 2 ??
	{
		int minTillUpdate = [prefsController cycleUpdateTime];
		cityTimer = [NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
													 target:self
												   selector:@selector(newCityTimerFired) 
												   userInfo:nil 
													repeats:NO];
        [cityTimer setTolerance:2*60];
	}
} // newCityTimerFired

- (void)newCitiesTimerFired
{
	#ifdef DEBUG
	NSLog(@"ME: New Cities Timer Fired (Changing active locations)");
	#endif
	[citiesTimer invalidate];
	citiesTimer = nil;

	[self generateMenuWithNewData:NO newCities:YES newCity:NO];
    
	if([prefsController cycleMode] & 4)
	{
		int minTillUpdate = [prefsController changeUpdateTime];
		citiesTimer = [NSTimer scheduledTimerWithTimeInterval:minTillUpdate*60
													   target:self
													 selector:@selector(newCitiesTimerFired) 
													 userInfo:nil 
													  repeats:NO];
        [citiesTimer setTolerance:2*60];
	}
} // newCitiesTimerFired

- (void)generateMenu
{
	[self generateMenuWithNewData:NO newCities:NO newCity:NO];
} // generateMenu

- (void)generateMenuWithNewData
{
	//NSLog(@"generateMenuWithNewData");
	[self generateMenuWithNewData:YES newCities:NO newCity:NO];
} // generateMenuWithNewData

- (void)generateMenuWithNewData:(BOOL)newData
					  newCities:(BOOL)newCities
						newCity:(BOOL)newCity
{
	if([cityTable doubleAction] != NULL)
	{
		if(isInMenubar)
			[self startLoadingInMenuBar];
            
		[NSThread detachNewThreadSelector:@selector(threadedGenerateMenu:)
								 toTarget:self
							   withObject:[NSNumber numberWithInt:newData*1 + newCity*2 + newCities*4]]; // are we drawing with 2 threads at the same time?
		//[self threadedGenerateMenu:[NSNumber numberWithInt:newData*1 + newCity*2 + newCities*4]];
	}
} // generateMenuWithNewData

- (void)pickNewCities:(BOOL *)newCities
		 ActiveCities:(int *)activeCities
{
	// JRC - this functionality seems like a waste.
	if(*newCities)
	{
		NSEnumerator *cityEnum = [cities objectEnumerator];
		MECity *city;
		BOOL lastWasActive = NO;
		int cityCount = 0;
		
		while(city = [cityEnum nextObject])
		{
			if([city isActive])
			{
				cityCount++;
			}
		}
		
		*activeCities = cityCount;
		
		cityEnum = [cities objectEnumerator];
		while(city = [cityEnum nextObject])
		{
			BOOL active = [city isActive];
            
			if(lastWasActive && !active)
			{
				[city setActive:YES];
				cityCount--;
				lastWasActive = YES;
			}
			else
			{
				lastWasActive = active;
			}
			
			if(active)
				[city setActive:NO];
		}
        
		if(*activeCities == cityCount)
		{
			//no new one were found
			cityEnum = [cities objectEnumerator];
			while((city = [cityEnum nextObject]) && cityCount>0)
			{
				[city setActive:YES];
				cityCount--;
			}
		}
        
		*activeCities = *activeCities - cityCount;
		
		[cityTable reloadData];
	}
	else
	{
		NSEnumerator *cityEnum = [cities objectEnumerator];
		MECity *city;
        
		while(city = [cityEnum nextObject])
		{
			if([city isActive]) // crash???
			{
                (*activeCities)++;
			}
		}
	}
} // pickNewCities

- (void)setCityImage:(NSImage **)theCityImage
 		activeCities:(int *)activeCities
			 newData:(BOOL *)newData
		  linkString:(NSString**)linkString
		 statusTitle:(NSString**)statusTitle
{
	if(*activeCities == 0)
	{
		[[menu addItemWithTitle:NSLocalizedString(@"No Active Cities",@"") 
						 action:@selector(dummy) 
				  keyEquivalent:@""] setTarget:self];
		
		if(isInMenubar)
		{
#if 0
			*statusTitle = nil;
			
			if([prefsController displayCityName])
				*statusTitle = NSLocalizedString(@"No Weather",@"");
			else
				*statusTitle = @"";
#endif
			
			// getting the TIFFRepresentation means we get a copy of the bitmap, so menubar image won't reference same image as dock _RAM
			*theCityImage = [[NSImage alloc] initWithData: [[NSApp applicationIconImage] TIFFRepresentation]];
			[*theCityImage setScalesWhenResized:YES];
			[*theCityImage setSize:NSMakeSize(16,16)];
		}
		
		if(isInDock)
		{
			NSImage *theCityImage = [NSImage imageNamed:@"meteo"];
			[NSApp setApplicationIconImage:theCityImage];
		}
    }
    else // activeCities > 0
    {
		MECity *city = mainCity;
		NSMenuItem *theCityItem;
		
		NSString *weatherFor = NSLocalizedString(@"Weather For",@"Will be used as \"Weather for <city name>\"");
        
		theCityItem = (NSMenuItem *)[menu addItemWithTitle:[NSString stringWithFormat:@"%@ %@",weatherFor,[city cityName]] 
													action:@selector(dummy) 
											 keyEquivalent:@""];
		[theCityItem setTarget:self];
		[self addDataToMenu:menu forCity:&city newData:newData]; // crashes here.
		
		*linkString = [[city weatherReport] stringForKey:@"Weather Link"
                                                  units:@"None"
                                                  prefs:prefsController
					                  displayingDegrees:![prefsController hideCF]
												modules:[MEWeather moduleNamesSupportingProperty:@"Weather Link"]];
		
		if(*linkString)
		{
			[theCityItem setTarget:*linkString];
			[theCityItem setAction:@selector(openLink:)];
		}
        
		if(isInMenubar)
		{
			*statusTitle = @"";
			
			if([prefsController displayCityName])
				*statusTitle = [city cityName];
			
			if([prefsController displayTemp])
			{
				NSDictionary *tempDict = [city dictionaryForProperty:@"Temperature"];
				
				NSString *temp = [[city weatherReport] stringForKey:@"Temperature"
															  units:[tempDict objectForKey:@"unit"]
															  prefs:prefsController
												  displayingDegrees:![prefsController hideCF]
															modules:[tempDict objectForKey:@"servers"]];
				
				temp = NSLocalizedString(temp,@"");
				
				if(temp)
				{
					if(*statusTitle)
						*statusTitle = [NSString stringWithFormat:@"%@ %@",*statusTitle,temp];
					else
						*statusTitle = temp;
				}
			}
			
			if([prefsController showHumidity])
			{
				NSDictionary *hDict = [city dictionaryForProperty:@"Humidity"];
				
				NSString *humidity = [[city weatherReport] stringForKey:@"Humidity"
															  units:[hDict objectForKey:@"unit"]
															  prefs:prefsController
												  displayingDegrees:NO
															modules:[hDict objectForKey:@"servers"]];
				
				humidity = NSLocalizedString(humidity,@"");
				
				if(humidity)
				{
					if(*statusTitle)
						*statusTitle = [NSString stringWithFormat:@"%@%@%@",*statusTitle,
										([prefsController displayTemp] == YES ? @"/" : @""), humidity];
					else
						*statusTitle = humidity;
				}
			}

			
			if([prefsController displayMenuIcon])
			{
				// JRC - here is where the menu icon is determined
				*theCityImage = [[city weatherReport] imageForKey:@"Weather Image"
															 size:16
														  modules:[MEWeather moduleNamesSupportingProperty:@"Weather Image"]
														   inDock:NO];
			}
			else
				*theCityImage = nil;
			
			//            if(([prefsController displayCityName] && [[statusItem attributedTitle] length] == 0) || 
			//			   ([prefsController displayMenuIcon] && [statusItem image] == nil) || 
			//			   ([prefsController displayTemp] && [[statusItem attributedTitle] length] == 0))
			//            {
			//                theCityImage = [NSApp applicationIconImage];
			//                [theCityImage setScalesWhenResized:YES];
			//                [theCityImage setSize:NSMakeSize(16,16)];
			//            }
		}
        
		if(isInDock)
		{
			[self updateDock];
		}
	}
} // setCityImage

- (void)addSecondaryCitiesToMenu:(NSString**)linkString
						 newData:(BOOL *)newData
{
	[menu addItem:[NSMenuItem separatorItem]];// JRC - was addItemWithTitle:@"" action:nil keyEquivalent:@""];
    
	NSArray *activeCities = [self activeCities];
	NSEnumerator *cityEnum = [activeCities objectEnumerator];
	MECity *city;
	
	while(city = [cityEnum nextObject])
	{
		if(city == mainCity)
			continue;
		
		NSDictionary *tempDict = [city dictionaryForProperty:@"Temperature"];
		
		NSString *temp = [[city weatherReport] stringForKey:@"Temperature"
													  units:[tempDict objectForKey:@"unit"]
													  prefs:prefsController
										  displayingDegrees:![prefsController hideCF]
													modules:[tempDict objectForKey:@"servers"]];
		
		temp = NSLocalizedString(temp,@"");
		
		if(temp)
			temp = [NSString stringWithFormat:@"%@ %@",[city cityName],temp];
		else
			temp = [city cityName];
		
		NSMenuItem *theCityItem;
		theCityItem = (NSMenuItem *)[menu addItemWithTitle:temp
													action:nil
											 keyEquivalent:@""];
		
		NSMenu *subMenu = [[NSMenu alloc] init]; // submenu for the city
		[theCityItem setSubmenu:subMenu]; // Cityname --> subMenu

		*linkString = [[city weatherReport]
					  stringForKey:@"Weather Link"
					  units:@"None"
					  prefs:prefsController
					  displayingDegrees:![prefsController hideCF]
					  modules:[MEWeather moduleNamesSupportingProperty:@"Weather Link"]
					  ];

		if (*linkString)
		{
			[theCityItem setTarget:*linkString];
			[theCityItem setAction:@selector(openLink:)];
		}

		NSImage *cityWeatherImage = [[city weatherReport] imageForKey:@"Weather Image"
																 size:16
															  modules:[MEWeather moduleNamesSupportingProperty:@"Weather Image"]
															   inDock:NO];
		[theCityItem setImage:cityWeatherImage]; // retain might not be necessary
		
		[self addDataToMenu:subMenu forCity:&city newData:newData];

	}
} // addSecondaryCitiesToMenu

- (void)addMainMenuControls
{
	NSMenu *submenu = menu;
	
    // now add all the stuff you always add
	[menu addItem:[NSMenuItem separatorItem]];
	
	if([prefsController embedControls]) // Controls in submenu?
	{
		NSMenuItem *controlMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Controls",@"Controls MenuItem") 
                                                      action:nil 
                                               keyEquivalent:@""];
		submenu = [[NSMenu alloc] init];
		[controlMenuItem setSubmenu:submenu];
	}
    
	NSMenu *citySwitcherMenu;
    
	refreshMI = (NSMenuItem *)[submenu addItemWithTitle:NSLocalizedString(@"Refresh",@"") 
												 action:@selector(refreshCallback:) 
										  keyEquivalent:@""];
	[refreshMI setTarget:self];
	[refreshMI performSelectorOnMainThread:@selector(setEnabled:) withObject:nil waitUntilDone:YES];
	showCityEditorMI = (NSMenuItem *)[submenu addItemWithTitle:NSLocalizedString(@"Show City Editor",@"Show City Editor MenuItem") 
														action:@selector(showCityController:) 
												 keyEquivalent:@""];
	[showCityEditorMI setTarget:self];
    
	citySwitcherMI = (NSMenuItem*)[submenu addItemWithTitle:NSLocalizedString(@"City Switcher",@"City Switcher MenuItem")
													 action:@selector(showCityController:) 
											  keyEquivalent:@""];
	citySwitcherMenu = [[NSMenu alloc] init];
	[citySwitcherMI setSubmenu:citySwitcherMenu];
    
	NSEnumerator *cityEnum = [cities objectEnumerator];
	MECity *nextCity;
    
	while(nextCity = [cityEnum nextObject])
	{
		NSMenuItem *nextCityItem = [citySwitcherMenu addItemWithTitle:[nextCity cityName] action:nil keyEquivalent:@""];
		if([nextCity isActive])
			[nextCityItem setState:NSOnState];
		
		[nextCityItem setTarget:nextCity];
		[nextCityItem setAction:@selector(toggleActivity)];
	}
    
    
	preferencesMI = (NSMenuItem *)[submenu addItemWithTitle:NSLocalizedString(@"Preferences",@"") 
													 action:@selector(showPrefsController:) 
											  keyEquivalent:@""];
	[preferencesMI setTarget:self];
	
	quitMI = (NSMenuItem *)[submenu addItemWithTitle:NSLocalizedString(@"Quit",@"") 
											  action:@selector(terminate:) 
									   keyEquivalent:@""];
	[quitMI setTarget:NSApp];
} // addMainMenuControls

- (void)threadedGenerateMenu:(NSNumber *)num
{
	@autoreleasepool { // make an autorelease pool for this thread
		[menuDrawLock lock]; // make sure that only one thread is drawing at a time

		[prefsController performSelectorOnMainThread:@selector(deactivateInterface) withObject:NULL waitUntilDone:YES];
		[addCity performSelectorOnMainThread:@selector(setEnabled:) withObject:NULL waitUntilDone:YES];
		[updateMenu performSelectorOnMainThread:@selector(setEnabled:) withObject:NULL waitUntilDone:YES];
    
		[cityTable setDoubleAction:NULL];

		menu = [[NSMenu alloc] init];

		NSString *statusTitle = nil;
		NSImage *theCityImage = nil;

		BOOL newData   = ([num intValue] & 1);
		BOOL newCity   = ([num intValue] & 2);
		BOOL newCities = ([num intValue] & 4);
		
		int activeCities = 0;
    
		NSString *linkString = nil;

		// pick new cities if that option is enabled.
		[self pickNewCities:&newCities ActiveCities:&activeCities];
    
		// pick a new main city if newCity was passed, mainCity is nil, or the mainCity isn't active.
		if(newCity || !mainCity || ![mainCity isActive])
		{
			NSArray *theActiveCities = [self activeCities];
			if([theActiveCities count])
			{
				if(!mainCity || ![mainCity isActive]) // there isn't a main city right now, so make the first the active city
				{
					mainCity = [theActiveCities objectAtIndex:0];
				}
				else
				{
					// choose a new main city
					int indexOfCity = [theActiveCities indexOfObject:mainCity];
                
					if(indexOfCity == [theActiveCities count]-1 || [theActiveCities count] == 1 || indexOfCity == -1)
						mainCity = [theActiveCities objectAtIndex:0];
					else
						mainCity = [theActiveCities objectAtIndex:indexOfCity + 1];
				}
			}
			else
			{
				mainCity = nil;
			}
		}
    
		// make sure non-active cities have data invalidated
		if(newData)
		{
			NSEnumerator *cityEnum = [cities objectEnumerator];
			MECity *city;
        
			while(city = [cityEnum nextObject])
			{
				if(![city isActive])
				{
					[[city weatherReport] prepareNewServerData];
				}
			}
		}
		
		NSMutableDictionary *menuAttributes = [NSMutableDictionary dictionary];
		[menuAttributes setObject:[NSFont fontWithName:[prefsController menuFontName] size:[prefsController menuFontSize]] forKey:NSFontAttributeName];
		[menuAttributes setObject:[prefsController menuColor] forKey:NSForegroundColorAttributeName];

		[self setCityImage:&theCityImage
			  activeCities:&activeCities
				   newData:&newData
				linkString:&linkString
			   statusTitle:&statusTitle];
    
		if(activeCities > 1)
		{
			[self addSecondaryCitiesToMenu:&linkString
								   newData:&newData];
		}

		// now add all the stuff you always add
		[self addMainMenuControls];
    
		if(isInMenubar)
		{
			if(([[statusItem title] isEqualToString:@""] || ![statusItem title]) && ![statusItem image])
			{
			   if([prefsController displayCityName])
				   statusTitle = NSLocalizedString(@"No Weather",@"");
			   else
				   statusTitle = @"";
             
				[statusItem setAttributedTitle:[[NSAttributedString alloc] initWithString:statusTitle attributes:menuAttributes]];
				// getting the TIFFRepresentation means we get a copy of the bitmap, so menubar image won't reference same image as dock _RAM
				theCityImage = [[NSImage alloc] initWithData: [[NSApp applicationIconImage] TIFFRepresentation]];
				[theCityImage setScalesWhenResized:YES];
				[theCityImage setSize:NSMakeSize(16,16)];
			}
    
			[cityTable reloadData];

			[self performSelectorOnMainThread:@selector(stopLoadingInMenuBar) withObject:NULL waitUntilDone:YES];

			// I still can't figure out all the stuff that happened up until here in this method,
			// but I know that if displayMenuIcon is YES and theCityImage is still nil at this point,
			// this is our last chance to come up with an image. _RAM
			if ([prefsController displayMenuIcon] && theCityImage == nil)
			{
				// getting the TIFFRepresentation means we get a copy of the bitmap, so menubar image won't reference same image as dock _RAM
				theCityImage = [[NSImage alloc] initWithData: [[NSApp applicationIconImage] TIFFRepresentation]];
				[theCityImage setScalesWhenResized:YES];
				[theCityImage setSize:NSMakeSize(16,16)];
			}

			// likewise, if there is no statusTitle by now, let's make sure there's something to show _RAM
			if ((statusTitle == nil || [statusTitle isEqualToString: @""]))
			{
				// actually, text is required only if we're not to show an icon 
				if (! [prefsController displayMenuIcon])
				{
					statusTitle = @"Meteo";
				}
			}
			
			[statusItem performSelectorOnMainThread:@selector(setAttributedTitle:) withObject:[[NSAttributedString alloc] initWithString:statusTitle attributes:menuAttributes] waitUntilDone:YES];
			[statusItem performSelectorOnMainThread:@selector(setImage:) withObject:theCityImage waitUntilDone:YES];
			[statusItem performSelectorOnMainThread:@selector(setMenu:) withObject:menu waitUntilDone:YES];
		}

		[prefsController performSelectorOnMainThread:@selector(activateInterface) withObject:NULL waitUntilDone:YES];
		[addCity performSelectorOnMainThread:@selector(setEnabled:) withObject:addCity waitUntilDone:YES];
		[updateMenu performSelectorOnMainThread:@selector(setEnabled:) withObject:updateMenu waitUntilDone:YES];
    
		// JRC
		[refreshMI performSelectorOnMainThread:@selector(setEnabled:) withObject:refreshMI waitUntilDone:YES];
		[cityTable setDoubleAction:@selector(editCity:)];
		
		
		// cleanup
		[menuDrawLock unlock];
	}
	[NSThread exit];
} // threadedGenerateMenu

- (void)addString:(NSString *)string toMenu:(NSMenu *)theMenu withCharacterWidth:(int)width withLink:(NSString *)linkString
{
    NSArray *components = [string componentsSeparatedByString:@" "];
    NSEnumerator *compEnum = [components objectEnumerator];
    
    NSString *subStr = nil;
    NSString *spaceStr = nil;
    NSString *sub;
    int count = -1;
    
    int subWidth = width;
    
    while(sub = [compEnum nextObject])
    {
        count+=[sub length]+1;
        
        if(count < subWidth)
        {
            if(!subStr)
                subStr = sub;
            else
                subStr = [NSString stringWithFormat:@"%@ %@",subStr,sub];
        }
        else
        {
            if(spaceStr)
                subStr = [NSString stringWithFormat:@"%@%@",spaceStr,subStr];
        
            if(subStr)
                [[theMenu addItemWithTitle:subStr action:@selector(dummy) keyEquivalent:@""] setTarget:self];
            
            if(!spaceStr)
            {
                float numWidth = [[components objectAtIndex:0] sizeWithAttributes:nil].width;
                
                spaceStr = @" ";
                while([spaceStr sizeWithAttributes:nil].width < numWidth)
                {
                    spaceStr = [NSString stringWithFormat:@"%@ ",spaceStr];
                    subWidth--;
                }
                
                subWidth-=2;
            }
            
            subStr = sub;
            count = [sub length];
        }
    }
    
    if(subStr)
    {
        if(spaceStr)
                subStr = [NSString stringWithFormat:@"%@%@",spaceStr,subStr];
    
		NSMenuItem *menuItem = [theMenu addItemWithTitle:subStr action:@selector(dummy) keyEquivalent:@""];
        [menuItem setTarget:self];
		if((linkString) && ([linkString length] > 0))
		{
			[menuItem setTarget:linkString];
			[menuItem setAction:@selector(openLink:)];
		}
    }
} // addString


- (void)addCurrentWeatherDataToMenu:(NSMenu *)theMenu
					 forWeatherInfo:(NSArray *)array
							 report:(MEWeather *)report
							newData:(BOOL)newData
							   city:(MECity *)city
{
    NSEnumerator *itemEnum = [array objectEnumerator];
    NSDictionary *nextObj;
	
    while(nextObj = [itemEnum nextObject])
    {
        //we have a nest!
        if(![nextObj objectForKey:@"enabled"])
        {
            NSMenu *nextMenu = [[NSMenu alloc] init];
            NSMenuItem *nextItem = [theMenu addItemWithTitle:[nextObj objectForKey:@"property"] action:NULL keyEquivalent:@""];
            [nextItem setSubmenu:nextMenu];
            
            [self addCurrentWeatherDataToMenu:nextMenu forWeatherInfo:[nextObj objectForKey:@"subarray"] report:report newData:newData city:city];
        }
        //just an individual
        else
        {
            if(![[nextObj objectForKey:@"enabled"] boolValue])
                continue;
            
            NSString *nextProp = [nextObj objectForKey:@"property"];
            
            id nextVal;
            
            if([nextProp isEqualToString:@"Weather Alert"])
            {
                nextVal = [report objectForKey:nextProp modules:[nextObj objectForKey:@"servers"]];
                
                if(nextVal)
                    [alertManager performSelectorOnMainThread:@selector(addCity:) withObject:[NSArray arrayWithObjects:city,nextVal,prefsController,nil] waitUntilDone:YES];
                else
                    [alertManager performSelectorOnMainThread:@selector(removeCity:) withObject:city waitUntilDone:YES];
            }
            else
                nextVal = [report stringForKey:nextProp
                                  units:[nextObj objectForKey:@"unit"]
                                  prefs:prefsController
                                  displayingDegrees:![prefsController hideCF]
                                  modules:[nextObj objectForKey:@"servers"]];
    
            if(nextVal!=nil && nextProp!=nil)
            {
                if([nextProp isEqualToString:@"Weather Alert"])
                {
                    //nextVal is an array of dictionaries with @"title", @"description" and @"link" as keys
                    NSMenuItem *nextItem = [theMenu addItemWithTitle:NSLocalizedString(nextProp,nil) action:nil keyEquivalent:@""];
                    NSMenu *anotherSub = [[NSMenu alloc] init];
                    
                    [nextItem setSubmenu:anotherSub];
                    
                    NSEnumerator *arrayEnum = [nextVal objectEnumerator];
                    NSDictionary *nextDict;
                    
                    int i = 0;
                    
                    while(nextDict = [arrayEnum nextObject])
                    {
                        NSString *dictTitle = [nextDict objectForKey:@"title"];
                        NSString *dictDesc = [nextDict objectForKey:@"description"];
                        NSString *dictLink = [nextDict objectForKey:@"link"];
                    
                        if((dictDesc!=nil || dictTitle!=nil) && i!=0)
                            [self addString:@"" toMenu:anotherSub withCharacterWidth:75 withLink:dictLink];
                    
                        //if(dictTitle)
                        //    [self addString:dictTitle toMenu:anotherSub withCharacterWidth:75 withLink:dictLink];
                        if(dictDesc)
                            [self addString:dictDesc toMenu:anotherSub withCharacterWidth:75 withLink:dictLink];
                            
                        i++;
                    }
                }
                else if([nextProp isEqualToString:@"Radar Image"])
                {
					NSData *dat = [[NSURL URLWithString:[nextVal stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
								   resourceDataUsingCache:!newData];
                    if(dat)
                    {
                        NSImage *sourceImage = [[NSImage alloc] initWithData:dat];
						NSRect screenBounds = [[NSScreen mainScreen] visibleFrame];
						NSSize newSize = [sourceImage size];
						NSSize originalSize = [sourceImage size];
						
						if (radarImageWidth == 0)
						{
							radarImageWidth = screenBounds.size.width/2;

							if([[MEPrefs sharedInstance] logMessagesToConsole])
							{
								NSLog(@"Screen size (%.0f, %.0f)", screenBounds.size.width, screenBounds.size.height);
								NSLog(@"Original image size (%.0f, %.0f)", originalSize.width, originalSize.height);
							}
							if (radarImageWidth > screenBounds.size.width/3)
							{
								radarImageWidth = screenBounds.size.width/3;
							}
						}
						
						if ((radarImageWidth) < originalSize.width)
						{
							newSize = NSMakeSize(radarImageWidth, (int)((radarImageWidth)/originalSize.width*originalSize.height));
						}
                        
						
                        if(sourceImage)
                        {
							// http://weblog.scifihifi.com/2005/06/25/how-to-resize-an-nsimage/
							NSImage *resizedImage = [[NSImage alloc] initWithSize:newSize];
							
							[resizedImage lockFocus];
							[sourceImage drawInRect: NSMakeRect(0, 0, newSize.width, newSize.height)
										   fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height)
										  operation: NSCompositeSourceOver fraction: 1.0];
							[resizedImage unlockFocus];
							
							//NSData *resizedData = [resizedImage TIFFRepresentation];
							
							nextProp = NSLocalizedString(nextProp,@"");
                        
                            NSMenuItem *nextItem = [theMenu addItemWithTitle:NSLocalizedString(nextProp,nil) action:nil keyEquivalent:@""];
                            NSMenu *anotherSub = [[NSMenu alloc] init];
                            
                            [nextItem setSubmenu:anotherSub];
                            nextItem = (NSMenuItem *)[anotherSub addItemWithTitle:@"" action:nil keyEquivalent:@""];
                            [nextItem setImage:resizedImage];
                            [nextItem setTarget:self];
                            [nextItem setAction:@selector(dummy)];
							[nextItem setTarget:nextVal];
							[nextItem setAction:@selector(openLink:)];
                        }
                    }
                }
                else
                {
					//int numSpaces = 13;
                    nextProp = NSLocalizedString(nextProp,@"");
//					nextProp = [@"\t" stringByAppendingString:nextProp];
                    nextVal = NSLocalizedString(nextVal,@"");
//					nextVal = [@"\t" stringByAppendingString:nextVal];

//					NSString *spaces = [NSString stringWithString:@" "];
//					spaces = [spaces stringByPaddingToLength:(numSpaces - [nextProp length]) withString:@" " startingAtIndex:0];
//					NSMutableAttributedString *attrNextProp = [[[NSMutableAttributedString alloc] initWithString:nextProp] autorelease];
//					NSMutableParagraphStyle *NPStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
//					[NPStyle addTabStop:[[[NSTextTab alloc] initWithType:NSRightTabStopType location:80] autorelease]];

//					[attrNextProp addAttribute:@"NSParagraphStyle" value:NPStyle range:NSMakeRange(0,[nextProp length])];

  //                  NSMutableAttributedString *nextTitle = attrNextProp;
					//[nextTitle
					NSString *nextTitle = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(nextProp,nil),nextVal];
                    [self addString:nextTitle toMenu:theMenu withCharacterWidth:75 withLink:nil];
                }
            }

        }
    }
} // addCurrentWeatherDataToMenu

/* called-by: threadedGenerateMenu:

*/
- (void)addDataToMenu:(NSMenu *)theMenu
			  forCity:(MECity **)city
			  newData:(BOOL *)newData
{
	NSMenu *tempMenu = theMenu;
	NSString *linkString = nil;


	if(*newData)
		[[*city weatherReport] prepareNewServerData];

        
	NSArray *weatherArray = [*city weatherAttributes];
	NSArray *forecastArray = [*city forecastAttributes];
	MEWeather *report = [*city weatherReport];
    
	[report newForecastEnumeratorForMods:[MEWeather moduleNames]];
    
	if([prefsController displayTodayInSubmenu])
	{
		NSMenuItem *item = [theMenu addItemWithTitle:NSLocalizedString(@"Current Conditions",@"") action:nil keyEquivalent:@""];
		NSMenu *subMenu = [[NSMenu alloc] init];
		[item setSubmenu:subMenu];
        
		tempMenu = subMenu;
	}
    
	[self addCurrentWeatherDataToMenu:tempMenu forWeatherInfo:weatherArray report:report newData:*newData city:*city];
        
	if([prefsController forecastDaysOn])
	{
		tempMenu = theMenu;
            
		if([prefsController viewForecastInSubmenu])
		{
			NSString *extFor = NSLocalizedString(@"Extended Forecast",@"");
        
			NSMenuItem *item = [theMenu addItemWithTitle:extFor action:nil keyEquivalent:@""];
			NSMenu *subMenu = [[NSMenu alloc] init];
			[item setSubmenu:subMenu];
            
			tempMenu = subMenu;
		}
		else if(![prefsController displayTodayInSubmenu])
		{
			[tempMenu addItem:[NSMenuItem separatorItem]];
		}
        
		int i = 0;
        
		while(i < [prefsController forecastDaysNumber])
		{
			NSDictionary *forcDict = [*city dictionaryForProperty:@"Forecast - Date"];
            
			NSString *date = [report forecastStringForKey:@"Forecast - Date" 
                                            units:[forcDict objectForKey:@"Forecast - Date"]
                                            prefs:prefsController
                                            displayingDegrees:NO
                                            modules:[forcDict objectForKey:@"servers"]];
			//NSString *date = [report forecastStringForKey:@"Forecast - Date" newDay:NO];
			
			NSString *dayName = [report forecastStringForKey:@"Forecast - Day" newDay:NO];
			
			NSString *menuItemTitle = [NSString stringWithFormat:@"%@, %@",dayName,date];
			
			if([dayName hasSuffix:@"ight"])
				i--;
        
			NSMenu *attempt = [[NSMenu alloc] init];
            
			NSEnumerator *objEnum = [forecastArray objectEnumerator];
			NSDictionary *nextObj;
            
			NSMutableArray *properties = [NSMutableArray array];
			NSMutableArray *values = [NSMutableArray array];
            
			while(nextObj = [objEnum nextObject])
			{
				if(![[nextObj objectForKey:@"enabled"] boolValue])
					continue;
            
				NSString *res = nil;
            
				if([[nextObj objectForKey:@"property"] isEqualToString:@"Forecast - Date"]) // JRC
					res = date;
				else
					res = [report forecastStringForKey:[nextObj objectForKey:@"property"] 
                                        units:[nextObj objectForKey:@"unit"]
                                        prefs:prefsController
                                        displayingDegrees:![prefsController hideCF]
                                        modules:[nextObj objectForKey:@"servers"]];
				NSString *property = [[nextObj objectForKey:@"property"] substringFromIndex:11];

				if(res && property)
				{
					[properties addObject:property];
					[values addObject:res];
				}
			}
                                            
			if([properties count] && menuItemTitle)
			{
				menuItemTitle = NSLocalizedString(menuItemTitle,@"");
                
				NSEnumerator *propEnum = [properties objectEnumerator];
				NSEnumerator *valueEnum = [values objectEnumerator];
				NSString *nextProp, *nextVal;
                
				if(![prefsController forecastInline])
				{
					while((nextProp = [propEnum nextObject]) && (nextVal = [valueEnum nextObject]))
					{
						nextProp = NSLocalizedString(nextProp,@"");
						nextVal = NSLocalizedString(nextVal,@"");
                    
						NSString *nextTitle;
                        
						if([nextProp isEqualToString:@""])
							nextTitle = nextVal;
						else
							nextTitle = [NSString stringWithFormat:@"%@: %@",nextProp,nextVal];
						[self addString:nextTitle toMenu:attempt withCharacterWidth:75 withLink:nil];
					}
                        
					NSMenuItem *linker = [tempMenu addItemWithTitle:@"Some Title" action:nil keyEquivalent:@""];
                    
					[linker setSubmenu:attempt];
                    
					[linker setTitle:menuItemTitle];
                    
					linkString = [report forecastStringForKey:@"Forecast - Link"
														units:@"None"
														prefs:prefsController
											displayingDegrees:![prefsController hideCF]
													  modules:[MEWeather moduleNamesSupportingProperty:@"Forecast - Link"]];
					
					if(linkString)
					{
						[linker setTarget:linkString];
						[linker setAction:@selector(openLink:)];
					}
                    
					if([prefsController displayDayImage])
					{
						[linker setImage:[report forecastImageForKey:@"Forecast - Icon"
																size:16
															 modules:[MEWeather moduleNamesSupportingProperty:@"Forecast - Icon"]
															  inDock:NO]];
					}
				}
				else
				{
					NSMenuItem *daItem = [tempMenu addItemWithTitle:@"Some Title" action:nil keyEquivalent:@""];
                    
					linkString = [report forecastStringForKey:@"Forecast - Link"
														units:@"None"
														prefs:prefsController
											displayingDegrees:![prefsController hideCF]
													  modules:[MEWeather moduleNamesSupportingProperty:@"Forecast - Link"]];
					
					if(linkString)
					{
						[daItem setTarget:linkString];
						[daItem setAction:@selector(openLink:)];
					}
					else
					{
						[daItem setTarget:self];
						[daItem setAction:@selector(dummy)];
					}
                    
					NSString *totalTitle = [NSString stringWithFormat:@"%@  ",menuItemTitle];
					NSString *hiTitle = [NSString stringWithFormat:@"%@\t\t\t",@""];
                    NSString *forecastTitle = @"";
                                        
					while((nextProp = [propEnum nextObject]) && (nextVal = [valueEnum nextObject]))
					{
                        if ([nextProp isEqualToString:NSLocalizedString(@"Forecast",@"")])
                        {
                            // Save forecast words at end for better alignment
                            nextProp = NSLocalizedString(nextProp,@"");
                            nextVal = NSLocalizedString(nextVal,@"");
                            forecastTitle = [NSString stringWithFormat:@"%@: %@",nextProp,nextVal];
                        }
                        else
                        {
                            nextProp = [MEWeather shortNameForKey:nextProp];
                            
                            nextProp = NSLocalizedString(nextProp,@"");
                            nextVal = NSLocalizedString(nextVal,@"");

                            if ([nextProp isEqualToString:NSLocalizedString(@"High",@"")])
                            {
                                // If we have "High", then null out padding
                                hiTitle = [NSString stringWithFormat:@"%@",@""];
                            }
                            if ([nextProp isEqualToString:NSLocalizedString(@"Low",@"")])
                            {
                                nextProp = [NSString stringWithFormat:@"%@%@",hiTitle, nextProp];
                            }
                            
                            NSString *nextTitle;
                            
                            if (![nextProp isEqualToString:NSLocalizedString(@"Date",@"")])
                            {
                                if([nextProp isEqualToString:@""])
                                {
                                    nextTitle = [NSString stringWithFormat:@"%@\t",nextVal];
                                }
                                else
                                {
                                    if ([nextVal length] < 3)
                                    {
                                        nextTitle = [NSString stringWithFormat:@"%@: %@  ",nextProp,nextVal];
                                    }
                                    else
                                    {
                                        nextTitle = [NSString stringWithFormat:@"%@: %@",nextProp,nextVal];
                                    }
                                }
                                
                                totalTitle = [NSString stringWithFormat:@"%@  \t%@",totalTitle,nextTitle];
                            }
                        }
					}
                    totalTitle = [NSString stringWithFormat:@"%@  \t%@",totalTitle,forecastTitle];
                    
					[daItem setTitle:totalTitle];
                    
					if([prefsController displayDayImage])
						[daItem setImage:[report forecastImageForKey:@"Forecast - Icon"
																size:16
															 modules:[MEWeather moduleNamesSupportingProperty:@"Forecast - Icon"]
															  inDock:NO]];
				}
			}
            
			i++;
		}
	}
} // addDataToMenu

- (void)dummy
{
} // dummy

- (NSArray *)activeCities
{
    NSMutableArray *activeCities = [NSMutableArray array];
    
    NSEnumerator *cityEnum = [cities objectEnumerator];
    MECity *nextCity;
    
    while(nextCity = [cityEnum nextObject])
        if([nextCity isActive])
            [activeCities addObject:nextCity];
            
    return activeCities;
} // activeCities

- (NSMutableArray *)citiesForData:(NSMutableArray *)dataArray
{
    NSMutableArray *cityArray = [[NSMutableArray alloc] init];
    
    NSEnumerator *dataEnum = [dataArray objectEnumerator];
    NSData *data;
    
    Class unarchiver;
    
    if([self respondsToSelector:@selector(performSelectorOnMainThread:withObject:waitUntilDone:)])
        unarchiver = [NSKeyedUnarchiver class];
    else
        unarchiver = [NSUnarchiver class];
    
    while(data = [dataEnum nextObject])
        [cityArray addObject:[unarchiver unarchiveObjectWithData:data]];
        
	/* for backwards compatibility */
    return cityArray;
} // citiesForData

- (NSMutableArray *)dataForCities:(NSMutableArray *)cityArray
{
    NSMutableArray *dataArray = [NSMutableArray array];
    
    NSEnumerator *cityEnum = [cityArray objectEnumerator];
    MECity *nextCity;
    
    Class archiver;
    
    if([self respondsToSelector:@selector(performSelectorOnMainThread:withObject:waitUntilDone:)])
        archiver = [NSKeyedArchiver class];
    else
        archiver = [NSArchiver class];
    
    while(nextCity = [cityEnum nextObject])
        [dataArray addObject:[archiver archivedDataWithRootObject:nextCity]];
        
    return dataArray;
} // dataForCities

NSFont* fontWithMaxHeight(NSString *name, int maxHeight)
{
	int i = 1;
	NSFont *font = [NSFont fontWithName:name size:1];
    
	while([font ascender] - [font descender] < maxHeight)
	{
		i++;
		font = [NSFont fontWithName:name size:i];
	}
    
	return [NSFont fontWithName:name size:i-1];
} // fontWithMaxHeight

// called by the Refresh MenuItem and the Update Now button
- (IBAction)refreshCallback:(id)sender
{
	#ifdef DEBUG
	NSLog(@"ME: Refresh Callback");
	#endif
	[updateMenu setEnabled:NO];
	if (refreshMI)
		[refreshMI setEnabled:NO];
	[self stopLoadingInMenuBar]; // stops the current timer if it is "waiting."
	[self generateMenuWithNewData]; // refreshes the menubar
} // refreshCallback

- (void)startLoadingInMenuBar
{
	menuBarLoadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
														target:self
													  selector:@selector(loadNextInMenuBar)
													  userInfo:[NSNumber numberWithInt:1]
													   repeats:NO];
    [menuBarLoadTimer setTolerance:0.1];
} // startLoadingInMenuBar

- (void)stopLoadingInMenuBar
{
	if(menuBarLoadTimer!=nil && [menuBarLoadTimer isValid])
		[menuBarLoadTimer invalidate];
    
	menuBarLoadTimer = nil;
} // stopLoadingInMenuBar

- (void)loadNextInMenuBar
{
	NSNumber *num = [menuBarLoadTimer userInfo];
	NSImage *img = nil;
	NSString *imageName = [NSString stringWithFormat:@"Loading-%d",[num intValue]];
	NSString *imageFileName = [[NSBundle mainBundle] pathForResource:imageName ofType:@"tiff"];
    
	img = [[NSImage alloc] initWithContentsOfFile:imageFileName];
        
	[statusItem setImage:img];
    
	num = [NSNumber numberWithInt:([num intValue]+1)%8+1];
    
	menuBarLoadTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(loadNextInMenuBar) userInfo:num repeats:NO];
    [menuBarLoadTimer setTolerance:0.1];
} // loadNextInMenuBar

- (void)updateDock
{
    //here's what needs to go on in the dock:

    NSArray *activeCities = [self activeCities];
    MECity *city;
    NSImage *pic;
    
    if([activeCities count])
        city = [activeCities objectAtIndex:0];
    else
        city = nil;
    
    pic = [[city weatherReport] 
                 imageForKey:@"Weather Image"
                 size:128
                 modules:[MEWeather moduleNamesSupportingProperty:@"Weather Image"]
                 inDock:YES];
    if(!pic)
    {
        pic = [NSImage imageNamed:@"Unknown.tiff"];
        [pic setScalesWhenResized:YES];
        [pic setSize:NSMakeSize(128,128)];
    }
                 
    [[city weatherReport] newForecastEnumeratorForMods:[MEWeather moduleNames]];             
    NSDictionary *forecastDict = [city dictionaryForProperty:@"Date"];
    NSString *forc = [[city weatherReport] 
                            stringForKey:@"Date"
                            units:[forecastDict objectForKey:@"unit"]
                            prefs:prefsController
                            displayingDegrees:![prefsController hideCF]
                            modules:[forecastDict objectForKey:@"servers"]];
        
    NSImage *tvImage = nil;
    NSImage *moonImage = nil;
    
    if([forc hasSuffix:@"ight"])
    {
        tvImage = [[NSImage alloc] initWithContentsOfFile:@"/Library/Application Support/Meteo/Dock Icons/Television/Television-Night.tiff"];
        if(!tvImage)
            tvImage = [[NSImage alloc] initWithContentsOfFile:[@"~/Library/Application Support/Meteo/Dock Icons/Television/Television-Night.tiff" stringByExpandingTildeInPath]];
        
        moonImage = [[city weatherReport] 
                            imageForKey:@"Moon Phase"
                            size:128
                            modules:[MEWeather moduleNamesSupportingProperty:@"Moon Phase"]
                            inDock:YES];
    }
    else
    {
        tvImage = [[NSImage alloc] initWithContentsOfFile:@"/Library/Application Support/Meteo/Dock Icons/Television/Television-Day.tiff"];
        if(!tvImage)
            tvImage = [[NSImage alloc] initWithContentsOfFile:[@"~/Library/Application Support/Meteo/Dock Icons/Television/Television-Day.tiff" stringByExpandingTildeInPath]];
    }
                            

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
    NSImage *tempPic = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];

    NSDictionary *tempDict = [city dictionaryForProperty:@"Temperature"];
    NSString *temp = [[city weatherReport] 
                            stringForKey:@"Temperature"
                            units:[tempDict objectForKey:@"unit"]
                            prefs:prefsController
                            displayingDegrees:![prefsController hideCF]
                            modules:[tempDict objectForKey:@"servers"]];
                            
    if(!temp)
        temp = @"N/A";
        
    NSImage *tempBar;
    int theTemperature = [temp intValue];
    
    if(([[tempDict objectForKey:@"unit"] isEqualToString:@"Celsius"] && ![prefsController useGlobalUnits]) ||
       ([[prefsController degreeUnits] isEqualToString:@"Celsius"] && [prefsController useGlobalUnits]))
        theTemperature = (theTemperature*9/5) + 32; //convert to Fahrenheit
                                                                            
    int i = theTemperature/10;
    
    if(i > 9)
        i = 9;
    if(i < 1)
        i = 1;
        
    tempBar = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/Meteo/Dock Icons/Temperature/Temperature-%d.tiff",i]];
    if(!tempBar)
        tempBar = [[NSImage alloc] initWithContentsOfFile:[[NSString stringWithFormat:@"~/Library/Application Support/Meteo/Dock Icons/Temperature/Temperature-%d.tiff",i] stringByExpandingTildeInPath]];
                                   
    NSMutableDictionary *attr = [MEController bestAttributesForString:temp size:NSMakeSize(36,36) fontName:[prefsController tempFont]];
    
    NSSize size;
    float x,y;
    
    if([prefsController displayTemp] && temp)
    {
        size = [temp sizeWithAttributes:attr];

        x = 128 - (40 + 8) + ((36 - size.width)/2);
        y = 8 + ((36 - size.height)/2);
    
        [tempPic lockFocus];
        [attr setObject:[prefsController tempColor] forKey:NSForegroundColorAttributeName];
        [temp drawAtPoint:NSMakePoint(x,y) withAttributes:attr];
        [tempPic unlockFocus];
    }
    
    [image lockFocus];
    if(tvImage) 
        [tvImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[prefsController imageOpacity]];
    if(moonImage)
        [moonImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[prefsController imageOpacity]];
    if(pic) 
        [pic compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[prefsController imageOpacity]];
    if(tempBar)
        [tempBar compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:[prefsController imageOpacity]];
    if([prefsController displayTemp]) 
        [tempPic compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
    [image unlockFocus];
    
    [NSApp setApplicationIconImage:image];
} // updateDock

+ (NSMutableDictionary *)bestAttributesForString:(NSString *)string size:(NSSize)size fontName:(NSString *)fontName
{
    NSFont *font = [NSFont fontWithName:fontName size:1];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    NSMutableDictionary *atr = [NSMutableDictionary dictionary];
    NSSize aSize;
    int i = 1;
    
    [style setAlignment:NSCenterTextAlignment];
    [atr setObject:font forKey:NSFontAttributeName];
    [atr setObject:style forKey:NSParagraphStyleAttributeName];
    
    while(1)
    {
        aSize = [string sizeWithAttributes:atr];
        if(aSize.width>size.width || aSize.height>size.height)
        {
            i--;
            font = [NSFont fontWithName:fontName size:i];
            [atr setObject:font forKey:NSFontAttributeName];
            break;
        }
        else
        {
            i++;
            font = [NSFont fontWithName:fontName size:i];
            [atr setObject:font forKey:NSFontAttributeName];
        }
    }
    
    return atr;
} // bestAttributesForString

@end



@implementation NSString (LinkAdditions)

- (void)openLink:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self]];
} // openLink

@end
