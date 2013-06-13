//
//  MEWeather.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Tue Jan 07 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEWeatherModule.h"
#import "MEPrefs.h"

@interface MEWeatherForecastEnumerator : NSObject
{
    NSMutableArray *forecastArrays;
    BOOL isFirst;
}

- (id)initWithForecastArrays:(NSMutableArray *)arrays;
- (void)nextDay;
- (void)nextDay:(BOOL)strip;
- (NSImage *)imageForKey:(NSString *)key inDock:(BOOL)inDock;
- (id)objectForKey:(NSString *)key;

@end


@interface MEWeather : NSObject 
{
    NSMutableArray *modules;
    NSArray *moduleClasses;
    MEWeatherForecastEnumerator *forecastEnum;
}

- (id)initWithCodesAndInfos:(NSDictionary *)dict;
- (void)newForecastEnumeratorForMods:(NSArray *)mods;

+ (NSArray *)moduleNames;
- (NSArray *)moduleClasses;
- (NSArray *)loadedModuleInstances;
+ (NSArray *)moduleClasses;
- (NSArray *)modulesForNames:(NSArray *)sourceNames;
+ (Class)moduleClassForName:(NSString *)sourceName;
+ (NSArray *)moduleNamesSupportingProperty:(NSString *)property;
- (void)prepareNewServerData;

+ (NSArray *)unitsForKey:(NSString *)key;

- (id)objectForKey:(NSString *)key modules:(NSArray *)mods;

- (NSString *)stringForKey:(NSString *)key modules:(NSArray *)mods;
- (NSString *)forecastStringForKey:(NSString *)key newDay:(BOOL)newDay;
+ (NSString *)shortNameForKey:(NSString *)key;

- (NSString *)stringForKey:(NSString *)key units:(NSString *)units prefs:(MEPrefs *)prefs displayingDegrees:(BOOL)degrees modules:(NSArray *)mods;
- (NSImage *)imageForKey:(NSString *)key size:(int)size modules:(NSArray *)mods inDock:(BOOL)dock;
- (NSString *)forecastStringForKey:(NSString *)key units:(NSString *)units prefs:(MEPrefs *)prefs displayingDegrees:(BOOL)degrees modules:(NSArray *)mods;
- (NSImage *)forecastImageForKey:(NSString *)key size:(int)size modules:(NSArray *)mods inDock:(BOOL)dock;

+ (NSArray *)performCitySearch:(NSString *)search module:(MEWeatherModule *)mod info:(NSString *)info;

@end
