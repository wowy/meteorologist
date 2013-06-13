//
//  MEWeather.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MEWeather.h"


@implementation MEWeatherForecastEnumerator

- (id)initWithForecastArrays:(NSMutableArray *)arrays
{
    self = [super init];
    if(self)
    {
        forecastArrays = [arrays retain];
        isFirst = YES;
        [self nextDay:NO];
    }
    return self;
}

- (void)dealloc
{
    [forecastArrays release]; /* JRC - was autorelease */
    [super dealloc];
}

- (int)compareDay:(NSString *)day withDay:(NSString *)other
{
    if(!other)
	return NSOrderedAscending;
        
    if([day isEqualToString:other])
        return NSOrderedSame;
        
    //Priority:
    // 1 - Now/Today
    // 2 - Afternoon
    // 3 - Tonight/Overnight
    // 4 - Tomorrow
    // 5 - X (Monday, Tueday, Wednesday, ...)
    // 6 - X Night (Monday Night, Tuesday Night, ...)
    
    int dayScore = -1;
    int otherScore = -1;
    
    if([day isEqualToString:@"Now"] || [day isEqualToString:@"Today"])
        dayScore = 1;
    else if([day hasSuffix:@"fternoon"])
        dayScore = 2;
    else if([day isEqualToString:@"Tonight"] || [day isEqualToString:@"Overnight"])
        dayScore = 3;
    else if([day isEqualToString:@"Tomorrow"])
        dayScore = 4;
        
    if([other isEqualToString:@"Now"] || [other isEqualToString:@"Today"])
        otherScore = 1;
    else if([other hasSuffix:@"fternoon"])
        otherScore = 2;
    else if([other isEqualToString:@"Tonight"] || [other isEqualToString:@"Overnight"])
        otherScore = 3;
    else if([other isEqualToString:@"Tomorrow"])
        otherScore = 4;
        
    if(dayScore == -1 && otherScore == -1)
    {
        float dayPoints = -1;
        float otherPoints = -1;
        
        if([day hasPrefix:@"Monday"])
            dayPoints = 1;
        else if([day hasPrefix:@"Tuesday"])
            dayPoints = 2;
        else if([day hasPrefix:@"Wednesday"])
            dayPoints = 3;
        else if([day hasPrefix:@"Thursday"])
            dayPoints = 4;
        else if([day hasPrefix:@"Friday"])
            dayPoints = 5;
        else if([day hasPrefix:@"Saturday"])
            dayPoints = 6;
        else if([day hasPrefix:@"Sunday"])
            dayPoints = 7;
        if([day hasSuffix:@"ight"])
            dayPoints += 0.5;
            
        if([other hasPrefix:@"Monday"])
            otherPoints = 1;
        else if([other hasPrefix:@"Tuesday"])
            otherPoints = 2;
        else if([other hasPrefix:@"Wednesday"])
            otherPoints = 3;
        else if([other hasPrefix:@"Thursday"])
            otherPoints = 4;
        else if([other hasPrefix:@"Friday"])
            otherPoints = 5;
        else if([other hasPrefix:@"Saturday"])
            otherPoints = 6;
        else if([other hasPrefix:@"Sunday"])
            otherPoints = 7;
        if([other hasSuffix:@"ight"])
            otherPoints += 0.5;
            
        if(otherPoints >= 6 && dayPoints <= 2)
            return NSOrderedDescending;
        else if(dayPoints >= 6 && otherPoints <= 2)
            return NSOrderedAscending;
        else
        {
            if(otherPoints < dayPoints)
                return NSOrderedDescending;
            else if(dayPoints < otherPoints)
                return NSOrderedAscending;
            else
                return NSOrderedSame;
        }
    }
    else if(dayScore == -1)
        return NSOrderedDescending;    
    else if(otherScore == -1)
        return NSOrderedAscending;
    else
    {
        if(otherScore < dayScore)
            return NSOrderedDescending;
        else if(otherScore > dayScore)
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }
    
        
    //Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    //Monday Night, Tuesday Night, Wednesday Night, Thursday Night, Friday Night, Saturday Night, Sunday Night
    //Afternoon, Tonight, Now, Today, Tomorrow
}

- (void)stripFirstLevel
{
    NSEnumerator *arrayEnum = [forecastArrays objectEnumerator];
    NSMutableArray *nextArray;
    
    while(nextArray = [arrayEnum nextObject])
    {
        if([nextArray count])
            [nextArray removeObjectAtIndex:0];
    }
}

- (void)nextDay:(BOOL)strip
{
    if(strip && !isFirst)
        [self stripFirstLevel];
        
    if(strip)
        isFirst = NO;

    //check all the first days and find which one comes first.
    //any one that comes later should have an NSNull placed at the front
    
    NSEnumerator *forecastEnum = [forecastArrays objectEnumerator];
    NSMutableArray *nextArray;
    
    NSString *firstDate = nil;
    
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id dict = [nextArray objectAtIndex:0];
            if(dict != [NSNull null])
            {
                int res = [self compareDay:[dict objectForKey:@"Forecast - Date"] withDay:firstDate];
                
                if(res == NSOrderedAscending)
                    firstDate = [dict objectForKey:@"Forecast - Date"];
            }
        }
    }
    
    forecastEnum = [forecastArrays objectEnumerator];
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id dict = [nextArray objectAtIndex:0];
            if(dict != [NSNull null])
            {
                int res = [self compareDay:[dict objectForKey:@"Forecast - Date"] withDay:firstDate];
                
                if(res == NSOrderedDescending)
                    [nextArray insertObject:[NSNull null] atIndex:0];
            }
        }
    }
}

- (void)nextDay
{
    [self nextDay:YES];
}

- (id)objectForKey:(NSString *)key
{
    NSEnumerator *forecastEnum = [forecastArrays objectEnumerator];
    id nextArray;
    
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id obj = [nextArray objectAtIndex:0];
            if(obj != [NSNull null])
            {
                id val = [obj objectForKey:key];
                if(val)
                    return val;
            }
        }
    }

    return nil;
}

- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)inDock
{
    NSEnumerator *forecastEnum = [forecastArrays objectEnumerator];
    id nextArray;
    
    while(nextArray = [forecastEnum nextObject])
    {
        if([nextArray count])
        {
            id obj = [nextArray objectAtIndex:0];
            
            if(obj != [NSNull null])
            {
                id val = [obj objectForKey:key];
                MEWeatherModule *mod = [obj objectForKey:@"Weather Module"];
                
                if(val)
                {
                    id img = [mod imageForString:val givenKey:key inDock:inDock];
                    if(img)
                        return img;
                }
            }
        }
    }
    
    return nil;
}

@end


@implementation MEWeather

/* @called-by:  MECity initWithCityAndInfoCodes:forCity:
				MECity setCode:info:forServer:
				MECity recreateWeatherObject
				MECity setCodeInfo:forServer:
				MECity initWithCoder:

*/
- (id)initWithCodesAndInfos:(NSDictionary *)dict
{
    self = [super init];
    if(self)
    {
        moduleClasses = [[MEWeather moduleClasses] retain];
                                                 
        modules = [[NSMutableArray array] retain];
        
        NSEnumerator *keyEnum = [dict keyEnumerator];
        NSString *key;
        forecastEnum = nil;
        
        while(key = [keyEnum nextObject])
        {
            NSDictionary *sub = [dict objectForKey:key];
            NSString *code = [sub objectForKey:@"code"];
            NSString *info = [sub objectForKey:@"info"];
            BOOL active = ![[sub objectForKey:@"inactive"] boolValue];
            
            NSEnumerator *classEnum = [moduleClasses objectEnumerator];
            Class class;
            
            while(class = [classEnum nextObject])
            {
                if([[class sourceName] isEqualToString:key])
                {
                    if(code != nil)
                        [modules addObject:[[[class alloc] initWithCode:code info:info active:active] autorelease]];
                    break;
                }
            }
            
            if(!class)
                NSLog(@"Unknown source name %@ found in initWithCodesAndInfos:",key);
        }
        
    }
    return self;
}

- (void)dealloc
{
    [modules release];
    [moduleClasses release];
    [forecastEnum release];
    [super dealloc];
}

- (void)newForecastEnumeratorForMods:(NSArray *)mods
{
	if (forecastEnum) // JRC
		[forecastEnum release];

    NSMutableArray *arrayOfForecasts = [NSMutableArray array];
    
    NSArray *thoseMods = [self modulesForNames:mods];

    NSEnumerator *weatherEnum = [thoseMods objectEnumerator];
    MEWeatherModule *gen;
    id obj;
 
    while(gen = [weatherEnum nextObject])
    {
        obj = [gen objectForKey:@"Forecast Array"];
        if(obj)
        {
            [arrayOfForecasts addObject:[NSMutableArray arrayWithArray:obj]];
        }
    }

    forecastEnum = [[MEWeatherForecastEnumerator alloc] initWithForecastArrays:arrayOfForecasts];
//	NSLog(@"forecastEnum count:%i",[forecastEnum retainCount]);
}

+ (NSArray *)moduleNames
{
    return [NSArray arrayWithObjects:[MEWeatherCom sourceName],
									 [MEWundergroundCom sourceName],
									 [MENWSCom sourceName],
                                     nil];
}

+ (NSArray *)moduleClasses
{
    return [NSArray arrayWithObjects:[MEWeatherCom class],
									 [MEWundergroundCom class],
                                     [MENWSCom class],
                                     nil]; 
}

- (NSArray *)loadedModuleInstances
{
    return modules;
}

- (NSArray *)moduleClasses
{
    return moduleClasses; /* JRC */
}

// memory leak reported in [NSArray objectEnumerator] in this method
- (NSArray *)modulesForNames:(NSArray *)sourceNames
{
    NSMutableArray *array = [NSMutableArray array];

    NSEnumerator *sourceEnum = [sourceNames objectEnumerator];
    NSString *nextSourceName;
    
    while(nextSourceName = [sourceEnum nextObject])
    {
        NSEnumerator *weatherEnum = [modules objectEnumerator];
        MEWeatherModule *weather;
        
        while(weather = [weatherEnum nextObject])
        {
            if([[[weather class] sourceName] isEqualToString:nextSourceName])
            {
                [array addObject:weather];
                break;
            }
        }
        
        //if(!weather)
            //NSLog(@"%@ source name not found in modulesForNames:",nextSourceName);
    }
    
    return array;
}

+ (Class)moduleClassForName:(NSString *)sourceName
{
    NSArray *classes = [self moduleClasses];
    NSEnumerator *classEnum = [classes objectEnumerator];
    Class next;
    
    while(next = [classEnum nextObject])
        if([[next sourceName] isEqualToString:sourceName])
            return next;
            
    return nil;
}

+ (NSArray *)moduleNamesSupportingProperty:(NSString *)property
{
    NSMutableArray *array = [NSMutableArray array];

    NSArray *all = [self moduleClasses];
    
    NSEnumerator *servEnum = [all objectEnumerator];
    Class next;
    
    while(next = [servEnum nextObject])
    {
        if([[next supportedKeys] containsObject:property])
            [array addObject:[next sourceName]];
    }
            
    return array;
}

/* called-by: MEController threadedGenerateMenu:

*/
- (void)prepareNewServerData
{
    NSEnumerator *weatherEnum = [modules objectEnumerator];
    MEWeatherModule *weather;
    
    while(weather = [weatherEnum nextObject])
        [weather invalidateData];
}

+ (NSArray *)unitsForKey:(NSString *)key
{
    if([key isEqualToString:@"Weather Image"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Temperature"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Feels Like"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Dew Point"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Humidity"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Visibility"])
    {
        return [NSArray arrayWithObjects:@"Miles",
                                         @"Feet",
                                         @"Kilometers",
                                         @"Meters",
                                         nil];
    }
    else if([key isEqualToString:@"Pressure"])
    {
        return [NSArray arrayWithObjects:@"Inches",
                                         @"Millibars",
                                         @"Kilopascals",
                                         @"Hectopascals",
                                         nil];
    }
    else if([key isEqualToString:@"Precipitation"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Wind"])
    {
        return [NSArray arrayWithObjects:@"Miles/Hour",
                                         @"Kilometers/Hour",
                                         @"Meters/Second",
                                         @"Knots",
                                         nil];
    }
    else if([key isEqualToString:@"UV Index"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Last Update"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Hi"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Wind Chill"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast - Date"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Icon"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Forecast"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - High"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Forecast - Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
	else if ([key isEqualToString:@"Forecast - UV Index"])
	{
		return [NSArray arrayWithObject:@"None"];
	}
    else if([key isEqualToString:@"Forecast - Precipitation"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Link"])
    {
        return [NSArray arrayWithObject:@"None"];
    }
    else if([key isEqualToString:@"Forecast - Wind Speed"])
    {
        return [NSArray arrayWithObjects:@"Miles/Hour",
                                         @"Kilometers/Hour",
                                         nil];
    }
	else if ([key isEqualToString:@"Forecast - Wind Direction"])
	{
		return [NSArray arrayWithObject:@"None"];
	}
	else if ([key isEqualToString:@"Forecast - Humidity"])
	{
		return [NSArray arrayWithObject:@"None"];
	}
    else if([key isEqualToString:@"Clouds"])
    {
        return [NSArray arrayWithObjects:@"Miles",
                                         @"Feet",
                                         @"Kilometers",
                                         @"Meters",
                                         nil];
    }
    else if([key isEqualToString:@"Normal Hi"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Record Hi"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Normal Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else if([key isEqualToString:@"Record Low"])
    {
        return [NSArray arrayWithObjects:@"Fahrenheit",
                                         @"Celsius",
                                         nil];
    }
    else
        return [NSArray arrayWithObject:@"None"];
}

- (id)objectForKey:(NSString *)key modules:(NSArray *)mods
{
    NSArray *thoseMods = [self modulesForNames:mods];

    NSEnumerator *weatherEnum = [thoseMods objectEnumerator];
    MEWeatherModule *gen;
    id obj;
 
    while(gen = [weatherEnum nextObject])
    {
        obj = [gen objectForKey:key];
        if(obj)
            return obj;
    }

    return nil;
}

- (NSString *)stringForKey:(NSString *)key modules:(NSArray *)mods
{
    if(![key hasPrefix:@"Forecast - "])
        return [self objectForKey:key modules:mods];
    else
        return [self forecastStringForKey:key newDay:([key isEqualToString:@"Forecast - Date"])];
}

- (NSString *)forecastStringForKey:(NSString *)key newDay:(BOOL)newDay
{
    if(newDay)
        [forecastEnum nextDay];
        
    return [forecastEnum objectForKey:key];
}

+ (NSString *)shortNameForKey:(NSString *)key
{
    if([key isEqualToString:@"Precipitation"])
        return @"Prec.";
    else if([key isEqualToString:@"Forecast"])
        return @"";
    else 
        return key;
}

- (NSString *)stringForKey:(NSString *)key units:(NSString *)units prefs:(MEPrefs *)prefs displayingDegrees:(BOOL)degrees modules:(NSArray *)mods
{
    NSString *string = [self stringForKey:key modules:mods];
    
    if(!string)
        return nil;
    
    if([key hasPrefix:@"Forecast - "])
        key = [key substringFromIndex:11];
    
    if([key hasPrefix:@"Temperature"] || 
       [key hasPrefix:@"Feels Like"] ||
       [key hasPrefix:@"Dew Point"] ||
       [key hasPrefix:@"Low"] ||
       [key hasPrefix:@"Hi"] ||
       [key hasPrefix:@"Wind Chill"] ||
       [key hasPrefix:@"Normal Low"] ||
       [key hasPrefix:@"Record Low"] ||
       [key hasPrefix:@"Normal Hi"] ||
       [key hasPrefix:@"Record Hi"])
    {
        BOOL metric;
        
        if([prefs useGlobalUnits])
            metric = [[prefs degreeUnits] isEqualToString:@"Celsius"];
        else
            metric = [units isEqualToString:@"Celsius"];
    
        if(metric)
            string = [NSString stringWithFormat:@"%d",(int)round(([string floatValue] - 32.0) * 5.0/9.0)];
            
        unichar degreeSignUTF8 = 0xB0; // could be 0xBA, too
		
		NSString *degreeSign = [NSString stringWithCharacters:&degreeSignUTF8 length:1];
        if(degrees)
        {
            if(metric)
                string = [NSString stringWithFormat:@"%@%@C",string,degreeSign];
            else
                string = [NSString stringWithFormat:@"%@%@F",string,degreeSign];
        }
        else
        {
            if(metric)
                string = [NSString stringWithFormat:@"%@%@",string,degreeSign];
            else
                string = [NSString stringWithFormat:@"%@%@",string,degreeSign];
        }
    }
    
    if([key hasPrefix:@"Visibility"] || [key hasPrefix:@"Clouds"])
    {
        
        if(([prefs useGlobalUnits] && [[prefs distanceUnits] isEqualToString:@"Kilometers"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Kilometers"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mi"] && i!=0)
                {
                    if(![[tokens objectAtIndex:i-1] hasPrefix:@"Unlimited"])
                        [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1.6]];
                    [tokens replaceObjectAtIndex:i withObject:@"km"];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs distanceUnits] isEqualToString:@"Meters"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Meters"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mi"] && i!=0)
                {
                    if(![[tokens objectAtIndex:i-1] hasPrefix:@"Unlimited"])
                        [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1600]];
                    [tokens replaceObjectAtIndex:i withObject:@"m"];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs distanceUnits] isEqualToString:@"Feet"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Feet"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mi"] && i!=0)
                {
                    if(![[tokens objectAtIndex:i-1] hasPrefix:@"Unlimited"])
                        [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*5280]];
                    [tokens replaceObjectAtIndex:i withObject:@"ft"];
                }
            
            string = [tokens componentsJoinedByString:@" "];
        }
    }
    
    if([key isEqualToString:@"Pressure"])
    {
		if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Inches"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Inches"]))
		{
			string = [string stringByAppendingString:@" inches"];
		}
        else if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Millibars"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Millibars"]))
        {
			string = [NSString stringWithFormat:@"%.1f millibars",[string floatValue]*33.864];
        }
        else if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Kilopascals"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Kilopascals"]))
        {
			string = [NSString stringWithFormat:@"%.1f kilopascals",[string floatValue]*3.3864];
        }
        else if(([prefs useGlobalUnits] && [[prefs pressureUnits] isEqualToString:@"Hectopascals"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Hectopascals"]))
        {
			string = [NSString stringWithFormat:@"%.1f hectopascals",[string floatValue]*33.864];
        }
    }
    
    if([key isEqualToString:@"Wind"] || [key isEqualToString:@"Wind Speed"])
    {
		if ([string hasPrefix:@"CALM"]) // CALM
			return string;
		
		if (![string hasSuffix:@"mph"])
			string = [string stringByAppendingString:@" mph"];
        if(([prefs useGlobalUnits] && [[prefs speedUnits] isEqualToString:@"Kilometers/Hour"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Kilometers/Hour"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mph"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1.6]];
                    [tokens replaceObjectAtIndex:i withObject:@"km/h"];
                }
                
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs speedUnits] isEqualToString:@"Meters/Second"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Meters/Second"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mph"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*1600.0/3600.0]];
                    [tokens replaceObjectAtIndex:i withObject:@"m/s"];
                }
                
            string = [tokens componentsJoinedByString:@" "];
        }
        else if(([prefs useGlobalUnits] && [[prefs speedUnits] isEqualToString:@"Knots"]) || (![prefs useGlobalUnits] && [units isEqualToString:@"Knots"]))
        {
            NSMutableArray *tokens = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
            int i;
            
            for(i = 0; i<[tokens count]; i++)
                if([[tokens objectAtIndex:i] hasPrefix:@"mph"] && i!=0)
                {
                    [tokens replaceObjectAtIndex:i-1 withObject:
                                [NSString stringWithFormat:@"%.1f",[[tokens objectAtIndex:i-1] floatValue]*0.868976]];
                    [tokens replaceObjectAtIndex:i withObject:@"knots"];
                }
                
            string = [tokens componentsJoinedByString:@" "];
        }
    }
    
    return string;
}

- (NSImage *)imageForKey:(NSString *)key size:(int)size modules:(NSArray *)mods inDock:(BOOL)dock
{
    NSArray *thoseMods = [self modulesForNames:mods];

    NSEnumerator *weatherEnum = [thoseMods objectEnumerator];
    MEWeatherModule *gen;
    NSImage *img;

    while(gen = [weatherEnum nextObject])
    {
        img = [gen imageForKey:key inDock:dock];
        if(img)
        {
            [img setScalesWhenResized:YES];
            [img setSize:NSMakeSize(size,size)];
            return img;
        }
    }

    return nil;
}

- (NSString *)forecastStringForKey:(NSString *)key units:(NSString *)units prefs:(MEPrefs *)prefs displayingDegrees:(BOOL)degrees modules:(NSArray *)mods
{
   return [self stringForKey:key units:units prefs:prefs displayingDegrees:degrees modules:mods];
}

- (NSImage *)forecastImageForKey:(NSString *)key size:(int)size modules:(NSArray *)mods inDock:(BOOL)dock
{
	if (forecastEnum == nil)
		[self newForecastEnumeratorForMods:mods];
    NSImage *img = [forecastEnum imageForKey:key inDock:dock];
    [img setScalesWhenResized:YES];
    [img setSize:NSMakeSize(size,size)];
    return img;
}


+ (NSArray *)performCitySearch:(NSString *)search module:(MEWeatherModule *)weather info:(NSString *)info
{
    return [[weather class] performCitySearch:search info:info];
}

@end
