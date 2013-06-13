//
//  MECity.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Sat Jan 04 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MEWeather.h"

@interface MECity : NSObject 
{
    NSMutableArray *weather_attributes; //an array of dictionaries
                                        //each dictionary has three keys
                                        //enabled -> a BOOL indicating whether the attribute is enabled
                                        //property -> a string denoting a weather attribute
                                        //servers -> an array of server names
                                        //units -> a string denoting the units used
                                        
    NSMutableArray *forecast_attributes; //an array of dictionaries
                                         //each dictionary has three keys
                                         //enabled -> a BOOL indicating whether the attribute is enabled
                                         //property -> a string denoting a weather attribute
                                         //servers -> an array of server names
                                         //units -> a string denoting the units used
    
    NSString *cityName; //user defined city name
    NSMutableDictionary *cityAndInfoCodes; //each server has a code and info associated with it
    
    MEWeather *weather;
    BOOL isActive;
}

+ (MECity *)defaultCity;

- (id)initWithCityAndInfoCodes:(NSMutableDictionary *)dict forCity:(NSString *)city;

- (MECity *)copy;

- (void)setCode:(NSString *)code info:(NSString *)info forServer:(NSString *)server;
- (void)recreateWeatherObject;
- (void)setCodeInfo:(NSMutableDictionary *)dict forServer:(NSString *)server;
- (NSMutableDictionary *)codeAndInfoForServer:(NSString *)server;

- (void)setWeatherAttributes:(NSMutableArray *)atr;
- (NSMutableArray *)weatherAttributes;
- (void)setForecastAttributes:(NSMutableArray *)atr;
- (NSMutableArray *)forecastAttributes;

- (void)setCityName:(NSString *)name;
- (NSString *)cityName;

- (void)setActive:(BOOL)act;
- (BOOL)isActive;
- (void)toggleActivity;

- (void)replaceMissingDefaults;

- (MEWeather *)weatherReport;
- (NSDictionary *)dictionaryForProperty:(NSString *)prop;

@end



@interface NSMutableArray (DuplicationAdditions)

- (id)duplicate;

@end
