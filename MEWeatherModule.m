//
//  MEWeatherModule.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//	03 Sep 2003	Rich Martin	changed some initWithContentsOfURL: messages to stringFromWebsite:spacesOnly:
//	12 Sep 2003	Rich Martin	added code for Heat Index data in wunderground.com's loadWeatherData
//	16 Sep 2003	Rich Martin	assert leading slash in 'code' for wunderground.com's weatherQueryURL
//

#import "MEWeatherModule.h"
#import "MEWeatherModuleParser.h"
#import "MEWebUtils.h" // MEWebFetcher

#define extendRange(x,y)        NSMakeRange((x).location+(x).length,y-((x).location+(x).length))
#define betweenRange(x,y)       NSMakeRange((x).location+(x).length,(y).location-((x).location+(x).length))

@implementation MEWeatherModule

- (id)initWithCode:(NSString *)theCode info:(NSString *)theInfo active:(BOOL)isActive
{ 
    self = [super init];
    if(self)
    {
		dataIsLoaded = NO;
        weatherData = nil;
		
		code = theCode;
		info = theInfo;
		
        supplyingOldData = YES;
        active = isActive;
		debug = YES;
    }
    return self;
}

+ (NSString *)sourceName
{
    return @"Generic";
}

+ (NSArray *)supportedKeys
{
    return [NSArray array];
}

+ (NSArray *)supportedInfos
{
    return [NSArray array];
}

- (void)invalidateData
{
    dataIsLoaded = NO;
}

- (BOOL)supplyingOldData
{
    return supplyingOldData;
}

- (BOOL)loadWeatherData
{
    dataIsLoaded = YES;
    supplyingOldData = YES;
    
    return active;
}

- (id)objectForKey:(NSString *)key
{
    if(!dataIsLoaded && (code != nil))
        [self loadWeatherData];
	
    return [[weatherData objectForKey:key] copy];
}

- (NSString *)stringForKey:(NSString *)key
{
    if(!dataIsLoaded && (code != nil))
        [self loadWeatherData];
	
    return [[weatherData objectForKey:key] copy];
}

- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)dock
{
    return [self imageForString:[self stringForKey:key] givenKey:key inDock:dock];
}

/* Overloaded by child classes */
- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
    return nil;
}

#ifndef VALID_RANGE
#define VALID_RANGE
BOOL validRange(NSRange range, int len)
{
    //if (range.location == NSNotFound || range.location < 0 || range.location + range.length > len)
    if (range.location == NSNotFound || range.location + range.length > len)
        return NO;
	
    else
        return YES;
}
#endif

+ (NSString *)getStringWithLeftBound:(NSString *)left rightBound:(NSString *)right string:(NSString *)string length:(int)stringLength lastRange:(NSRange *)lastRange
{
    NSString *temp;
    
    NSRange leftRange;
    NSRange rightRange;
    float leftSum;
    float rightSum;
	NSRange myRange;
    
    if(!validRange(*lastRange,stringLength))
        return nil;
    
    
    leftRange = [string rangeOfString:left                                                                                                     
							  options:NSCaseInsensitiveSearch  
								range:*lastRange];
    if(!validRange(leftRange,stringLength))
        return nil;
    leftSum = leftRange.location + leftRange.length;
    
    myRange = NSMakeRange(leftSum, stringLength - leftSum);
    rightRange = [string rangeOfString:right
							   options:NSCaseInsensitiveSearch
								 range:myRange];
    if(!validRange(rightRange,stringLength))
        return nil;
    rightSum = rightRange.location+rightRange.length;
	
	
    if(rightRange.location-leftSum < 0)
        return nil;
    
    temp = [string substringWithRange:NSMakeRange(leftSum,rightRange.location-leftSum)];
    
    if(rightSum != 0)
        rightSum--;
    
	*lastRange = NSMakeRange(rightSum,stringLength - rightSum);
    
	
    return temp;
}

+ (NSString *)stripWhiteSpaceAtBeginningAndEnd:(NSString *)str
{
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@" \n\r\t\f"];
    const char *cString = [str UTF8String];
    
    int lowerBound = 0;
    int length = [str length];
    
    while(length > lowerBound && [set characterIsMember:cString[lowerBound]])
        lowerBound++;
	
    int upperBound = length - 1;
    
    while(upperBound > lowerBound && [set characterIsMember:cString[upperBound]])
        upperBound--;
	
    if(lowerBound >= length || upperBound + 1 - lowerBound <= 0)
        return nil;
	
    NSRange range = NSMakeRange(lowerBound,upperBound + 1 - lowerBound);
    
    return [str substringWithRange:range];
}

+ (NSString *)replaceString:(NSString *)bad withString:(NSString *)replace forString:(NSString *)old
{
    NSRange range;
    
    while((range = [old rangeOfString:bad]).location!=NSNotFound)
        old = [NSString stringWithFormat:@"%@%@%@",[old substringToIndex:range.location],
			replace,
			[old substringFromIndex:range.location+range.length]];
	
    return old;
}

+ (NSString *)stripSuffix:(NSString *)suf forString:(NSString *)string
{
    NSRange range = [string rangeOfString:suf options:NSBackwardsSearch];
    
    if(range.location==NSNotFound)
        return string;
    
    return [string substringToIndex:range.location];
}

+ (NSString *)stripPrefix:(NSString *)prf forString:(NSString *)string
{
    NSRange range = [string rangeOfString:prf];
    
    if(range.location==NSNotFound)
        return string;
    
    return [string substringFromIndex:range.location+range.length];
}


+ (NSArray *)performCitySearch:(NSString *)search info:(NSString *)information
{
    return [[MEWeatherModuleParser sharedInstance] performCitySearch:search onServer:[self sourceName]];
}

+ (NSString *)dateInfoForCalendarDate:(NSCalendarDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-yy"];
    //NSString *d = [date descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults]
    //                                                                            stringForKey:NSShortDateFormatString]
	//										 timeZone:nil
	//										   locale:nil];
    NSString *d = [dateFormatter stringFromDate:date];
    //NSString *t = [date descriptionWithCalendarFormat:[[NSUserDefaults standardUserDefaults]
    //                                                            stringForKey:NSTimeFormatString]
	//										 timeZone:nil
	//										   locale:nil];
	
    [dateFormatter setDateFormat:@"hh:mm:ss aaa"];
    NSString *t = [dateFormatter stringFromDate:date];
    return [NSString stringWithFormat:@"%@ %@",d,t];
}

//
// name-- optionally includes an extension.
//
NSImage *imageForName(NSString *name, BOOL inDock)
{
    NSString *fileName;
    if (!inDock) {
        fileName = [[NSBundle mainBundle] pathForImageResource:[NSString stringWithFormat:@"MB-%@",name]];
    } else {    
        fileName = [[NSBundle mainBundle] pathForResource:name ofType:@"tiff"];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:fileName];
    
    return image;
}


@end


@implementation MEYahooWeatherCom

+ (NSString *)sourceName
{
    return @"http://developer.yahoo.com/weather/";
}

@end


@implementation MEWeatherCom

+ (NSString *)sourceName
{
    return @"Weather.com";
}

+ (NSArray *)supportedKeys
{
    return [NSArray arrayWithObjects:@"Weather Image",
		@"Temperature",
		@"Forecast",
		@"Feels Like",
		@"Dew Point",
		@"Humidity",
		@"Visibility",
		@"Pressure",
		//@"Precipitation",
		@"Wind",
		@"UV Index",
		@"Last Update",
		@"Hi",
		@"Low",
		@"Weather Link",
		@"Forecast - Link",
		@"Forecast - Date",
		@"Forecast - Icon",
        @"Forecast - Forecast",
		@"Forecast - High",
		@"Forecast - Low",
		@"Forecast - UV Index",
		@"Forecast - Wind Speed",
		@"Forecast - Wind Direction",
		@"Forecast - Humidity",
		@"Forecast - Precipitation",
		@"Radar Image",
		@"Weather Alert",
		@"Weather Alert Link",
		nil];
}

+ (NSArray *)supportedInfos
{
    return [NSArray arrayWithObject:@"Global"];
}

- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
    NSImage *img = nil;
    
    NSString *name = [[string lastPathComponent] stringByDeletingPathExtension];
    int val = [name intValue];
    
    NSString *imageName;
    
    if([key isEqualToString:@"Moon Phase"])
    {
        NSString *fileName = [[NSBundle mainBundle] pathForImageResource:@"Moon"];
        return [[NSImage alloc] initWithContentsOfFile:fileName];
    }
    switch(val)
    {
        case 1:
        case 2:
        case 5:
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 39:
        case 40:
        case 45:
            imageName = @"Rain";
            break;
        case 3:
        case 4:
        case 17:
        case 35:
        case 37:
        case 38:
        case 47:
            imageName = @"Thunderstorm";
            break;
        case 6:
        case 13:
        case 14:
        case 15:
        case 16:
        case 18:
        case 41:
        case 42:
        case 43:
        case 46:
            imageName = @"Snow";
            break;
        case 7:
            imageName = @"Sleet";
            break;
        case 19:
        case 20:
        case 21:
        case 22:
            imageName = @"Hazy";
            break;
        case 23:
        case 24:
        case 25:
            imageName = @"Wind";
            break;
        case 26:
            imageName = @"Cloudy";
            break;
        case 27:
            imageName = @"Moon-Cloud-2";
            break;
        case 28:
            imageName = @"Sun-Cloud-2";
            break;
        case 29:
        case 33:
            imageName = @"Moon-Cloud-1";
            break;
        case 30:
        case 34:
        case 44:
            imageName = @"Sun-Cloud-1";
            break;
        case 31:
            imageName = @"Moon";
            break;
        case 32:
        case 36:
            imageName = @"Sun";
            break;
        default:
            imageName = @"Unknown";
            NSLog([NSString stringWithFormat:@"Unknown graphic image, id=%d", val],@"");
            break;
    }
	
    return imageForName(imageName,dock);
} // imageForString

- (BOOL)loadWeatherData
{
    if(![super loadWeatherData])
    {
        weatherData = nil;
        return NO;
    }
	
    if([info isEqualToString:@"Global"])
        [self loadGlobalWeatherData];
    else
    	[self loadGlobalWeatherData];
    
    return YES;
} // loadWeatherData

- (void)checkForAlert:(NSCharacterSet*)set lastRange:(NSRange*)lastRange class:(Class*)class string:(NSString*)string
{
    NSString *alertTemp;
	
    alertTemp = [*class getStringWithLeftBound:@"<div id=\"alerttext\">"
									rightBound:@"</script>"
										string:string
										length:[string length]
									 lastRange:lastRange];
	alertTemp = [alertTemp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (alertTemp && [alertTemp length])
	{
		NSMutableArray *weatherAlerts = [NSMutableArray array];
		int alertLength = [alertTemp length];
		NSRange alertRange = NSMakeRange(0,alertLength);
		while(alertTemp != nil)
		{
			NSString *alertString;
			NSString *alertStringLink;
			alertString = [*class getStringWithLeftBound:@"<a href=\"http://mw.weather.com/wxalrt/"
											  rightBound:@"?"
												  string:alertTemp
												  length:alertLength
											   lastRange:&alertRange]; 
			alertString = [alertString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if(!alertString)
				break;
			
			// Actual alert
			alertString = [*class getStringWithLeftBound:@">"
											  rightBound:@"<"
												  string:alertTemp
												  length:alertLength
											   lastRange:&alertRange];
			alertString = [alertString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if(!alertString)
				break;
			
			if(alertString)
			{
				alertString = [NSString stringWithFormat:@"Weather.com: %@",alertString];
				alertStringLink = [NSString stringWithFormat:@"http://mw.weather.com/wxalrt/%@?family=webkit", code];
				
				NSMutableDictionary *diction = [NSMutableDictionary dictionary];
				[diction setObject:@"Weather Alert" forKey:@"title"];
				[diction setObject:alertString forKey:@"description"];
				[diction setObject:alertStringLink forKey:@"link"];
				
				[weatherAlerts addObject:diction];
			}     
		}
		
		if([weatherAlerts count])
			[weatherData setObject:weatherAlerts forKey:@"Weather Alert"];
	}
	
} // checkForAlert

- (void)loadRadar:(NSCharacterSet*)set
		lastRange:(NSRange*)lastRange
            class:(Class*)class
{
	NSURL *radarUrl;
    NSString *radarData;
    int radarStringLength;
    NSString *radarTemp;
	
	//NSString *rawUrl = [NSString stringWithFormat:@"http://www.weather.com/outlook/travel/businesstraveler/map/%@?bypassredirect=true",code];
	NSString *rawUrl = [NSString stringWithFormat:@"http://www.weather.com/weather/map/classic/%@?bypassredirect=true",code];
	
    NSString *escapedUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)rawUrl,NULL,NULL,kCFStringEncodingUTF8));
	radarUrl = [NSURL URLWithString:escapedUrl];
	
	radarData = [[MEWebFetcher sharedInstance] fetchURLtoString:radarUrl];	// JRC
	radarData = [radarData stringByTrimmingCharactersInSet:set];
	if(!radarData)
	{
		NSLog(@"The string for the forecast data for URL %@ was empty.",radarUrl);
		return;
	}
	
	radarStringLength = [radarData length];
	if(radarStringLength==0)
	{
		NSLog(@"A zero-length string was downloaded for URL %@.",radarUrl);
		return;
	}
	
	*lastRange = NSMakeRange(0,radarStringLength);
	
	//get the radar image
	radarTemp = [*class getStringWithLeftBound:@"NAME=\"mapImg\" SRC=\""
									rightBound:@"\" WIDTH="
										string:radarData
										length:radarStringLength
									 lastRange:lastRange];
	radarTemp = [radarTemp stringByTrimmingCharactersInSet:set];
	//NSLog(radarTemp);
	if(radarTemp)
		[weatherData setObject:radarTemp forKey:@"Radar Image"];
	
} // loadRadar

- (void)loadCurrentConditions:(NSCharacterSet*)set lastRange:(NSRange*)lastRange class:(Class*)class string:(NSString*)string
{
    NSString *currentConditionsTemp;
	int currentConditionsStringLength = [string length];

	//just move us down towards the right location
	/* OHL Comment out useless (and silly) pattern:
	 temp = [class getStringWithLeftBound:@"padding:0px 0px 10px 0px;"
	 rightBound:@">"
	 string:string
	 length:stringLength
	 lastRange:&lastRange];
	 */
    // OHL 29 Aug 2007: Replacement for the above with a little bit
    // better chance at lasting more than a few days...
	// Looking for: wxicon32-01.png
	// in particular the 32
	//NSLog([NSString stringWithFormat:@"Weather string=%@", string]);
    currentConditionsTemp = [*class getStringWithLeftBound:@"AnimIcons/wxicon"
							   rightBound:@"-"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	
	//Checking for a weather icon
	//    temp = [class getStringWithLeftBound:@"<p>"
	//			      rightBound:@"</p>"
	//							  string:string
	//							  length:stringLength
	//						   lastRange:&lastRange];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
	{
		[weatherData setObject:currentConditionsTemp forKey:@"Weather Image"];
		//NSLog([NSString stringWithFormat:@"Found Weather Image, name=%@", currentConditionsTemp]);
	}
	else
	{
		currentConditionsTemp = [*class getStringWithLeftBound:@"\"curicon\", \"wxicon"
								   rightBound:@"-"
									   string:string
									   length:currentConditionsStringLength
									lastRange:lastRange];
		currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
		if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		{
			[weatherData setObject:currentConditionsTemp forKey:@"Weather Image"];
		}
		else
		{
			currentConditionsTemp = [*class getStringWithLeftBound:@"45x45/bigicon"
									   rightBound:@"."
										   string:string
										   length:currentConditionsStringLength
										lastRange:lastRange];
		}
		currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
		if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		{
			[weatherData setObject:currentConditionsTemp forKey:@"Weather Image"];
		}
	}
	
	//end weather icon checking
	
	//get the current temp
	currentConditionsTemp = [*class getStringWithLeftBound:@"<div id=\"cc_temp\">"
							   rightBound:@"&"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Temperature"];
	//end getting current temp
	
	//get the current feels-like
	[*class getStringWithLeftBound:@"Feels like:"
						rightBound:@"div class"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
	//currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\">"
							   rightBound:@"&"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Feels Like"];
	//end getting current feels-like
	
	//    //get the current forecast
	//    temp = [class getStringWithLeftBound:@"obsTextA>"
	//                  rightBound:@"<"
	//                  string:string
	//                  length:stringLength
	//                  lastRange:&lastRange];
	//    if(temp && ![temp hasPrefix:@"N/A"])
	//        [weatherData setObject:temp forKey:@"Forecast"];
	//    //end getting current forecast
	
	//get the current uv index
	[*class getStringWithLeftBound:@"UV Index:"
						rightBound:@"<div"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
	//currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\">"
							   rightBound:@"</div>"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"UV Index"];
	//end getting current uv index
	
	//get the current wind
	[*class getStringWithLeftBound:@"Wind:"
						rightBound:@"<div"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
	//currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\"> "
							   rightBound:@"</div>"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:[*class replaceString:@" <BR> " withString:@" "
										   forString:[*class replaceString:@"&nbsp;"
																withString:@" "
																 forString:currentConditionsTemp]]
						forKey:@"Wind"];
	//end getting current pressure
	
	//get the current humidity
    [*class getStringWithLeftBound:@"Humidity:"
						rightBound:@"<div"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
	//currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\">"
							   rightBound:@"</div>"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Humidity"];
	//end getting current humidity
	
	//get the current pressure
	[*class getStringWithLeftBound:@"Pressure:"
						rightBound:@"<div"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
	currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\">"
							   rightBound:@" in"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Pressure"];
	//end getting current pressure
	
	//get the current dew point
    currentConditionsTemp = [*class getStringWithLeftBound:@"Dew Point:"
							   rightBound:@"<div"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	if (currentConditionsTemp)
	{
		currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\">"
								   rightBound:@"&"
									   string:string
									   length:currentConditionsStringLength
									lastRange:lastRange];
		currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	}
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Dew Point"];
	//end getting current dew point
	
    //get the current visibility
	[*class getStringWithLeftBound:@"Visibility:"
						rightBound:@"<div"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
	currentConditionsTemp = [*class getStringWithLeftBound:@"cc_minordata\">"
							   rightBound:@"</div"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	currentConditionsTemp = [currentConditionsTemp stringByTrimmingCharactersInSet:set];
	if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Visibility"];
    //end getting current visibility
	
    //get the current sunrise
    currentConditionsTemp = [*class getStringWithLeftBound:@"<div class=\"ccWeaRes\">" // dummy
							   rightBound:@"Sunrise:"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
	if (currentConditionsTemp)
	{
		currentConditionsTemp = [*class getStringWithLeftBound:@"<div class=\"ccWeaRes\">"
								   rightBound:@"</div>"
									   string:string
									   length:currentConditionsStringLength
									lastRange:lastRange];
	}
    if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Sunrise"];
    //end getting current sunrise
	
    //get the current sunset
	[*class getStringWithLeftBound:@"<div class=\"ccWeaRes\">" // dummy
						rightBound:@"Sunset:"
							string:string
							length:currentConditionsStringLength
						 lastRange:lastRange];
    currentConditionsTemp = [*class getStringWithLeftBound:@"<div class=\"ccWeaRes\">"
							   rightBound:@"</div>"
								   string:string
								   length:currentConditionsStringLength
								lastRange:lastRange];
    if(currentConditionsTemp && ![currentConditionsTemp hasPrefix:@"N/A"])
		[weatherData setObject:currentConditionsTemp forKey:@"Sunset"];
    //end getting current sunset
	
	[self loadRadar:set lastRange:lastRange class:class];
	
} // loadCurrentConditions

- (void)loadExtendedWeatherDay:(int*)numDaysSoFar
						oneDay:(NSString*)oneDay
						   set:(NSCharacterSet*)set
						 class:(Class*)class
			   extendedWeather:(NSString *)extendedWeatherTemp
				 forecastArray:(NSMutableArray *)forecastArray
{
	oneDay = [oneDay stringByTrimmingCharactersInSet:set];
	NSMutableDictionary *forecastDictionary = [NSMutableDictionary dictionary];
	int oneDayLength = [oneDay length];
	NSRange oneDayRange = NSMakeRange(0,oneDayLength);
	NSString *forecastLinkUrlString,
	*day,
	*date,
	*iconURL,
	*forecast,
	*precip,
	*uvindex,*windspeed,*longwinddir,*shortwinddir,*humidity;
	(*numDaysSoFar)++;
	//	link = [class getStringWithLeftBound:@"<A HREF=" /* URL for the days weather */
	//							  rightBound:@">"
	//								  string:oneDay
	//								  length:oneDayLength
	//							   lastRange:&oneDayRange];
	//	
	//	//lastRange.location-=2; /* I don't understand */
	//	oneDayRange.location--; /* Add back the > */
	//	oneDayRange.length++;   /* keep our the whole range*/
	
	/* ------------- DATE -------------- */
	date = [*class getStringWithLeftBound:@"te_date\">" // dummy
							   rightBound:@"</td"
								   string:oneDay
								   length:oneDayLength
								lastRange:&oneDayRange];
	date = [date stringByTrimmingCharactersInSet:set];
	
	/*
	 day = [class getStringWithLeftBound:@">"
	 rightBound:@"</td>"
	 string:oneDay
	 length:oneDayLength
	 lastRange:&oneDayRange];
	 day = [day stringByTrimmingCharactersInSet:set];
	 */
	
	NSString *separatorString = @" ";
	NSScanner *aScanner= [NSScanner scannerWithString:date];
	[aScanner scanUpToString:separatorString intoString:&day];
	[aScanner scanUpToString:separatorString intoString:&extendedWeatherTemp];
	[aScanner scanUpToString:separatorString intoString:&date];
	date = [NSString stringWithFormat:@"%@ %@", extendedWeatherTemp, date];
	
	NSRange range2 = NSMakeRange(oneDayRange.location, oneDayRange.length);
	/* ------------- URL of icon (weather pic) ------------ */
	iconURL = [*class getStringWithLeftBound:@"<img src=\"/webkit/images/generic/big-wxicons/bigicon"
								  rightBound:@".png"
									  string:oneDay
									  length:oneDayLength
								   lastRange:&oneDayRange];
	iconURL = [iconURL stringByTrimmingCharactersInSet:set];
	if (iconURL == NULL)
	{
		iconURL = [*class getStringWithLeftBound:@"<img src=\"/webkit/images/generic/big-wxicons/bigicon"
									  rightBound:@".png"
										  string:oneDay
										  length:oneDayLength
									   lastRange:&oneDayRange];
		iconURL = [iconURL stringByTrimmingCharactersInSet:set];
	}
	if (iconURL == NULL)
	{
		iconURL = [*class getStringWithLeftBound:@"bigicon"
									  rightBound:@".jpg"
										  string:oneDay
										  length:oneDayLength
									   lastRange:&oneDayRange];
		iconURL = [iconURL stringByTrimmingCharactersInSet:set];
	}
	
	/* ------------- Forecast ------------- */
	//          e.g. partly sunny, cloudy, etc.
	forecast = [*class getStringWithLeftBound:@"<br/>"
								   rightBound:@"</td>"
									   string:oneDay
									   length:oneDayLength
									lastRange:&oneDayRange];
	forecast = [forecast stringByTrimmingCharactersInSet:set];
	
	/* ------------- High ------------- */
	NSString *high = [*class getStringWithLeftBound:@"High: "
										 rightBound:@"&"
											 string:oneDay
											 length:oneDayLength
										  lastRange:&oneDayRange];
	high = [high stringByTrimmingCharactersInSet:set];
	
	/* ------------- Low ------------- */
	NSString *low = [*class getStringWithLeftBound:@"Low: "
										rightBound:@"&"
											string:oneDay
											length:oneDayLength
										 lastRange:&range2];
	low = [low stringByTrimmingCharactersInSet:set];
	
	/* ------------- UVIndex ------------- */
	/*
	 uvindex = [class getStringWithLeftBound:@"'"
	 rightBound:@"',"
	 string:oneDay
	 length:oneDayLength
	 lastRange:&oneDayRange];
	 */
	
	/* ------------- wind speed (mph) ------------- */
	/*
	 windspeed = [class getStringWithLeftBound:@"'"
	 rightBound:@"',"
	 string:oneDay
	 length:oneDayLength
	 lastRange:&oneDayRange];
	 */
	
	/* ------------- long wind direction ------------- */
	/*
	 longwinddir = [class getStringWithLeftBound:@"'"
	 rightBound:@"',"
	 string:oneDay
	 length:oneDayLength
	 lastRange:&oneDayRange];
	 */
	
	/* ------------- short wind dir ------------- */
	/*
	 shortwinddir = [class getStringWithLeftBound:@"'"
	 rightBound:@"',"
	 string:oneDay
	 length:oneDayLength
	 lastRange:&oneDayRange];
	 */
	
	/* -------------- CHANCE OF PRECIP -------------- */
	precip = [*class getStringWithLeftBound:@"Precip: "
								 rightBound:@"."
									 string:oneDay
									 length:oneDayLength
								  lastRange:&oneDayRange];
	precip = [precip stringByTrimmingCharactersInSet:set];
	precip = [NSString stringWithFormat:@"%@%%",precip];
	
	/* -------------- Humidity -------------- */
	/*
	 humidity = [class getStringWithLeftBound:@"'"
	 rightBound:@"')"
	 string:oneDay
	 length:oneDayLength
	 lastRange:&oneDayRange];
	 humidity = [NSString stringWithFormat:@"%@%%",humidity];
	 */
	
	forecastLinkUrlString = [NSString stringWithFormat:@"http://www.weather.com/outlook/travel/businesstraveler/wxdetail/%@?dayNum=%d", code, ((*numDaysSoFar)-1)];
	[forecastDictionary setObject:forecastLinkUrlString
						   forKey:@"Forecast - Link"];
	if(date)
		[forecastDictionary setObject:date     forKey:@"Forecast - Date"];  
	if(day)
		[forecastDictionary setObject:day      forKey:@"Forecast - Day"];   
	if (high && ![high isEqualToString:@"N/A"])
		[forecastDictionary setObject:high     forKey:@"Forecast - High"];
	if (low && ![low isEqualToString:@"N/A"])
		[forecastDictionary setObject:low      forKey:@"Forecast - Low"];
	if(iconURL && ![iconURL hasPrefix:@"N/A"])
		[forecastDictionary setObject:iconURL  forKey:@"Forecast - Icon"];
	if (forecast && ![forecast hasPrefix:@"N/A"])
		[forecastDictionary setObject:forecast forKey:@"Forecast - Forecast"];
	/*
	 if (uvindex && ![uvindex isEqualToString:@"N/A"])
	 [forecastDictionary setObject:uvindex      forKey:@"Forecast - UV Index"];
	 if(windspeed && ![windspeed hasPrefix:@"N/A"])
	 [forecastDictionary setObject:windspeed    forKey:@"Forecast - Wind Speed"];
	 if (longwinddir && ![longwinddir hasPrefix:@"N/A"])
	 [forecastDictionary setObject:longwinddir  forKey:@"Forecast - Wind Direction"];
	 if (humidity && ![humidity hasPrefix:@"N/A"])
	 [forecastDictionary setObject:humidity     forKey:@"Forecast - Humidity"];
	 */
	if (precip && ![precip hasPrefix:@"N/A"])
	{
		[forecastDictionary setObject:precip   forKey:@"Forecast - Precipitation"];
		//if(itemCounter == 1)
		//	[weatherData setObject:precip forKey:@"Precipitation"];
	}
	
	
	[forecastDictionary setObject:self forKey:@"Weather Module"];
	[forecastArray addObject:forecastDictionary];
	//NSLog(@"Day Added.");
} // loadExtendedWeatherDay

- (void)loadExtendedWeather:(NSCharacterSet*)set lastRange:(NSRange*)lastRange class:(Class*)class
{
	NSURL *extendedWeatherUrl;
	NSString *extendedWeatherDataString;
	int extendedWeatherStringLength;
	NSString *extendedWeatherTemp;
	//int itemCounter = 0;
	NSString *oneDay;
	NSMutableArray *forecastArray = [NSMutableArray array]; 
	int numDaysSoFar=0;
	
	NSString *rawUrl = [NSString stringWithFormat:@"http://mw.weather.com/tenday/%@?family=webkit",code];

	NSString *escapedUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)rawUrl,NULL,NULL,kCFStringEncodingUTF8));
	extendedWeatherUrl = [NSURL URLWithString:escapedUrl];

	extendedWeatherDataString = [[MEWebFetcher sharedInstance] fetchURLtoString:extendedWeatherUrl];	// JRC
	extendedWeatherDataString = [extendedWeatherDataString stringByTrimmingCharactersInSet:set];
	if(!extendedWeatherDataString)
	{
		NSLog(@"The string for the forecast data for URL %@ was empty.",extendedWeatherUrl);
		return;
	}
	
	extendedWeatherStringLength = [extendedWeatherDataString length];
	if(extendedWeatherStringLength==0)
	{
		NSLog(@"A zero-length string was downloaded for URL %@.",extendedWeatherDataString);
		return;
	}
	
	*lastRange = NSMakeRange(0,extendedWeatherStringLength);
	
	//move down file
	extendedWeatherTemp = [*class getStringWithLeftBound:@"id=\"fcstTable\""
											  rightBound:@"<tr>"
												  string:extendedWeatherDataString
												  length:extendedWeatherStringLength
											   lastRange:lastRange];
	
	//begin getting the forecast
	//NSLog([NSString stringWithFormat:@"Extended weather string=\n%@", string]);
	while((oneDay = [*class getStringWithLeftBound:@"tendaytable"
										rightBound:@"</table>"
											string:extendedWeatherDataString
											length:extendedWeatherStringLength
										 lastRange:lastRange]) &&
		  (numDaysSoFar<=10))
	{
		[self loadExtendedWeatherDay:&numDaysSoFar
							  oneDay:oneDay
								 set:set
							   class:class
					 extendedWeather:extendedWeatherTemp
					   forecastArray:forecastArray];
	}
	
	rawUrl = [NSString stringWithFormat:@"http://mw.weather.com/tenday/%@?family=webkit&pagenumber=2",code];
	
	escapedUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)rawUrl,NULL,NULL,kCFStringEncodingUTF8));
	extendedWeatherUrl = [NSURL URLWithString:escapedUrl];
	
	extendedWeatherDataString = [[MEWebFetcher sharedInstance] fetchURLtoString:extendedWeatherUrl];	// JRC
	extendedWeatherDataString = [extendedWeatherDataString stringByTrimmingCharactersInSet:set];
	if(!extendedWeatherDataString)
	{
		NSLog(@"The string for the forecast data for URL %@ was empty.",extendedWeatherUrl);
		return;
	}
	
	extendedWeatherStringLength = [extendedWeatherDataString length];
	if(extendedWeatherStringLength==0)
	{
		NSLog(@"A zero-length string was downloaded for URL %@.",extendedWeatherDataString);
		return;
	}
	
	*lastRange = NSMakeRange(0,extendedWeatherStringLength);
	
	//move down file
	extendedWeatherTemp = [*class getStringWithLeftBound:@"id=\"fcstTable\""
											  rightBound:@"<tr>"
												  string:extendedWeatherDataString
												  length:extendedWeatherStringLength
											   lastRange:lastRange];

	while((oneDay = [*class getStringWithLeftBound:@"tendaytable"
										rightBound:@"</table>"
											string:extendedWeatherDataString
											length:extendedWeatherStringLength
										 lastRange:lastRange]) &&
		  (numDaysSoFar<=10))
	{
		[self loadExtendedWeatherDay:&numDaysSoFar
							  oneDay:oneDay
								 set:set
							   class:class
					 extendedWeather:extendedWeatherTemp
					   forecastArray:forecastArray];
	}
	[weatherData setObject:forecastArray forKey:@"Forecast Array"];
	
} // loadExtendedWeather

- (void)loadGlobalWeatherData
{
	NSURL *weatherForURL;
	NSURL *linkUrl;
	NSString *globalWeatherData;
	NSRange lastRange;
	int globalWeatherDataStringLength;
	//NSCalendarDate *d = [NSCalendarDate calendarDate];
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@" \n\r\t\f\v"];
	NSMutableDictionary *lastWeather = weatherData;
    
	// Link for "Weather for"
	NSString *linkUrlString = [NSString stringWithFormat:@"http://www.weather.com/weather/today/%@", code];
	NSString *weatherForUrlString = [NSString stringWithFormat:@"http://mw.weather.com/now/%@?family=webkit",code];
    
	Class class = [self class];
	
	if([[MEPrefs sharedInstance] logMessagesToConsole])
	{
		NSLog(weatherForUrlString,@"");
	}
	
	NSString *escapedUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)weatherForUrlString,NULL,NULL,kCFStringEncodingUTF8));
	weatherForURL = [NSURL URLWithString:escapedUrl];

	escapedUrl = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)linkUrlString,NULL,NULL,kCFStringEncodingUTF8));
	linkUrl = [NSURL URLWithString:escapedUrl];
	
	if(!weatherForURL)
	{
		NSLog(@"There was a problem creating the URL for code: %@.",code);
		return;
	}
	
	globalWeatherData = [[MEWebFetcher sharedInstance] fetchURLtoString:weatherForURL];	// JRC
	globalWeatherData = [globalWeatherData stringByTrimmingCharactersInSet:set];
	
	if(!globalWeatherData)
	{
		NSLog(@"There was an error downloading the URL %@.",weatherForURL);
		return;
	}
	
    globalWeatherDataStringLength = [globalWeatherData length];
    
	if(globalWeatherDataStringLength==0)
	{	
		NSLog(@"A zero-length string was downloaded for URL %@.",weatherForURL);
		return;
	}
	
	lastRange = NSMakeRange(0,globalWeatherDataStringLength);
    
	weatherData = [[NSMutableDictionary alloc] initWithCapacity:0];
	[weatherData setObject:@"Today" forKey:@"Date"];                   
    
	// Link for "Weather for"
	[weatherData setObject:[linkUrl absoluteString] forKey:@"Weather Link"];
    
	//get weather alert info
	[self checkForAlert:set lastRange:&lastRange class:&class string:globalWeatherData];

	//get current weather conditions
	[self loadCurrentConditions:(NSCharacterSet *)set lastRange:&lastRange class:&class string:globalWeatherData];

	//get extended forecast
	[self loadExtendedWeather:set lastRange:&lastRange class:&class];

	//get current date/time
	//d = [NSCalendarDate calendarDate];
	[weatherData setObject:[class dateInfoForCalendarDate:[NSCalendarDate calendarDate]]  forKey:@"Last Update"];
	
	if([weatherData count] > 5)
	{
		supplyingOldData = NO;
	}
	else
	{
		supplyingOldData = YES;
		weatherData = lastWeather;
	}

} // loadGlobalWeatherData

@end


@implementation MEWundergroundCom

+ (NSString *)sourceName
{
    return @"Wunderground.com";
}

+ (NSArray *)supportedKeys
{
    return [NSArray arrayWithObjects:nil];
    /*return [NSArray arrayWithObjects:@"Weather Image",
		@"Weather Link",
		@"Wind",
		@"Humidity",
		@"Dew Point",
		@"Temperature",
		@"Visibility",
		@"Forecast",
		@"Pressure",
		@"Clouds",
		@"Length of Day",
		@"Sunrise",
		@"Sunset",
		@"Moon Rise",
		@"Moon Set",
		@"Last Update",
		@"Wind Chill",
		@"Normal Hi",
		@"Record Hi",
		@"Normal Low",
		@"Record Low",
		@"UV Index",
		@"Precipitation",
		@"Forecast - Date",
		@"Forecast - Icon",
//		@"Forecast - Hi",
		@"Forecast - Low",
//		@"Forecast - Wind",
		@"Forecast - Forecast",
		@"Forecast - Precipitation",
		@"Hi",
		@"Low",
		@"Radar Image",
		@"Moon Phase",
		@"Weather Alert",
		@"Weather Alert Link",
		nil];*/
}

+ (NSArray *)supportedInfos
{
    return [NSArray arrayWithObject:@"English"];
}

- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
    NSImage *img = nil;
    
    NSString *name = [[string lastPathComponent] stringByDeletingPathExtension];
    
    NSString *imageName;
    
    if([key isEqualToString:@"Moon Phase"])
    {
        NSString *s = [MEWeatherModule stripPrefix:@"moon" forString:name];
        NSString *imageFileName = [[NSBundle mainBundle] pathForImageResource:[NSString stringWithFormat:@"MoonPhase-%@",s]];
        if (imageFileName == nil) {
            imageFileName = [[NSBundle mainBundle] pathForImageResource:@"Moon"];
        }
        
        return [[NSImage alloc] initWithContentsOfFile:imageFileName];
    }
	
    if([name hasSuffix:@"chanceflurries"])
        imageName = @"Flurries.tiff";
    else if([name hasSuffix:@"chancerain"])
        imageName = @"Rain.tiff";
    else if([name hasSuffix:@"chancesleat"])
        imageName = @"Sleet.tiff";
    else if([name hasSuffix:@"chancesnow"])
        imageName = @"Snow.tiff";
    else if([name hasSuffix:@"chancetstorms"])
        imageName = @"Thunderstorm.tiff";
    else if([name hasSuffix:@"clear"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Moon.tiff";
        else
            imageName = @"Sun.tiff";
    }
    else if([name hasSuffix:@"cloudy"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Cloudy.tiff";
        else
            imageName = @"Cloudy.tiff";
    }
    else if([name hasSuffix:@"flurries"])
        imageName = @"Flurries.tiff";
    else if([name hasSuffix:@"hazy"])
        imageName = @"Hazy.tiff";
    else if([name hasSuffix:@"mostlycloudy"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Moon-Cloud-2.tiff";
        else
            imageName = @"Sun-Cloud-2.tiff";
    }
    else if([name hasSuffix:@"mostlysunny"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Moon-Cloud-1.tiff";
        else
            imageName = @"Sun-Cloud-1.tiff";
    }
    else if([name hasSuffix:@"partlycloudy"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Moon-Cloud-1.tiff";
        else
            imageName = @"Sun-Cloud-1.tiff";
    }
    else if([name hasSuffix:@"partlysunny"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Moon-Cloud-2.tiff";
        else
            imageName = @"Sun-Cloud-2.tiff";
    }
    else if([name hasSuffix:@"rain"])
        imageName = @"Rain.tiff";
    else if([name hasSuffix:@"sleat"])
        imageName = @"Sleet.tiff";
    else if([name hasSuffix:@"snow"])
        imageName = @"Snow.tiff";
    else if([name hasSuffix:@"sunny"])
    {
        if([name hasPrefix:@"nt"])
            imageName = @"Moon.tiff";
        else
            imageName = @"Sun.tiff";
    }
    else if([name hasSuffix:@"tstorms"])
        imageName = @"Thunderstorm.tiff";
    else if([name hasSuffix:@"unknown"])
        imageName = @"Unknown.tiff";
    else
        imageName = @"Unknown.tiff";
    
    return imageForName(imageName,dock);
} // ImageForString

+ (BOOL)validDataInString:(NSString *)string stringLength:(int)stringLength withLastRange:(NSRange)range
{
    NSString *temp;
	
    temp = [[self class] getStringWithLeftBound:@">"
									 rightBound:@"</td>"
										 string:string
										 length:stringLength
									  lastRange:&range];
	
    return (([temp rangeOfString:@"  - "]).location == NSNotFound);
}

- (BOOL)loadWeatherData
{
    if(![super loadWeatherData])
    {
        weatherData = nil;
        return NO;
    }
	
    NSURL *url;
    //NSData *data;
    NSString *string;
    NSRange lastRange;
    int stringLength;
    NSString *temp;
    //NSCalendarDate *d = [NSCalendarDate calendarDate];
    
    Class class = [self class];
	
	// If I could figure out when and where this code string is initialized, I would probably
	// do the "assert leading slash" thang, prior to adding it to the dictionary.
	// Doing it here just means that a bad string gets corrected over and over again _RAM
	NSString *weatherQueryURL = [NSString stringWithFormat:@"http://www.wunderground.com%s%@", (('/' == [code characterAtIndex:0]) ? "" : "/"), code];
    url = [NSURL URLWithString:[weatherQueryURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
    //string = [[[NSString alloc] initWithContentsOfURL:url] autorelease];
    
    //NSData *data = [[MEWeatherModuleParser sharedInstance] loadDataFromWebsite:[NSString stringWithFormat:@"http://www.wunderground.com%@",code]];
	
    //string = [[[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]] autorelease];
    string = [[MEWeatherModuleParser sharedInstance] stringFromWebsite: url spacesOnly: NO];	// v1.3.0a _RAM
	
	if(!string)
        return NO;
	
    stringLength = [string length];
    
    if(!stringLength)
        return NO;
	
    lastRange = NSMakeRange(0,stringLength);
    NSMutableDictionary *lastWeather = weatherData;
    weatherData = [[NSMutableDictionary alloc] initWithCapacity:0];
    [weatherData setObject:@"Today" forKey:@"Date"];
    
    [weatherData setObject:[url absoluteString] forKey:@"Weather Link"];
    
    //just moving down the file
	/*    temp = [class getStringWithLeftBound:@"<!-- Time Bar -->"
	 rightBound:@"</td>"
	 string:string
	 length:stringLength
	 lastRange:&lastRange];
	 */
	
	temp = [class getStringWithLeftBound:@"<img src="
							  rightBound:@"thumb_t.jpg"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
	
	if(temp)
	{
		temp = [NSString stringWithFormat:@"%@thumb_t.jpg",temp];
		[weatherData setObject:temp forKey:@"Radar Image"];
	}
    
    //Weather Alert!  Weather Alert!
	[class getStringWithLeftBound:@"Active"
					   rightBound:@"Advisor"
						   string:string
						   length:stringLength
						lastRange:&lastRange];
	
    //we have advisories!
	/* I don't think this works */
    if(lastRange.location != NSNotFound && lastRange.location < stringLength && [string characterAtIndex:lastRange.location] == 'y')
    {
        temp = [class getStringWithLeftBound:@"<TD>"
								  rightBound:@"</td>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
		
        NSMutableArray *alertArray = [NSMutableArray array];
        [weatherData setObject:alertArray forKey:@"Weather Alert"];
		
        while(1)
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            int subLength = [temp length];
            NSRange subRange = NSMakeRange(0,subLength);
            
            NSString *sub = [class getStringWithLeftBound:@"<NOBR><a href=\"#"
											   rightBound:@"\""
												   string:temp
												   length:subLength
												lastRange:&subRange];
			
            if(!sub)
                break;
			
            //sub should now be something like SVR
            
            NSString *title = [class getStringWithLeftBound:@">"
												 rightBound:@"<"
													 string:temp
													 length:subLength
												  lastRange:&subRange];
            
            if(!title)
                break;
			
            temp = [temp substringWithRange:NSMakeRange(subRange.location,subLength-subRange.location)];
            [alertArray addObject:dict];
            
            [dict setObject:title forKey:@"title"];
            
            subRange = lastRange;
            sub = [class getStringWithLeftBound:[NSString stringWithFormat:@"<a name=\"%@\">",sub]
									 rightBound:@"</table>"
										 string:string
										 length:stringLength
									  lastRange:&subRange];
			
            if(!sub)
                break;
			
            subLength = [sub length];
            subRange = NSMakeRange(0,subLength);
            
            sub = [class getStringWithLeftBound:@"<p></p>"
									 rightBound:@"</td>"
										 string:sub
										 length:subLength
									  lastRange:&subRange];
            
            if(!sub)
                break;
			
            sub = [class replaceString:@"<p></p>" withString:@"" forString:sub];
            sub = [class replaceString:@"</font></p>" withString:@"" forString:sub];
            
            NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t\f\v"];
            sub = [sub stringByTrimmingCharactersInSet:set];
            
            if(sub)
            {
                sub = [NSString stringWithFormat:@"(Wunderground): %@",sub];
                [dict setObject:sub forKey:@"description"];
            }
        }
    } /* Weather alert */
    
    //just moving down the file
	[class getStringWithLeftBound:@"<img src=\"http://icons.wunderground.com/graphics/conds/"
					   rightBound:@">"
						   string:string
						   length:stringLength
						lastRange:&lastRange];
	
    temp = [class getStringWithLeftBound:@">"
							  rightBound:@"<"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
                  
    NSRange tempRange;
    
    if([temp isEqualToString:@"Temperature"])
    {
        //get the current temp
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Temperature"];
        }
        //end getting current temp
        
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
                  
    if([temp isEqualToString:@"Windchill"])
    {
		
        //get the current wind chill
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Wind Chill"];
        }
        //end getting current wind chill
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
		
    }

	// In warmer weather, there is no Wind Chill. Instead we get HeatIndex data _RAM
    if([temp isEqualToString:@"HeatIndex"])
    {
		
        //get the current heat index
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"]) {
				NSLog(@"Heat Index: %@", temp);	// _RAM debug
			//[weatherData setObject:temp forKey:@"Heat Index"];	// Heat Index not yet in our list of supported keys _RAM
			}
        }
        //end getting current heat index
		
        //just moving down the file
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
		
    }

    if([temp isEqualToString:@"Humidity"])
    {                                                        
        //get the current humidity
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Humidity"];
        }
        //end getting current humidity
        
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
                  
    if([temp isEqualToString:@"Dew Point"])
    {
        //get the current dew point
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Dew Point"];
        }
        //end getting current dew point
        
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
     
    
    if([temp isEqualToString:@"Wind"])
    {
        //get the current wind
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            NSString *theTemp = [class getStringWithLeftBound:@"<b>"
												   rightBound:@"</b>"
													   string:temp
													   length:tempRange.length
													lastRange:&tempRange];
			
            if(theTemp && ![theTemp hasPrefix:@"N/A"])
            {
                NSString *lastReading = theTemp;
				
                NSString *dir = [NSString stringWithFormat:@"%@ at ",theTemp];
                
                theTemp = [class getStringWithLeftBound:@"<b>"
											 rightBound:@"</b>"
												 string:temp
												 length:tempRange.length
											  lastRange:&tempRange];
				
                if(theTemp && ![theTemp hasPrefix:@"N/A"])
                    [weatherData setObject:[NSString stringWithFormat:@"%@%@ mph",dir,theTemp] forKey:@"Wind"];
                else
                    [weatherData setObject:lastReading forKey:@"Wind"];
            }
        }
        //end getting current wind
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    
    if([temp isEqualToString:@"Wind Gust"])
    {
        //wind gusts?
		
        //just moving down the file
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
                  
    if([temp isEqualToString:@"Pressure"])
    {
        //get the current pressure
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:[NSString stringWithFormat:@"%@ inches",temp] forKey:@"Pressure"];
        }
        //end getting current pressure
        
        
        //just moving down the file
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    
    if([temp isEqualToString:@"Conditions"])
    {              
        //get the current forecast
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Forecast"];
        }
        //end getting current forecast
        
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    if([temp isEqualToString:@"Visibility"])
    {
        //get the current visibility
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:[NSString stringWithFormat:@"%@ miles",temp] forKey:@"Visibility"];
        }
        //end getting current visibility
        
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    if([temp isEqualToString:@"UV"])
    {
        //get the current uv
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"UV Index"];
        }
        //end getting current uv
        
        
        //just moving down the file
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    if([temp hasPrefix:@"Clouds"])
    {
        //get the current clouds
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"td"
									  rightBound:@"/td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
			
            tempRange = NSMakeRange(0,[temp length]);
            temp = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempRange.length
									   lastRange:&tempRange];
			
            if(temp && [temp length] && ![temp hasPrefix:@"N/A"])
            {
                int prefix = [temp characterAtIndex:0];
                
                if(prefix >= 48 && prefix <=57)
                    temp = [NSString stringWithFormat:@"%.1f miles", [temp floatValue]/5280.0];
				
                [weatherData setObject:temp forKey:@"Clouds"];
            }
        }
        //end getting current clouds
        
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    if([temp isEqualToString:@"Max Temperature"])
    {
        //get the max temp
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<b>Normal: "
									  rightBound:@"&"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            if(temp && [temp length] && ![temp hasPrefix:@"N/A"])
            {
                [weatherData setObject:temp forKey:@"Normal Hi"];
                temp = [class getStringWithLeftBound:@"<b>Record: "
										  rightBound:@"&"
											  string:string
											  length:stringLength
										   lastRange:&lastRange];
                if(temp && [temp length] && ![temp hasPrefix:@"N/A"])
                {
                    [weatherData setObject:temp forKey:@"Record Hi"];
                }
            }
        }
        //end getting max temp
        
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    if([temp isEqualToString:@"Min Temperature"])
    {
        //get the min temp
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<b>Normal: "
									  rightBound:@"&"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            if(temp && [temp length] && ![temp hasPrefix:@"N/A"])
            {
                [weatherData setObject:temp forKey:@"Normal Low"];
                temp = [class getStringWithLeftBound:@"<b>Record: "
										  rightBound:@"&"
											  string:string
											  length:stringLength
										   lastRange:&lastRange];
                if(temp && [temp length] && ![temp hasPrefix:@"N/A"])
                {
                    [weatherData setObject:temp forKey:@"Record Low"];
                }
            }
        }
        //end getting min temp
        
    }
    
	[class getStringWithLeftBound:@"<b>Astronomy"
					   rightBound:@">"
						   string:string
						   length:stringLength
						lastRange:&lastRange];
	[class getStringWithLeftBound:@"<tr BGCOLOR="
					   rightBound:@"<"
						   string:string
						   length:stringLength
						lastRange:&lastRange];
    temp = [class getStringWithLeftBound:@">"
							  rightBound:@"<"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
    
    if([temp isEqualToString:@"Length of Day"])
    {
        //get the length of day
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td align=right>"
									  rightBound:@"</td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            temp = [class replaceString:@"<b>" withString:@"" forString:temp]; 
            temp = [class replaceString:@"</b>" withString:@"" forString:temp]; 
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Length of Day"];
            //end getting length of day
        }
        
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    
    if([temp isEqualToString:@"Sunrise"])
    {
        //get the sunrise
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td align=right>"
									  rightBound:@"</td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            temp = [class replaceString:@"<b>" withString:@"" forString:temp]; 
            temp = [class replaceString:@"</b>" withString:@"" forString:temp]; 
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Sunrise"];
            //end getting sunrise
        }
        
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    
    if([temp isEqualToString:@"Sunset"])
    {
        //get the sunset
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            temp = [class getStringWithLeftBound:@"<td align=right>"
									  rightBound:@"</td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            temp = [class replaceString:@"<b>" withString:@"" forString:temp]; 
            temp = [class replaceString:@"</b>" withString:@"" forString:temp]; 
            if(temp && ![temp hasPrefix:@"N/A"])
                [weatherData setObject:temp forKey:@"Sunset"];
            //end getting sunset
        }
        
        [class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    
    if([temp isEqualToString:@"Moon Rise"])
    {
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            //get the moon rise
            temp = [class getStringWithLeftBound:@"<td align=right>"
									  rightBound:@"</td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            temp = [class replaceString:@"<b>" withString:@"" forString:temp]; 
            temp = [class replaceString:@"</b>" withString:@"" forString:temp]; 
            if(temp && ![temp hasPrefix:@"N/A"])
            {
                [weatherData setObject:temp forKey:@"Moon Rise"];
            }
            //end getting moon rise
        }
		
		[class getStringWithLeftBound:@"<tr BGCOLOR="
						   rightBound:@"<"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
        temp = [class getStringWithLeftBound:@">"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    
    if([temp isEqualToString:@"Moon Set"])
    {
        if([class validDataInString:string stringLength:stringLength withLastRange:lastRange])
        {
            //get the moon set
			temp = [class getStringWithLeftBound:@"<td align=right>"
									  rightBound:@"</td>"
										  string:string
										  length:stringLength
									   lastRange:&lastRange];
            temp = [class replaceString:@"<b>" withString:@"" forString:temp]; 
            temp = [class replaceString:@"</b>" withString:@"" forString:temp]; 
            if(temp && ![temp hasPrefix:@"N/A"])
            {
                [weatherData setObject:temp forKey:@"Moon Set"];
            }
            //end getting moon set
        }
    }
    
    //get the moon phase
    temp = [class getStringWithLeftBound:@"img src=\""
							  rightBound:@"\""
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
    if(temp)
        [weatherData setObject:temp forKey:@"Moon Phase"];
    
    int i = 0;
    int j = 0;
    
    NSMutableArray *forecastArray = [NSMutableArray array];
    while((temp = [class getStringWithLeftBound:@"BGCOLOR=#C8C8C8"
									 rightBound:@"</table>"
										 string:string
										 length:stringLength
									  lastRange:&lastRange]))
    {
        int tempLength = [temp length];
        NSRange tempRange = NSMakeRange(0,tempLength);
        
		
        for (i=0; i<11 && temp!=nil; i++)
        {
            NSMutableDictionary *forecastDict = [NSMutableDictionary dictionary];
			
            NSString *imag;
            NSString *date;
            NSString *temporary;
			
            (imag = [class getStringWithLeftBound:@"<td align=right><img src=\""
									   rightBound:@"\""
										   string:temp
										   length:tempLength
										lastRange:&tempRange]) ||
				(imag = [class getStringWithLeftBound:@"<td align=right bgcolor=\"#ffffff\"><img src=\""
										   rightBound:@"\""
											   string:temp
											   length:tempLength
											lastRange:&tempRange]) ;
			
            date = [class getStringWithLeftBound:@"<b>"
									  rightBound:@"</b>"
										  string:temp
										  length:tempLength
									   lastRange:&tempRange];
			
            if(!date)
                break;
            //else if([date isEqualToString:@"Now"])
            //{
            //    i--;
            //    continue;
            //}
				else if(i == 0 && [date hasSuffix:@"ight"])
					i++;
                
				if(![weatherData objectForKey:@"Weather Image"] && imag)
					[weatherData setObject:imag forKey:@"Weather Image"];
                
				[forecastDict setObject:date forKey:@"Forecast - Date"];
                
				if(imag)
					[forecastDict setObject:imag forKey:@"Forecast - Icon"];
				
				temporary = [class getStringWithLeftBound:@"r>"
											   rightBound:@"</td>"
												   string:temp
												   length:tempLength
												lastRange:&tempRange];
				
				temporary = [class replaceString:@"\n" withString:@" " forString:temporary];              
				NSArray *components = [temporary componentsSeparatedByString:@". "];
				NSEnumerator *compEnum = [components objectEnumerator];
				NSString *comp;
				
				comp = [compEnum nextObject];
				if(comp)
					[forecastDict setObject:comp forKey:@"Forecast - Forecast"];
				
				while(comp = [compEnum nextObject])
				{
					comp = [class stripSuffix:@"." forString:comp];
					NSArray *words = [comp componentsSeparatedByString:@" "];
					
					//now what?
					
					//precipitation is now by "percent"
					//hi temp is know by "highs" or "Highs"
					//low temp is known by "lows" or "Lows"
					//	hi and low can be combined in same line
					//wind is known by "winds"
					
					NSInteger index;
					char percent = '%';
					
					if((index = [words indexOfObject:@"percent"]) != NSNotFound && index > 0)
					{
						NSString *percip = [NSString stringWithFormat:@"%@ %c", [words objectAtIndex:index-1], percent];
						[forecastDict setObject:percip forKey:@"Forecast - Precipitation"];
					}
					else if([words indexOfObject:@"winds"] != NSNotFound)
					{
						if((index = [words indexOfObject:@"to"]) != NSNotFound)
						{
							NSMutableArray *compArray = [NSMutableArray arrayWithArray:words];
							[compArray insertObject:@"mph" atIndex:index];
							comp = [compArray componentsJoinedByString:@" "];
						}
						
						[forecastDict setObject:comp forKey:@"Forecast - Wind"];
                        
					}
					else if((index = [words indexOfObject:@"\n\tHigh:"]) != NSNotFound && 
							(index = [words indexOfObject:@"F.\t\n\t\n"]) != NSNotFound && 
							index > 0)
					{
						temporary = [words objectAtIndex:index-1];
						
						if(temporary)
						{
							temporary = [class stripSuffix:@"&deg;" forString:temporary];
							
							if(temporary && ![temporary hasPrefix:@"N/A"])
							{
								[forecastDict setObject:temporary forKey:@"Forecast - Hi"];
							}
						}
					}
					else if((index = [words indexOfObject:@"\n\tLow:"]) != NSNotFound && 
							(index = [words indexOfObject:@"F.\t\n\t\n"]) != NSNotFound && 
							index > 0)
					{
						temporary = [words objectAtIndex:index-1];
						
						if(temporary)
						{
							temporary = [class stripSuffix:@"&deg;" forString:temporary];
							
							if(temporary && ![temporary hasPrefix:@"N/A"])
							{
								[forecastDict setObject:temporary forKey:@"Forecast - Low"];
							}
						}
					}
					else
					{
						words = [comp componentsSeparatedByString:@" and "];
						NSEnumerator *yaEnum = [words objectEnumerator];
						NSString *moreComps;
						
						while(moreComps = [yaEnum nextObject])
						{
							words = [moreComps componentsSeparatedByString:@" "];
							
							if([words indexOfObject:@"highs"]!=NSNotFound || [words indexOfObject:@"Highs"]!=NSNotFound || [words indexOfObject:@"High"]!=NSNotFound || [words indexOfObject:@"High"]!=NSNotFound)
							{
								if((index = [words indexOfObject:@"mid"]) != NSNotFound || (index = [words indexOfObject:@"near"]) != NSNotFound || (index = [words indexOfObject:@"upper"]) != NSNotFound || (index = [words indexOfObject:@"lower"]) != NSNotFound || (index = [words indexOfObject:@"middle"]) != NSNotFound)
								{
									if(index+1 < [words count])
									{
										NSString *candidate = [words objectAtIndex:index+1];
										
										// 30s, 20s, teens...
										
										candidate = [class stripSuffix:@"s" forString:candidate];
										if([candidate isEqualToString:@"teen"])
											candidate = @"10";
                                        
										if([candidate hasSuffix:@"0"])
										{
											candidate = [class stripSuffix:@"0" forString:candidate];
                                            
											NSString *phrase = [words objectAtIndex:index];
											if([phrase hasPrefix:@"mid"])
												candidate = [NSString stringWithFormat:@"%@5",candidate];
											else if([phrase isEqualToString:@"near"])
												candidate = [NSString stringWithFormat:@"%@0",candidate];
											else if([phrase isEqualToString:@"upper"])
												candidate = [NSString stringWithFormat:@"%@8",candidate];
											else if([phrase isEqualToString:@"lower"])
												candidate = [NSString stringWithFormat:@"%@2",candidate];
											else
												candidate = [NSString stringWithFormat:@"%@0",candidate];
										}
										
										if(candidate)
										{
											[forecastDict setObject:candidate
															 forKey:@"Forecast - Hi"];
										}
									}
								}
								
							}
							else if([words indexOfObject:@"lows"]!=NSNotFound || [words indexOfObject:@"Lows"]!=NSNotFound || [words indexOfObject:@"low"]!=NSNotFound || [words indexOfObject:@"Low"]!=NSNotFound)
							{
								if((index = [words indexOfObject:@"mid"]) != NSNotFound || (index = [words indexOfObject:@"near"]) != NSNotFound || (index = [words indexOfObject:@"upper"]) != NSNotFound || (index = [words indexOfObject:@"lower"]) != NSNotFound || (index = [words indexOfObject:@"middle"]) != NSNotFound)
								{
									if(index+1 < [words count])
									{
										NSString *candidate = [words objectAtIndex:index+1];
										
										// 30s, 20s, teens...
										
										candidate = [class stripSuffix:@"s" forString:candidate];
										if([candidate isEqualToString:@"teen"])
											candidate = @"10";
                                        
										if([candidate hasSuffix:@"0"])
										{
											candidate = [class stripSuffix:@"0" forString:candidate];
                                            
											NSString *phrase = [words objectAtIndex:index];
											if([phrase hasPrefix:@"mid"])
												candidate = [NSString stringWithFormat:@"%@5",candidate];
											else if([phrase isEqualToString:@"near"])
												candidate = [NSString stringWithFormat:@"%@0",candidate];
											else if([phrase isEqualToString:@"upper"])
												candidate = [NSString stringWithFormat:@"%@8",candidate];
											else if([phrase isEqualToString:@"lower"])
												candidate = [NSString stringWithFormat:@"%@2",candidate];
											else
												candidate = [NSString stringWithFormat:@"%@0",candidate];
										}
                                        
										if(candidate)
										{
											[forecastDict setObject:candidate 
															 forKey:@"Forecast - Low"];
										}
									}
								}
								
							}
						}
					}
				}
				
				[forecastDict setObject:self forKey:@"Weather Module"];
				[forecastArray addObject:forecastDict];
				
				j++;
        }
    }
    [weatherData setObject:forecastArray forKey:@"Forecast Array"];
    
    
    //NSCalendarDate *d = [NSCalendarDate calendarDate];
    //[weatherData setObject:[d descriptionWithCalendarFormat:@"%a, %b %d %I:%M %p"] forKey:@"Last Load"];
    [weatherData setObject:[class dateInfoForCalendarDate:[NSCalendarDate calendarDate]] forKey:@"Last Update"];
    if([weatherData count] > 5)
    {
        supplyingOldData = NO;
    }
    else
    {
		NSLog(@"Only obtained %lu datapoints, re-using old data", [weatherData count]);
        supplyingOldData = YES;
        weatherData = lastWeather;
    }
    
	return YES;
}

/*+ (NSArray *)perfromCitySearch:(NSString *)search info:(NSString *)information
{
    NSURL *url;
    //NSData *data;
    
    NSRange lastRange;
    NSString *string;
    int stringLength;
    NSString *temp;
    NSMutableArray *array = [NSMutableArray array];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    search = [self replaceString:@" " withString:@"%20" forString:search];
    
    url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.wunderground.com/cgi-bin/findweather/getForecast?query=%@",search]];
																 //data = [url resourceDataUsingCache:NO];
    
    //if(!data)
	//return nil;
    
    //string = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
    string = [[[NSString alloc] initWithContentsOfURL:url] autorelease];
    
    if(!string)
        return nil;
	
    stringLength = [string length];
    
    if(!stringLength)
        return nil;
    
    lastRange = NSMakeRange(1,stringLength-1);
    
    // Let's see if this resolved right away
    temp = [self getStringWithLeftBound:@"Weather Underground: "
							 rightBound:@" Forecast</title>"
								 string:string
								 length:stringLength
							  lastRange:&lastRange];
	
    
    //then we resolved right away
    if(temp && lastRange.location)
    {
        [dict setObject:temp forKey:@"city"];
        lastRange = NSMakeRange(1,stringLength-1);
        
        //get the loc
        temp = [self getStringWithLeftBound:@"URL=/"
								 rightBound:@"\">"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            [dict setObject:temp forKey:@"code"];
			
            if(information)
                [dict setObject:information forKey:@"info"];
			
            [array addObject:dict];
            return array;
        }
        
        return [NSArray array];
    }
    
    lastRange = NSMakeRange(1,stringLength-1);
    //just moving down the file
    [self getStringWithLeftBound:@"<tr bgcolor=#"
							 rightBound:@">"
								 string:string
								 length:stringLength
							  lastRange:&lastRange];
    
    while(lastRange.location)
    {
        dict = [NSMutableDictionary dictionary];
		
        temp = [self getStringWithLeftBound:@"<tr bgcolor=#"
								 rightBound:@"a hr"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
		
        if(!temp)
            break;
		
        temp = [self getStringWithLeftBound:@"\""
								 rightBound:@"\""
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
		
        if(temp)
            [dict setObject:temp forKey:@"code"];
        else
            break;
		
        temp = [self getStringWithLeftBound:@">"
								 rightBound:@"</a>"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
        if(temp)
            [dict setObject:temp forKey:@"city"];
        else
            break;
		
        if(information)
            [dict setObject:information forKey:@"info"];
		
        [array addObject:dict];
    }
    
    return array;
}*/

@end


@implementation MENWSCom

+ (NSString *)sourceName
{
    return @"National Weather Service";
}

+ (NSArray *)supportedKeys
{
    return [NSArray arrayWithObjects:nil];
    /*
    return [NSArray arrayWithObjects:@"Weather Image",
		@"Weather Link",
		@"Temperature",
		@"Forecast",
		@"Humidity",
		@"Wind",
		@"Pressure",
		@"Dew Point",
		@"Visibility",
		@"Last Update",
		@"Forecast - Date",
        @"Forecast - Forecast",
//		@"Forecast - Hi",
		@"Forecast - Low",
		@"Wind Chill",
		@"Precipitation",
		@"Forecast - Icon",
//		@"Forecast - Wind",
		@"Forecast - Precipitation",
		@"Hi",
		@"Low",
		@"Radar Image",
		@"Weather Alert",
		@"Weather Alert Link",
		nil];
     */
}

+ (NSArray *)supportedInfos
{
    return [NSArray arrayWithObject:@"United States"];
}

- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;
{
    NSImage *img = nil;
    
    NSString *name = [[string lastPathComponent] stringByDeletingPathExtension];
    NSString *imageName;
    
    if([key isEqualToString:@"Moon Phase"])
    {
        img = [[NSImage alloc] initWithContentsOfFile:@"/Library/Application Support/Meteo/Weather Status/Moon.tiff"];
        
        if(!img)
            img = [[NSImage alloc] initWithContentsOfFile:[@"~/Library/Application Support/Meteo/Weather Status/Moon.tiff" stringByExpandingTildeInPath]];
        
        if(img)
            return img;
    }
    
    if([name hasSuffix:@"nfew"] || [name isEqualToString:@"hi_nclr"] || [name isEqualToString:@"hi_nmoclr"] || 
       [name hasSuffix:@"nskc"] || [name isEqualToString:@"sunnyn"])
        imageName = @"Moon.tiff";
    else if([name hasPrefix:@"nsct"] || [name isEqualToString:@"hi_nptcldy"] || [name isEqualToString:@"nhiclouds"] || 
            [name isEqualToString:@"pcloudyn"])
        imageName = @"Moon-Cloud-1.tiff";
    else if([name hasSuffix:@"nbkn"] || [name isEqualToString:@"hi_nmocldy"] || [name hasSuffix:@"mcloudyn"] || [name isEqualToString:@"tcu"])
        imageName = @"Moon-Cloud-2.tiff";
    else if([name hasSuffix:@"few"] || [name isEqualToString:@"br"] || [name isEqualToString:@"fair"] || 
            [name isEqualToString:@"hi_clr"] || [name hasSuffix:@"skc"] || [name hasPrefix:@"hot"] || 
            [name isEqualToString:@"sunny"])
        imageName = @"Sun.tiff";
    else if([name hasSuffix:@"sct"] || [name isEqualToString:@"hi_moclr"] || [name isEqualToString:@"hi_ptcldy"] || 
            [name isEqualToString:@"pcloudy"])
        imageName = @"Sun-Cloud-1.tiff";
    else if([name hasSuffix:@"bkn"] || [name isEqualToString:@"hi_mocldy"] || [name isEqualToString:@"mcloudy"])
        imageName = @"Sun-Cloud-2.tiff";
    else if([name hasSuffix:@"ovc"] || [name hasPrefix:@"cloudy"] || [name isEqualToString:@"fu"] || 
            [name isEqualToString:@"hiclouds"])
        imageName = @"Cloudy.tiff";
    else if([name hasPrefix:@"fog"] || [name hasPrefix:@"du"] || [name hasSuffix:@"fg"] ||
            [name isEqualToString:@"mist"] || [name isEqualToString:@"smoke"])
        imageName = @"Hazy.tiff";
    else if([name hasPrefix:@"ra"] || [name hasSuffix:@"drizzle"] || [name isEqualToString:@"freezingrain"] || 
            [name hasPrefix:@"fz"] || [name hasSuffix:@"shwrs"] || [name hasPrefix:@"nra"] || 
            [name isEqualToString:@"showers"] || [name hasPrefix:@"shra"] || [name isEqualToString:@"sleet"])
        imageName = @"Rain.tiff";
    else if([name isEqualToString:@"none"] || [name isEqualToString:@"na"])
        imageName = @"Unknow.tiff";
    else if([name hasSuffix:@"tsra"] || [name hasPrefix:@"ntsra"] || [name hasPrefix:@"tstorm"])
        imageName = @"Thunderstorm.tiff";
    else if([name isEqualToString:@"flurries"])
        imageName = @"Flurries.tiff";
    else if([name hasSuffix:@"sn"] || [name isEqualToString:@"blizzard"] || [name isEqualToString:@"blowingsnow"] ||
            [name hasSuffix:@"mix"] || [name hasPrefix:@"snow"])
        imageName = @"Snow.tiff";
    else if([name hasPrefix:@"cold"] || [name hasSuffix:@"wind"] || [name hasPrefix:@"wind"])
        imageName = @"Wind.tiff";
    else if([name isEqualToString:@"nsvrtsra"] || [name isEqualToString:@"hurr"] || [name hasSuffix:@"tor"] || 
            [name isEqualToString:@"wswatch"] || [name isEqualToString:@"wswarning"])
        imageName = @"Alert.tiff";
    else
        imageName = @"Unknown.tiff";
    
    if(string && !(img = imageForName(imageName,dock)))
    {
        if(dock)
            return nil;
		
        //NSLog(@"%@ : %@",name,imageName);
		
		NSData *dat = [[NSURL URLWithString:[string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
					   resourceDataUsingCache:YES];
        if(dat)
            img = [[NSImage alloc] initWithData:dat];
    }
    
    return img;
}


- (BOOL)loadWeatherData
{
#define NUM_NWS_FORECAST_ITEMS	8
    if(![super loadWeatherData])
    {
        weatherData = nil;
        return NO;
    }
    NSURL *url;
    //NSData *data;
    NSString *string;
    NSRange lastRange;
    int stringLength;
    NSString *temp;
    //NSCalendarDate *d = [NSCalendarDate calendarDate];
    
    Class class = [self class];
    
    [super loadWeatherData];
	
	NSString *weatherQueryURL = [NSString stringWithFormat:@"http://www.crh.noaa.gov/forecasts/%@",code];
																  //url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.crh.noaa.gov/data/forecasts/%@",code]];
    url = [NSURL URLWithString:[weatherQueryURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	string = [[NSString alloc] initWithContentsOfURL:url
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
    
    if(!string)
        return NO;
	
    stringLength = [string length];
    
    if(!stringLength)
        return NO;
	
    lastRange = NSMakeRange(0,stringLength);
    NSMutableDictionary *lastWeather = weatherData;
    weatherData = [[NSMutableDictionary alloc] initWithCapacity:0];
    [weatherData setObject:@"Today" forKey:@"Date"];
    
    [weatherData setObject:[url absoluteString] forKey:@"Weather Link"];
	
    //begin getting forecast forecast and forecast image
    int i;
    
    [class getStringWithLeftBound:@"<tr valign=\"top\" align=\"center\">"
					   rightBound:@"<tr valign=\"top\" align=\"center\">"
						   string:string
						   length:stringLength
						lastRange:&lastRange];
    
    NSMutableArray *forecastArray = [NSMutableArray array];
    NSMutableDictionary *forecastDict;
    
	// why does he grab 9 items here? there are only 8 _RAM
	//for(i=0; i<9; i++)
	for(i=0; i<NUM_NWS_FORECAST_ITEMS; i++)
    {
        forecastDict = [NSMutableDictionary dictionary];
		
        temp = [class getStringWithLeftBound:@"<img src=\""
								  rightBound:@"\" alt"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            [forecastDict setObject:temp forKey:@"Forecast - Icon"];
            
            if(![weatherData objectForKey:@"Weather Image"])
                [weatherData setObject:temp forKey:@"Weather Image"];
        }
        
		
        temp = [class getStringWithLeftBound:@"<br>"
								  rightBound:@"</td>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            temp = [class replaceString:@"<BR>" withString:@" " forString:temp];
			
            if(temp)
            {
                [forecastDict setObject:temp forKey:@"Forecast - Forecast"];
            }
        }
        
        [forecastArray addObject:forecastDict];
    }
    //end getting forecast forecast
    [weatherData setObject:forecastArray forKey:@"Forecast Array"];
    
    
    //begin getting the hi/low forecast
    NSEnumerator *forecastEnumerator = [forecastArray objectEnumerator];
	// why does he grab 9 items here? there are only 8 _RAM
	//for(i=0; i<9; i++)
	for(i=0; i<NUM_NWS_FORECAST_ITEMS; i++)
    {
        temp = [class getStringWithLeftBound:@"<td>"
								  rightBound:@"<"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            NSString *daKey = nil;
			
            if([temp hasPrefix:@"Hi"])
                daKey = @"Hi";
            else if([temp hasPrefix:@"Lo"])
                daKey = @"Low";
			
            if(daKey)
            {
                temp = [class getStringWithLeftBound:@">"
										  rightBound:@"&"
											  string:string
											  length:stringLength
										   lastRange:&lastRange];
				
                if(temp && lastRange.location)
                {
                    forecastDict = [forecastEnumerator nextObject];
                    [forecastDict setObject:temp forKey:[NSString stringWithFormat:@"Forecast - %@",daKey]];
                }
            }
        }
    }
    //end getting hi/low forecast
	
    
    temp = [class getStringWithLeftBound:@"</a>Hazardous weather condition(s):"
							  rightBound:@"<span class=\"warn\">"//@" <font " _RAM
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
	
    if(temp)
    {
        NSRange tempRange = NSMakeRange(0,[temp length]);
        
        NSString *alertStr = [class getStringWithLeftBound:@"><a href=\""
												rightBound:@"\">"
													string:temp
													length:tempRange.length
												 lastRange:&tempRange];
		
        if(alertStr)
        {
            
            NSString *loadedAlertString = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:[alertStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                                         encoding:NSUTF8StringEncoding
                                                                            error:nil];
            
            if(loadedAlertString)
            {
                alertStr = loadedAlertString;
                int alertStrLength = [alertStr length];
                tempRange = NSMakeRange(0,alertStrLength);
                NSMutableArray *alertArray = [NSMutableArray array];
                
                while(1)
                {
                    NSString *subStr = [class getStringWithLeftBound:@"<pre>"
														  rightBound:@"$$"
															  string:alertStr
															  length:alertStrLength
														   lastRange:&tempRange];
					
                    if(!subStr)
                        break;
					
                    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"\n\r\t\f\v"];
                    subStr = [subStr stringByTrimmingCharactersInSet:set];
                    
                    subStr = [NSString stringWithFormat:@"(NWS): %@",subStr];
                    
                    if(subStr)
                    {
                        NSMutableDictionary *diction = [NSMutableDictionary dictionary];
                        [diction setObject:@"Weather Alert" forKey:@"title"];
                        [diction setObject:subStr forKey:@"description"];
                        [alertArray addObject:diction];
                    }
                }
                
                if([alertArray count])
                    [weatherData setObject:alertArray forKey:@"Weather Alert"];
            }
			
        }
    }
    
    //moving down the file
	[class getStringWithLeftBound:@"Detailed Forecast"	// this won't be found _RAM
					   rightBound:@"br>"
						   string:string
						   length:stringLength
						lastRange:&lastRange];
	
    forecastEnumerator = [forecastArray objectEnumerator];
	// why does he grab 9 items here? there are only 8 _RAM
	//for(i=0; i<9; i++)
	for(i=0; i<NUM_NWS_FORECAST_ITEMS; i++)
    {
        NSString *date;
		
        date = [class getStringWithLeftBound:@"<b>"
								  rightBound:@"</b>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
		
        if(!date)
            break;
		
        if(i==0 && [date hasSuffix:@"ight"])
            i++;
		
        forecastDict = [forecastEnumerator nextObject];
        [forecastDict setObject:date forKey:@"Forecast - Date"];
        [forecastDict setObject:self forKey:@"Weather Module"];
        
        temp = [class getStringWithLeftBound:@" "
								  rightBound:@"<br>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        
        temp = [class replaceString:@"\n" withString:@" " forString:temp];
        NSArray *components = [temp componentsSeparatedByString:@". "];
        NSEnumerator *compEnum = [components objectEnumerator];
        NSString *comp;
        
        comp = [compEnum nextObject];
        if(comp)
            [forecastDict setObject:comp forKey:@"Forecast - Forecast"];
        
        while(comp = [compEnum nextObject])
        {
            comp = [class stripSuffix:@"." forString:comp];
            NSArray *words = [comp componentsSeparatedByString:@" "];
            
            //now what?
            
            //precipitation is now by "percent"
            //hi temp is know by "highs" or "Highs"
            //low temp is known by "lows" or "Lows"
            //	hi and low can be combined in same line
            //wind is known by "winds"
            
            NSInteger index;
            char percent = '%';
            
            if((index = [words indexOfObject:@"percent"]) != NSNotFound && index > 0)
            {
                NSString *part = [words objectAtIndex:index-1];
				
                if(![part length])
                    part = [words objectAtIndex:index-2];
				
                NSString *percip = [NSString stringWithFormat:@"%@ %c", part, percent];
				
                [forecastDict setObject:percip forKey:@"Forecast - Precipitation"];
            }
            else if([words indexOfObject:@"winds"] != NSNotFound)
            {
                if((index = [words indexOfObject:@"to"]) != NSNotFound)
                {
                    NSMutableArray *compArray = [NSMutableArray arrayWithArray:words];
                    [compArray insertObject:@"mph" atIndex:index];
                    comp = [compArray componentsJoinedByString:@" "];
                }
				
                [forecastDict setObject:comp forKey:@"Forecast - Wind"];
            }
            else
            {
                words = [comp componentsSeparatedByString:@" and "];
                NSEnumerator *yaEnum = [words objectEnumerator];
                NSString *moreComps;
                
                while(moreComps = [yaEnum nextObject])
                {
                    words = [moreComps componentsSeparatedByString:@" "];
                    
                    if([words indexOfObject:@"highs"]!=NSNotFound || [words indexOfObject:@"Highs"]!=NSNotFound)
                    {
                        if((index = [words indexOfObject:@"mid"]) != NSNotFound || (index = [words indexOfObject:@"near"]) != NSNotFound || (index = [words indexOfObject:@"upper"]) != NSNotFound || (index = [words indexOfObject:@"lower"]) != NSNotFound ||
						   
						   (index = [words indexOfObject:@"middle"]) != NSNotFound)
                        {
                            if(index+1 < [words count])
                            {
                                NSString *candidate = [words objectAtIndex:index+1];
                                
                                // 30s, 20s, teens...
                                
                                candidate = [class stripSuffix:@"s" forString:candidate];
                                if([candidate isEqualToString:@"teen"])
                                    candidate = @"10";
								
                                if([candidate hasSuffix:@"0"])
                                {
                                    candidate = [class stripSuffix:@"0" forString:candidate];
									
                                    NSString *phrase = [words objectAtIndex:index];
                                    if([phrase hasPrefix:@"mid"])
                                        candidate = [NSString stringWithFormat:@"%@5",candidate];
                                    else if([phrase isEqualToString:@"near"])
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                    else if([phrase isEqualToString:@"upper"])
                                        candidate = [NSString stringWithFormat:@"%@8",candidate];
                                    else if([phrase isEqualToString:@"lower"])
                                        candidate = [NSString stringWithFormat:@"%@2",candidate];
                                    else
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                }
								
                                if(candidate)
                                {
                                    if(![forecastDict objectForKey:@"Forecast - Hi"])
                                        [forecastDict setObject:candidate
														 forKey:@"Forecast - Hi"];
                                }
                            }
                        }
						
                    }
                    else if([words indexOfObject:@"lows"]!=NSNotFound || [words indexOfObject:@"Lows"]!=NSNotFound)
                    {
                        if((index = [words indexOfObject:@"mid"]) != NSNotFound || (index = [words indexOfObject:@"near"]) != NSNotFound || (index = [words indexOfObject:@"upper"]) != NSNotFound || (index = [words indexOfObject:@"lower"]) != NSNotFound ||
						   
						   (index = [words indexOfObject:@"middle"]) != NSNotFound)
                        {
                            if(index+1 < [words count])
                            {
                                NSString *candidate = [words objectAtIndex:index+1];
                                
                                // 30s, 20s, teens...
                                
                                candidate = [class stripSuffix:@"s" forString:candidate];
                                if([candidate isEqualToString:@"teen"])
                                    candidate = @"10";
								
                                if([candidate hasSuffix:@"0"])
                                {
                                    candidate = [class stripSuffix:@"0" forString:candidate];
									
                                    NSString *phrase = [words objectAtIndex:index];
                                    if([phrase hasPrefix:@"mid"])
                                        candidate = [NSString stringWithFormat:@"%@5",candidate];
                                    else if([phrase isEqualToString:@"near"])
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                    else if([phrase isEqualToString:@"upper"])
                                        candidate = [NSString stringWithFormat:@"%@8",candidate];
                                    else if([phrase isEqualToString:@"lower"])
                                        candidate = [NSString stringWithFormat:@"%@2",candidate];
                                    else
                                        candidate = [NSString stringWithFormat:@"%@0",candidate];
                                }
								
                                if(candidate)
                                {
                                    if(![forecastDict objectForKey:@"Forecast - Low"])
                                        [forecastDict setObject:candidate
														 forKey:@"Forecast - Low"];
                                }
                            }
                        }
						
                    }
                }
            }
        }
    }
    
    //get the current forecast
    temp = [class getStringWithLeftBound:@"<td class=\"big\" width=\"120\" align=\"center\">"
							  rightBound:@"<br><"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
    if(temp && ![temp hasPrefix:@"NA"])
        [weatherData setObject:temp forKey:@"Forecast"];
    //end getting current forecast
    
    
	//get the current temperature
    temp = [class getStringWithLeftBound:@">"
							  rightBound:@"&"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];                            
    if(temp && ![temp hasPrefix:@"NA"])
        [weatherData setObject:temp forKey:@"Temperature"];
    //end getting current temp
	
    
    temp = [class getStringWithLeftBound:@"<td><b>"
							  rightBound:@"</b>"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
    
    //get the current humidity
    if([temp isEqualToString:@"Humidity"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
								  rightBound:@"</td>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:temp forKey:@"Humidity"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
								  rightBound:@"</b>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    //end getting current humidity
    
    //get the current wind
    if([temp isEqualToString:@"Wind Speed"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
								  rightBound:@" MPH"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:[NSString stringWithFormat:@"%@ mph",temp] forKey:@"Wind"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
								  rightBound:@"</b>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    //end getting current wind
    
    //get the current pressure
    if([temp isEqualToString:@"Barometer"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
								  rightBound:@"</td>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            temp = [class stripWhiteSpaceAtBeginningAndEnd:temp];
			
            if([temp hasPrefix:@"nowrap>"])
                temp = [temp substringFromIndex:7];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
			
            if([temp hasSuffix:@")"])
                temp = [NSString stringWithFormat:@"%@ inches",[[temp componentsSeparatedByString:@"&"] objectAtIndex:0]];
			
            if([temp hasSuffix:@"&quot;"])
                temp = [class stripSuffix:@"&quot;" forString:temp];
			
            [weatherData setObject:temp forKey:@"Pressure"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
								  rightBound:@"</b>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    //end getting current pressure
	
    
    //get the current dew point
    if([temp isEqualToString:@"Dewpoint"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
								  rightBound:@"&"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if ([temp hasPrefix:@"nowrap>"])
                temp = [temp substringFromIndex:8];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:temp forKey:@"Dew Point"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
								  rightBound:@"</b>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    //end getting current dew point
    
    //get the current wind chill
    if([temp isEqualToString:@"Windchill"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
								  rightBound:@"&"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:temp forKey:@"Wind Chill"];
        }
        
        temp = [class getStringWithLeftBound:@"<td><b>"
								  rightBound:@"</b>"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
    }
    //end getting current wind chill
    
    //get the current visibility
    if([temp isEqualToString:@"Visibility"])
    {
        temp = [class getStringWithLeftBound:@"<td align=\"right\""
								  rightBound:@" mi"
									  string:string
									  length:stringLength
								   lastRange:&lastRange];
        if(temp && ![temp hasPrefix:@"NA"])
        {
            if([temp hasPrefix:@" nowrap>"])
                temp = [temp substringFromIndex:9];
            else if([temp hasPrefix:@">"])
                temp = [temp substringFromIndex:1];
            [weatherData setObject:[NSString stringWithFormat:@"%@ miles",temp] forKey:@"Visibility"];
        }
        
		[class getStringWithLeftBound:@"<td><b>"
						   rightBound:@"</b>"
							   string:string
							   length:stringLength
							lastRange:&lastRange];
    }
    //end getting current visibility
    
    
    //get the radar image
    temp = [class getStringWithLeftBound:@"http://www.crh.noaa.gov/radar/latest/"
							  rightBound:@"/si.klot.shtml"
								  string:string
								  length:stringLength
							   lastRange:&lastRange];
	
    if(temp)
        [weatherData setObject:[NSString stringWithFormat:@"http://www.crh.noaa.gov/radar/images/%@/SI.klot/latest.gif",temp] forKey:@"Radar Image"];
    

    //[weatherData setObject:[d descriptionWithCalendarFormat:@"%a, %b %d %I:%M %p"] forKey:@"Last Load"];
    [weatherData setObject:[class dateInfoForCalendarDate:[NSCalendarDate calendarDate]]  forKey:@"Last Update"];
    
    if([weatherData count] > 5)
    {
        supplyingOldData = NO;
    }
    else
    {
        supplyingOldData = YES;
		if (lastWeather != nil) {
			weatherData = lastWeather;
		}	// No previous weather data? We'll use what little we have. _RAM
    }
    
    return YES;
}

/*+ (NSArray *)perfromCitySearch:(NSString *)search info:(NSString *)information
{
    NSURL *url;
    //NSData *data;
    
    NSRange lastRange;
    NSString *string;
    int stringLength;
    NSString *temp;
    NSMutableArray *array = [NSMutableArray array];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    search = [self replaceString:@" " withString:@"%20" forString:search];
    
    url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.srh.noaa.gov/zipcity.php?inputstring=%@",search]];
	
    string = [[[NSString alloc] initWithContentsOfURL:url] autorelease];
    
    if(!string)
        return nil;
	
    stringLength = [string length];
    
    if(!stringLength)
        return nil;
    
    lastRange = NSMakeRange(1,stringLength-1);
    
    // Let's see if this resolved right away
    temp = [self getStringWithLeftBound:@"More than one"
							 rightBound:@"matched your submission"
								 string:string
								 length:stringLength
							  lastRange:&lastRange];
	
    
    //then we resolved right away
    if(!temp || !(lastRange.location))
    {
		
        lastRange = NSMakeRange(1,stringLength-1);
        
        //get the loc
        temp = [self getStringWithLeftBound:@"class=\"white1\">"
								 rightBound:@"<a href"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
        
        if(temp && lastRange.location)
        {
            [dict setObject:temp forKey:@"city"];
            
            temp = [self getStringWithLeftBound:@"warnzone="
									 rightBound:@"&"
										 string:string
										 length:stringLength
									  lastRange:&lastRange];
            
            if(temp && lastRange.location)
            {
                NSString *TEMP = nil;
				
                TEMP = [self getStringWithLeftBound:@"cal_place="
										 rightBound:@"&"
											 string:string
											 length:stringLength
										  lastRange:&lastRange];
                
                if([TEMP hasPrefix:@"1="])
                    TEMP = [TEMP substringFromIndex:2];
				
                if(TEMP && lastRange.location)
                {
                    [dict setObject:[NSString stringWithFormat:@"%@-%@",temp,TEMP] forKey:@"code"];
					
                    if(information)
                        [dict setObject:information forKey:@"info"];
					
                    [array addObject:dict];
                    return array;
                }
				
            }
        }
        
        return [NSArray array];
    }
	
    // Moving down down down...
    temp = [self getStringWithLeftBound:@"<table cellspacing=\"2\" cellpadding=\"20\" border=\"0\">"
							 rightBound:@"<td>"
								 string:string
								 length:stringLength
							  lastRange:&lastRange];
    
    while(lastRange.location)
    {
        dict = [NSMutableDictionary dictionary];
		
        temp = [self getStringWithLeftBound:@"orecasts/"
								 rightBound:@".php"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
        if(!temp)
            break;
		
        NSString *TEMP = nil;
        TEMP = [self getStringWithLeftBound:@"ity="
								 rightBound:@">"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
		
        if(TEMP)
            [dict setObject:[NSString stringWithFormat:@"%@-%@",temp,TEMP] forKey:@"code"];
        else
            break;
		
        lastRange.location--;
        temp = [self getStringWithLeftBound:@">"
								 rightBound:@"</a>"
									 string:string
									 length:stringLength
								  lastRange:&lastRange];
        if(temp)
            [dict setObject:temp forKey:@"city"];
        else
            break;
		
        if(information)
            [dict setObject:information forKey:@"info"];
		
        [array addObject:dict];
    }
    
    return array;
}*/

@end
