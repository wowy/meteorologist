//
//  MEWeatherModuleParser.m
//  XML Meteo
//
//  Created by Matthew Fahrenbacher on Thu Apr 17 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//	03 Sep 2003	Rich Martin	added spacesOnly arg to stringFromWebsite:
//

#import "MEWeatherModuleParser.h"
#import "MEStringSearcher.h"
#import "MEWebUtils.h"
#import "NSString-Additions.h"
MEWeatherModuleParser *sharedWeatherModuleParser = nil;

@implementation MEWeatherModuleParser

- (id)init
{
    self = [super init];
    if(self)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"weather" ofType:@"xml"];
        moduleDict = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
        
        if(!path || !moduleDict)
        {
            //error
            [self release];
        }
    }
    return self;
}

+ (id)sharedInstance
{
    if(!sharedWeatherModuleParser)
        sharedWeatherModuleParser = [[MEWeatherModuleParser alloc] init];
        
    return sharedWeatherModuleParser;
}

- (NSArray *)allServerNames
{
    return [moduleDict allKeys];
}

- (void)dealloc
{
    [moduleDict autorelease]; /* JRC - was autorelease */
    [super dealloc];
}

- (NSData *)loadDataFromWebsite:(NSURL *)url
{
	NSError *error;
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData
										  timeoutInterval:60];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error) {	
		NSLog(@"Error: %@",[error localizedDescription]);
	}
	
	return data;
	
    /*NSTask *task = [[[NSTask alloc] init] autorelease];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *handle = nil;
    NSData *inData = nil;
    NSMutableData *data = [NSMutableData data];
    
    [task setStandardOutput:pipe];
    handle = [pipe fileHandleForReading];
    
    [task setLaunchPath:@"/usr/bin/curl"];
    [task setArguments:[NSArray arrayWithObjects:@"-s",@"-i",site,nil]];
    
    [task launch];
    
    while ((inData = [handle availableData]) && [inData length])
        [data appendData:inData];
    
    [pipe release];

    return data; */
}

- (NSString *)stringFromWebsite:(NSURL *)url spacesOnly: (BOOL) flag
{
	return [[MEWebFetcher sharedInstance] fetchURLtoString:url];

/*    NSData *data = [self loadDataFromWebsite:url];
    NSString *str = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];

	//NSLog(@"String: %@",str);

	if (flag == NO) return str;

	// there might be a faster way to do this, especially with Regex's 
    str = [[str componentsSeparatedByString:@"\n"] componentsJoinedByString:@" "];
    str = [[str componentsSeparatedByString:@"\r"] componentsJoinedByString:@" "];
    str = [[str componentsSeparatedByString:@"\t"] componentsJoinedByString:@" "];
    str = [[str componentsSeparatedByString:@"\f"] componentsJoinedByString:@" "];
    str = [[str componentsSeparatedByString:@"\v"] componentsJoinedByString:@" "];
    
    return str; */
}

/* Never called ! */
- (NSDictionary *)loadWeatherDataForServer:(NSString *)server code:(NSString *)code
{
/*    NSDictionary *weatherDataDict = [[moduleDict objectForKey:server] objectForKey:@"weather data"];
    NSString *htmlLoc = [NSString stringWithFormat:[weatherDataDict objectForKey:@"url"], code];
    NSString *htmlStr = [self stringFromWebsite:[NSURL URLWithString:htmlLoc] spacesOnly: YES];
    
    NSArray *weatherItems = [weatherDataDict objectForKey:@"weather items"];
*/    
    return nil;
}

+ (NSString *)getStringFromString:(NSString *)start upToString:(NSString *)end inString:(NSString *)string
{
	return [MEWeatherModuleParser getStringFromString:start upToString:end inString:string remainingString:nil];
}

/* remaining - everything after 'end' in the string 'string' is loaded into this 
			   If remaining is nil, then nothing is placed in remaining
*/
+ (NSString *)getStringFromString:(NSString *)start upToString:(NSString *)end inString:(NSString *)string
													remainingString:(NSString **)remaining
{

	NSString  *result = [NSString string];
	NSScanner *scanner = [NSScanner scannerWithString:string];
	[scanner setCaseSensitive:NO]; // costly?
	
	[scanner scanUpToString:start intoString:nil];     // find the start string
	[scanner scanString:start     intoString:nil];     // skip the start string
	[scanner scanUpToString:end   intoString:&result]; // find everything between start and end string

	if ([scanner scanLocation] == [string length] - 1) // at the end
		return nil;
	
	if (remaining != nil){
		[scanner scanString:end intoString:nil];
//		int scanLoc = [scanner scanLocation];
		//[remaining release];
		*remaining = [NSString stringWithString:[string substringFromIndex:[scanner scanLocation]]];
	}
	return result;

}

- (NSArray *)performCitySearch:(NSString *)search onServer:(NSString *)server
{
	NSMutableString *searchTerm			  = [NSMutableString stringWithString:search];
	NSDictionary    *searchCityStateSpecs = [[moduleDict objectForKey:server] objectForKey:@"searchCityState"];
	NSDictionary    *searchZipSpecs       = [[moduleDict objectForKey:server] objectForKey:@"searchZip"];
	NSDictionary	*searchDictionary;     // one of the two above
	NSString        *searchQueryURL;	   // from weather.xml and search
	BOOL            isAURL;
	
	NSAssert(searchCityStateSpecs,@"searchCityStateSpecs was nil in performCitySearch:onServer:.  Please restore your weather.xml file.");
	NSAssert(searchZipSpecs,@"searchZipSpecs was nil in performCitySearch:onServer:.  Please restore your weather.xml file.");

	// Add http:// if missing.
	if ([searchTerm hasPrefix:@"www."])
		searchTerm = [NSMutableString stringWithFormat:@"http://%@",searchTerm];
	isAURL = [searchTerm hasPrefix:@"http://"];
//	if (isAURL)
//		searchTerm = [NSMutableString stringWithFormat:@"http://www.w3.%@",[searchTerm stripPrefix:@"http://www."]];
		
	// figure out if we're searching for a city,state, a zip code, or a URL
	if (isAURL)
		searchDictionary = searchZipSpecs; // JRC - just for now! might only work with weather.com
	else if ([searchTerm intValue] == 0) // not a numeric value
		searchDictionary = searchCityStateSpecs;
	else if ([[searchZipSpecs objectForKey:@"sameAsSearchCityState"] boolValue] == YES)
		searchDictionary = searchCityStateSpecs;
	else
		searchDictionary = searchZipSpecs;
	
	// a searchDictionary must have found and notFound and could also have choicesFound
	if (!isAURL)
		searchQueryURL = [NSString stringWithFormat:[searchDictionary objectForKey:@"searchURL"], searchTerm];
	else 
		searchQueryURL = searchTerm;
	
	if([[MEPrefs sharedInstance] logMessagesToConsole])
	{
		NSLog(@"search url: %@",searchQueryURL);
	}
    return [MEWebParser performSearchOnURL:[NSURL URLWithString:[searchQueryURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
							usingParseDict:searchDictionary];
}

@end
