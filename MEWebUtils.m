//
//  MEWebUtils.m
//  Meteorologist
//
//  Created by Joseph Crobak on Thu Jun 17 2004.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MEWebUtils.h"
#import "MEStringSearcher.h"
//#ifdef __x86_64__
//#import <CURLHandle_64/CURLHandle.h>
//#import <CURLHandle_64/CURLHandle+extras.h>
//#else
//#import <CURLHandle/CURLHandle+extras.h>
//#endif

#define DEFAULT_TIMEOUT 60

@implementation MEWebFetcher


- (void)dealloc
{
    [super dealloc];
}

+ (MEWebFetcher *)sharedInstance
{
	static MEWebFetcher *sharedInstance = nil;
	if (!sharedInstance)
		sharedInstance = [[self alloc] init];
	return sharedInstance;
}

#pragma mark -
/* @parameters:
				url  is a valid NSURL
   @result:
				returns the result of calling fetchURLtoString:withTimeout: passing DEFAULT_TIMEOUT				
*/
- (NSString *)fetchURLtoString:(NSURL *)url 
{
	return [self fetchURLtoString:url withTimeout:DEFAULT_TIMEOUT];
}

/* @parameters:
				url   is a valid NSURL
				secs  is the number of seconds before the request for url will be given up.
   @result:
				returns the data associated with the url.  Returns nil if there was an error.				
*/
- (NSString *)fetchURLtoString:(NSURL *)url withTimeout:(int)secs
{
	if([[MEPrefs sharedInstance] logMessagesToConsole])
	{
		NSLog(@"Fetching URL: %@",[url absoluteString]);
	}
	NSData *urlData     = [self fetchURLtoData:url withTimeout:secs];
	NSString *urlString = [[[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding] autorelease];
	
	//[urlData release]; // JRC - I still don't understand release I guess...
	//NSLog(@"urlData count: %i",[urlData retainCount]);
	return urlString;
}

#pragma mark -
/* @parameters:
				url  is a valid NSURL
   @result:
				returns the result of calling fetchURLtoData:withTimeout: passing DEFAULT_TIMEOUT				
*/
- (NSData *)fetchURLtoData:(NSURL *)url
{
	return [self fetchURLtoData:url withTimeout:DEFAULT_TIMEOUT];
}

/* @parameters:
				url   is a valid NSURL
				secs  is the number of seconds before the request for url will be given up.
   @result:
				returns the data associated with the url.  Returns nil if there was an error.				
*/
- (NSData *)fetchURLtoData:(NSURL *)url withTimeout:(int)secs 
{
	NSData *data; // data from the website
    
    data = [NSData dataWithContentsOfURL:url];
    
//	mURLHandle = (CURLHandle *)[url URLHandleUsingCache:NO];
//	
//	[mURLHandle setFailsOnError:NO];	   // don't fail on >= 300 code; I want to see real results.
//	[mURLHandle setFollowsRedirects:YES];  // Follow Location: headers in HTML docs.
//	//[mURLHandle setUserAgent: @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6 GTB6"];
//	//[mURLHandle setUserAgent: @"Mozilla/5.0 (iPhone; U; iPhone OS_3_1_3 like Mac OS X; en-US) Gecko/20100115 Firefox/3.6 GTB6"];
//	[mURLHandle setConnectionTimeout:secs];
//	
//	data = [[mURLHandle resourceData] retain]; // already autoreleased?
//	if (NSURLHandleLoadFailed == [mURLHandle status])
//	{
//		NSLog([mURLHandle failureReason],@"");
//        [data release];
//		return nil;
//	}
//	return [data autorelease];
	return data;
}

- (void)URLHandle:(NSURLHandle *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{

}

- (void)URLHandleResourceDidBeginLoading:(NSURLHandle *)sender
{

}

- (void)URLHandleResourceDidFinishLoading:(NSURLHandle *)sender
{

}

- (void)URLHandleResourceDidCancelLoading:(NSURLHandle *)sender
{

}

- (void)URLHandle:(NSURLHandle *)sender resourceDidFailLoadingWithReason:(NSString *)reason
{

}
@end

#pragma mark -

@interface MEWebParser (PrivateMethods)
+ (void)parseSingleMatchFromString:(NSString *)string withParseDict:(NSDictionary *)foundDict
													 withParseArray:(NSArray *)foundArray
													  addingToArray:(NSMutableArray **)cities;
+ (void)parseMultipleMatchesFromString:(NSString *)string withParseDict:(NSDictionary *)foundDict
														 withParseArray:(NSArray *)foundArray
														  addingToArray:(NSMutableArray **)cities;													  
@end

#pragma mark -

@implementation MEWebParser

/*@parameters:
				url   is a valid NSURL request that will contain search results
				s
  @result:
				class performSearchOnUrl:usingParseDict:usingParseArray:withTimeout passing
				DEFAULT_TIMEOUT
*/
+ (NSArray *)performSearchOnURL:(NSURL *)url usingParseDict:(NSDictionary *)parseDict
{
	return [MEWebParser performSearchOnURL:url usingParseDict:parseDict
											      withTimeout:DEFAULT_TIMEOUT];
}

/* @parameters:
				url         is a valid NSURL request that will contain search results.
				searchDict  is a NSDict containing information from weather.xml associated with
				            the page specified by url.
				secs		is the number of seconds for the timeout for downloading the website.
  @result:
				class performSearchOnUrl:usingParseDict:usingParseArray:withTimeout passing
				DEFAULT_TIMEOUT
*/
+ (NSArray *)performSearchOnURL:(NSURL *)url usingParseDict:(NSDictionary *)searchDict
											    withTimeout:(int)secs
{
	NSMutableArray  *citiesFound  = [[NSMutableArray array] retain]; // array to return - already autoreleased
	NSString        *resultsPageContents;                   // text contents at url.
	NSEnumerator	*itr;
	NSRange			searchRange;
	NSArray			*notFoundArray;		   // from weather.xml
	NSArray         *foundArray;		   // from weather.xml
	NSArray			*choicesFoundArray;    // from weather.xml 
	NSString        *notFoundString;	   // from weather.xml 
	NSDictionary    *foundDict;			   // from weather.xml 
	NSDictionary	*choicesDict;		   // from weather.xml 

	NSAssert(searchDict,@"searchDict was nil in performSearchOnURL.  Please restore your weather.xml file.");

	resultsPageContents = [[MEWebFetcher sharedInstance] fetchURLtoString:url withTimeout:secs];
	
	if (!resultsPageContents)
	{
		NSLog(@"Error downloading the page.");
		//return [citiesFound autorelease];
		return [citiesFound autorelease];
	}
	
#if 0
	// The web page URL doesn't display the same as what we see here
	NSLog(@"Begin resultsPageContents:");
	NSLog(resultsPageContents);
	NSLog(@"End resultsPageContents:");
#endif
	
	// Search page for text describing NOT FOUND
	notFoundArray = [searchDict objectForKey:@"notFound"];
	NSAssert(notFoundArray,@"There is an error in the weather.xml file (notFoundArray).  Please Reinstall Meteorologist.");
	
	itr = [notFoundArray objectEnumerator];
	while (notFoundString = [itr nextObject])
	{	
		NSAssert(notFoundString,@"There is an error in the weather.xml file (notFoundArray).  Please Reinstall Meteorologist.");
		searchRange = [resultsPageContents rangeOfString:notFoundString];
		if (searchRange.location != NSNotFound)
		{  
			// NOT FOUND page
			//return [citiesFound autorelease]; /* return an empty array for now */
			return [citiesFound autorelease];
		}
	}

#if 0
	// Search page for text describing FOUND
	foundArray = [searchDict objectForKey:@"found"];
	if (foundArray)
	{
		//NSAssert(foundArray,@"There is an error in the weather.xml file (foundArray).  Please Reinstall Meteorologist.");
		itr = [foundArray objectEnumerator];
		while (foundDict = [itr nextObject])
		{	
			NSAssert([foundDict objectForKey:@"singleMatchString"],@"There is an error in the weather.xml file (foundDict missing key \"singleMatchString\").  Please Reinstall Meteorologist.");
			searchRange = [resultsPageContents rangeOfString:[foundDict objectForKey:@"singleMatchString"]];
			
			if (searchRange.location != NSNotFound) 
			{   // found the singleMatchString
				// search for the single result.
				NSAssert([foundDict objectForKey:@"parseOrder"],@"There is an error in the weather.xml file (foundDict missing key \"parseOrder\").  Please Reinstall Meteorologist.");
				[MEWebParser parseSingleMatchFromString:resultsPageContents 
										  withParseDict:foundDict
										 withParseArray:[foundDict objectForKey:@"parseOrder"]
										  addingToArray:&citiesFound];
				
				
			}
		}
		if ([citiesFound count] > 0)
			//return [citiesFound autorelease];
			return citiesFound;
	}
#endif
	// Search page for text describing MULTIPLE FOUND
	choicesFoundArray = [searchDict objectForKey:@"choicesFound"];
	if (choicesFoundArray) 
	{
		itr = [choicesFoundArray objectEnumerator];
		while (choicesDict = [itr nextObject]) 
		{
			NSAssert([choicesDict objectForKey:@"multipleMatchString"],@"There is an error in the weather.xml file (choicesDict missing key \"multipleMatchString\").  Please Reinstall Meteorologist.");
			searchRange = [resultsPageContents rangeOfString:[choicesDict objectForKey:@"multipleMatchString"]];
			
			if (searchRange.location != NSNotFound) 
			{   // found the multipleMatchString 
				// search for the multiple results.
				NSAssert([choicesDict objectForKey:@"parseOrder"],@"There is an error in the weather.xml file (choicesDict missing key \"parseOrder\").  Please Reinstall Meteorologist.");
				[MEWebParser parseMultipleMatchesFromString:resultsPageContents
											  withParseDict:choicesDict
											 withParseArray:[choicesDict objectForKey:@"parseOrder"]
											  addingToArray:&citiesFound];
				// and add them to citiesFound
			} // if
			else
			{   // found the singleMatchString
				// search for the single result.
				NSAssert([choicesDict objectForKey:@"parseOrder"],@"There is an error in the weather.xml file (foundDict missing key \"parseOrder\").  Please Reinstall Meteorologist.");
				[MEWebParser parseSingleMatchFromString:resultsPageContents 
										  withParseDict:choicesDict
										 withParseArray:[choicesDict objectForKey:@"parseOrder"]
										  addingToArray:&citiesFound];
			}
		} // while
		return [citiesFound autorelease];
	} // 
    
	NSLog(@"No multiple choices found option");
    [citiesFound release];
    return nil;
}											  

+ (NSArray *)parseURL:(NSURL *)url usingParseDict:(NSDictionary *)parseDict
								   usingParseArray:(NSArray *)parseArray
{
	return nil;
}


/* @parameters:
				string		a string representation of an html page.  This html page should be a "single match"
							(found) page.
				foundDict   is a NSDict containing the information from weather.xml for a single match "Found"
							item.
				foundArray  is an array of NSStrings.  These strings must be "code" and "name."
							This array is iterated and its strings are used as keys to get objects out of
							 foundDict.  The objects associated with these keys are searched for within the
							'string' to created a city code/name dictionary.
				cities		a pointer to a NSMutableArray.  The city code/name dictionary is added to this array.
  @result:
				The cityCode and cityName found in the string is added to cities.
*/
+ (void)parseSingleMatchFromString:(NSString *)string withParseDict:(NSDictionary *)foundDict
													 withParseArray:(NSArray *)foundArray
													  addingToArray:(NSMutableArray **)cities													  
{
	NSMutableDictionary *cityInfoDict = [NSMutableDictionary dictionaryWithCapacity:2]; // stores code and name
	NSString *currKey,*substring;
	NSEnumerator *itr;	
	NSCharacterSet	*set = [NSCharacterSet characterSetWithCharactersInString:@" \n\r\t\f\v"];
	
	NSAssert(cities,@"\"cities\" was nil in parseSingleMatchFromString.");
	NSAssert(*cities,@"\"*cities\" was nil in parseSingleMatchFromString.");
	NSAssert(foundDict,@"\"foundDict\" was nil in parseSingleMatchFromString.");
	NSAssert(foundArray,@"\"foundArray\" was nil in parseSingleMatchFromString.");
	
	MEStringSearcher *ss = [[[MEStringSearcher alloc] initWithString:string] autorelease];
	itr = [foundArray objectEnumerator];
	
	while (currKey = [itr nextObject])
	{
		substring = [[ss getStringWithLeftBound:[foundDict objectForKey:[currKey stringByAppendingString:@"Start"]]
									 rightBound:[foundDict objectForKey:[currKey stringByAppendingString:@"End"]]] retain];
		if (substring)
		{
			substring = [substring stringByTrimmingCharactersInSet:set];
			[cityInfoDict setObject:substring forKey:currKey]; // JRC - might cause a autorelease pool crash??
            [substring release];
		}
		else
		{
			//NSLog(@"Missing Key: \"%@\" in [MEWebParser parseSingleMatchWithString...]",currKey);
			//[ss release];
			return;
		}
	}
	
	[*cities addObject:cityInfoDict];
	//[ss release];
}													  

/* @parameters:
				string		a string representation of an html page.  This html page should be a "multiple match"
							(choicesFound) page.
				foundDict   is a NSDict containing the information from weather.xml for a multiple match 
							"choicesFound" item.
				foundArray  is an array of NSStrings.  These strings must be "code" and "name."
							This array is iterated and its strings are used as keys to get objects out of
							 foundDict.  The objects associated with these keys are searched for within the
							'string' to created a city code/name dictionary.
				cities		a pointer to a NSMutableArray.  The city code/name dictionary is added to this array.
  @result:
				All cities found with information from foundDict and foundArray have been added to 'cities.'
*/
+ (void)parseMultipleMatchesFromString:(NSString *)string withParseDict:(NSDictionary *)foundDict
														 withParseArray:(NSArray *)foundArray
														  addingToArray:(NSMutableArray **)cities
{
	NSMutableDictionary *cityInfoDict;
	NSString *currKey,*substring;
	NSEnumerator *itr;
	
	NSAssert(cities,@"\"cities\" was nil in parseMultipleMatchesFromString.");
	NSAssert(*cities,@"\"*cities\" was nil in parseMultipleMatchesFromString.");
	NSAssert(foundDict,@"\"foundDict\" was nil in parseMultipleMatchesFromString.");
	NSAssert(foundArray,@"\"foundArray\" was nil in parseMultipleMatchesFromString.");
	
	MEStringSearcher *ss = [[MEStringSearcher alloc] initWithString:string];

	while (![ss atEnd])
	{ // search for the two keys and add them to the cities array.
		cityInfoDict = [NSMutableDictionary dictionaryWithCapacity:2];
		itr = [foundArray objectEnumerator];
		while (currKey = [itr nextObject])
		{
			substring = [[ss getStringWithLeftBound:[foundDict objectForKey:[currKey stringByAppendingString:@"Start"]]
										 rightBound:[foundDict objectForKey:[currKey stringByAppendingString:@"End"]]] retain];
			if (substring)
			{
				[cityInfoDict setObject:substring forKey:currKey];
                [substring release];
			} else
			{
				NSLog(@"Missing Key: %@ in [MEWebParser parseMultipleMatchesWithString...]",currKey);
				continue;
			}
		} // while
		[*cities addObject:cityInfoDict];
	} // while
	
	[ss release];
}
@end
