//
//  MEWeatherModuleParser.h
//  XML Meteo
//
//  Created by Matthew Fahrenbacher on Thu Apr 17 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//	03 Sep 2003	Rich Martin	added spacesOnly arg to stringFromWebsite:
//

#import "MEPrefs.h"
#import <Foundation/Foundation.h>
//#import <AGRegex/AGRegex.h>

@interface MEWeatherModuleParser : NSObject 
{
    NSDictionary *moduleDict;
}

+ (id)sharedInstance;

- (NSArray *)allServerNames;

- (NSData *)loadDataFromWebsite:(NSURL *)url;
- (NSString *)stringFromWebsite:(NSURL *)url spacesOnly:(BOOL) flag;

+ (NSString *)getStringFromString:(NSString *)start upToString:(NSString *)end inString:(NSString *)string;
+ (NSString *)getStringFromString:(NSString *)start upToString:(NSString *)end inString:(NSString *)string
													remainingString:(NSString **)remaining;
													
- (NSArray *)performCitySearch:(NSString *)search onServer:(NSString *)server;
- (NSDictionary *)loadWeatherDataForServer:(NSString *)server code:(NSString *)code;

@end
