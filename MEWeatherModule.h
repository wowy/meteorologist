//
//  MEWeatherModule.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MEPrefs.h"
#import <Foundation/Foundation.h>

@interface MEWeatherModule : NSObject 
{
    NSMutableDictionary *weatherData;
    BOOL dataIsLoaded;
    BOOL supplyingOldData;
    
    NSString *code, *info;
    
    BOOL active, debug;
}

- (id)initWithCode:(NSString *)theCode info:(NSString *)theInfo active:(BOOL)isActive;

+ (NSString *)sourceName;
+ (NSArray *)supportedKeys;
+ (NSArray *)supportedInfos;

- (void)invalidateData;
- (BOOL)supplyingOldData;

- (BOOL)loadWeatherData;
- (id)objectForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)dock;
- (NSImage *)imageForString:(NSString *)string givenKey:(NSString *)key inDock:(BOOL)dock;

+ (NSString *)getStringWithLeftBound:(NSString *)left rightBound:(NSString *)right string:(NSString *)string
length:(int)stringLength lastRange:(NSRange *)lastRange;
+ (NSString *)replaceString:(NSString *)bad withString:(NSString *)replace forString:(NSString *)old;
+ (NSString *)stripWhiteSpaceAtBeginningAndEnd:(NSString *)str;

+ (NSString *)stripSuffix:(NSString *)suf forString:(NSString *)string;
+ (NSString *)stripPrefix:(NSString *)prf forString:(NSString *)string;

+ (NSArray *)performCitySearch:(NSString *)search info:(NSString *)information;

+ (NSString *)dateInfoForCalendarDate:(NSCalendarDate *)date;

NSImage *imageForName(NSString *name, BOOL inDock);

@end

@interface MEYahooWeatherCom : MEWeatherModule 
{
}
@end


@interface MEWeatherCom : MEWeatherModule 
{
}

- (void)loadGlobalWeatherData;

@end


@interface MEWundergroundCom : MEWeatherModule
{
}

+ (BOOL)validDataInString:(NSString *)string stringLength:(int)stringLength withLastRange:(NSRange)range;

@end


@interface MENWSCom : MEWeatherModule
{
}

@end
