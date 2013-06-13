//
//  MECity.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Sat Jan 04 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MECity.h"


@implementation MECity

+ (MECity *)defaultCity
{
    MECity *city = [[MECity alloc] initWithCityAndInfoCodes:[NSMutableDictionary dictionary] forCity:@""];
    [city replaceMissingDefaults];
                                        
    return [city autorelease];
}

/* @called-by:  MECity defaultCity
*/
- (id)initWithCityAndInfoCodes:(NSMutableDictionary *)dict forCity:(NSString *)city
{
    self = [super init];
    if(self)
    {
        weather_attributes = [[NSMutableArray alloc] init];
        forecast_attributes = [[NSMutableArray alloc] init];
        cityAndInfoCodes = [dict mutableCopy];
        cityName = [city copy];
        isActive = YES;
        
        weather = [[MEWeather alloc] initWithCodesAndInfos:cityAndInfoCodes];
		
		[self replaceMissingDefaults];
    }
    return self;
}

- (void)dealloc
{
    [weather_attributes release]; /* JRC - changed all autoreleases to release */
    [forecast_attributes release];
    [cityAndInfoCodes release];
    [cityName release];
    [weather release];
	
	[super dealloc];
}

- (MECity *)copy
{
    MECity *city = [[MECity alloc] initWithCityAndInfoCodes:[[self->cityAndInfoCodes mutableCopy] autorelease]
                                   forCity:[[[self cityName] copy] autorelease]];
    [city setWeatherAttributes:[[self weatherAttributes] duplicate]];
    [city setForecastAttributes:[[self forecastAttributes] duplicate]];
    city->isActive = self->isActive;
    city->weather = [self->weather retain];
    
    return city;
}

/* @called-by:  never called?? */
- (void)setCode:(NSString *)code info:(NSString *)info forServer:(NSString *)server
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:code forKey:@"code"];
    [dict setObject:info forKey:@"info"];
    [cityAndInfoCodes setObject:dict forKey:server];
    
    [weather autorelease];
    weather = [[MEWeather alloc] initWithCodesAndInfos:cityAndInfoCodes];
}

/* @called-by:  MECityEditor weatherSourceActivenessChanged:
*/
- (void)recreateWeatherObject
{
    [weather autorelease]; /* JRC - was autorelease */
    weather = [[MEWeather alloc] initWithCodesAndInfos:cityAndInfoCodes];
}

/* @called-by:  MECityEditor tableViewSelectionDidChange:
*/
- (void)setCodeInfo:(NSMutableDictionary *)dict forServer:(NSString *)server
{
    [cityAndInfoCodes setObject:[dict retain] forKey:server];
    
    [weather autorelease]; /* JRC - was autorelease */
    weather = [[MEWeather alloc] initWithCodesAndInfos:cityAndInfoCodes]; /* retained */
}

- (NSMutableDictionary *)codeAndInfoForServer:(NSString *)server
{
    return [cityAndInfoCodes objectForKey:server];
}

- (void)setWeatherAttributes:(NSMutableArray *)atr
{
    [weather_attributes autorelease]; /* JRC - was autorelease */
    weather_attributes = [atr retain];
}

- (NSMutableArray *)weatherAttributes
{
    return weather_attributes;
}

- (void)setForecastAttributes:(NSMutableArray *)atr
{
    [forecast_attributes autorelease]; /* JRC - was autorelease */
    forecast_attributes = [atr retain];
}

- (NSMutableArray *)forecastAttributes
{
    return forecast_attributes;
}

- (NSString *)cityName
{
    return cityName;
}

- (void)setCityName:(NSString *)name
{
    [cityName autorelease]; /* JRC - was autorelease */
    cityName = [name retain];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if([encoder respondsToSelector:@selector(allowsKeyedCoding)])
    {
        [encoder encodeObject:cityName forKey:@"name"];
        [encoder encodeObject:weather_attributes forKey:@"weather"];
        [encoder encodeObject:forecast_attributes forKey:@"forecast"];
        [encoder encodeObject:cityAndInfoCodes forKey:@"infoAndCodes"];
        [encoder encodeObject:[NSNumber numberWithBool:isActive] forKey:@"isActive"];
    }
    else
    {
        [encoder encodeObject:cityName];
        [encoder encodeObject:weather_attributes];
        [encoder encodeObject:forecast_attributes];
        [encoder encodeObject:cityAndInfoCodes];
        [encoder encodeObject:[NSNumber numberWithBool:isActive]];
    }
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if(self)
    {
        if([decoder respondsToSelector:@selector(allowsKeyedCoding)])
        {
            cityName = [decoder decodeObjectForKey:@"name"];
            if (cityName)
				[cityName retain];
			else
				cityName = @"d";
            weather_attributes = [decoder decodeObjectForKey:@"weather"];
			if (weather_attributes)
				[weather_attributes retain];
			else
				weather_attributes = [[NSMutableArray alloc] init];
            forecast_attributes = [decoder decodeObjectForKey:@"forecast"];
			if (forecast_attributes)
				[forecast_attributes retain];
			else
				forecast_attributes = [[NSMutableArray alloc] init];
			NSArray *toBeRemoved = [NSArray arrayWithObjects:@"Forecast - Hi",@"Forecast - Wind",nil];
			NSEnumerator *itr = [forecast_attributes objectEnumerator];
			NSDictionary *attribute;
			while (attribute = [itr nextObject])
			{
				NSEnumerator *remItr = [toBeRemoved objectEnumerator];
				NSString *TBRProp;
				while (TBRProp = [remItr nextObject])
					if ([TBRProp isEqualToString:[attribute objectForKey:@"property"]])
					{
						[forecast_attributes removeObject:attribute];
						// removing an object might screw up the enumerator
						itr = [forecast_attributes objectEnumerator];
					}
			}
			
			
            cityAndInfoCodes = [decoder decodeObjectForKey:@"infoAndCodes"];
            if (cityAndInfoCodes)
				[cityAndInfoCodes retain];
			else
				cityAndInfoCodes = [[NSMutableDictionary dictionary] retain];
            isActive = [[decoder decodeObjectForKey:@"isActive"] boolValue];
            [self replaceMissingDefaults];
            
            weather = [[MEWeather alloc] initWithCodesAndInfos:cityAndInfoCodes];
        }
        else
        {
            cityName = [[decoder decodeObject] retain];
            weather_attributes = [[decoder decodeObject] retain];
            forecast_attributes = [[decoder decodeObject] retain];
            cityAndInfoCodes = [[decoder decodeObject] retain];
            isActive = [[decoder decodeObject] boolValue];
            [self replaceMissingDefaults];
            
            weather = [[MEWeather alloc] initWithCodesAndInfos:cityAndInfoCodes];
        }
    }
    return self;
}

- (void)setActive:(BOOL)act
{
    isActive = act;
}

- (BOOL)isActive
{
    return isActive;
}

- (void)toggleActivity
{
    isActive = !isActive;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MECityOrderChanged" object:nil];
}

- (MEWeather *)weatherReport
{
    return weather;
}

- (BOOL)searchArrayEnum:(NSEnumerator *)enumer forProperty:(NSString *)property
{
    NSDictionary *next;
    
    while(next = [enumer nextObject])
    {
        if([next objectForKey:@"enabled"])
        {
            if([[next objectForKey:@"property"] isEqualToString:property])
                return YES;
        }
        else
        {
            if([self searchArrayEnum:[[next objectForKey:@"subarray"] objectEnumerator] forProperty:property])
                return YES;
        }
    }
    
    return NO;
}

- (void)removeDefaultsFromArray:(NSMutableArray *)def notStoredInArray:(NSArray *)sto
{
    int i = [def count]-1;
    
    while(i>=0)
    {
        NSDictionary *dict = [def objectAtIndex:i];
        
        if([dict objectForKey:@"enabled"])
        {
            NSString *prop = [dict objectForKey:@"property"];
            
            if(![sto containsObject:prop])
                [def removeObjectAtIndex:i];
        }
        else //nest
        {
            [self removeDefaultsFromArray:[dict objectForKey:@"subarray"] notStoredInArray:sto];
        }
        
        i--;
    }
}

- (void)removeOldDefaults
{
    NSMutableArray *atr = [self weatherAttributes];
    NSMutableArray *fcs = [self forecastAttributes];
    
    NSArray *classes = [MEWeather moduleClasses];
    NSEnumerator *classEnum = [classes objectEnumerator];
    Class class;
    
    NSMutableArray *properties = [NSMutableArray array];
    
    while(class = [classEnum nextObject])
    {
        NSArray *props = [class supportedKeys];
        [properties addObjectsFromArray:props];
    }
    
    [self removeDefaultsFromArray:atr notStoredInArray:properties];
    [self removeDefaultsFromArray:fcs notStoredInArray:properties];
}

- (void)replaceMissingDefaults
{
    NSMutableArray *atr = [self weatherAttributes];
    NSMutableArray *fcs = [self forecastAttributes];
    NSArray *keys = [NSArray arrayWithObjects:@"enabled",@"property",@"servers",@"unit",nil];
    
    NSArray *classes = [MEWeather moduleClasses];
    NSEnumerator *classEnum = [classes objectEnumerator];
    Class class;
    
    NSArray *ignoreArray = [NSArray arrayWithObjects:@"Weather Image",
                                                     @"Forecast - Link",
                                                     @"Forecast - Icon",
                                                     @"Weather Link",
                                                     @"Moon Phase",
													 @"Weather Alert Link",
                                                     nil];
    
    while(class = [classEnum nextObject])
    {
        NSArray *properties = [class supportedKeys];
        NSEnumerator *propertyEnum = [properties objectEnumerator];
        NSString *propertyName;
        
        while(propertyName = [propertyEnum nextObject])
        {
            if([ignoreArray containsObject:propertyName])
                continue;
        
            BOOL forecastParam = [propertyName hasPrefix:@"Forecast - "];
            NSEnumerator *arrayEnum;
            //NSDictionary *propertyDict;
                
            if(forecastParam)
                arrayEnum = [fcs objectEnumerator];
            else
                arrayEnum = [atr objectEnumerator];
            
            //only case if we get here
            if(![self searchArrayEnum:arrayEnum forProperty:propertyName])
            {
                NSMutableArray *theArray;
                
                if(forecastParam)
                    theArray = fcs;
                else
                    theArray = atr;
                    
                NSArray *suppServers = [MEWeather moduleNamesSupportingProperty:propertyName];
                //suppServers = [NSMutableArray arrayWithObject:[suppServers objectAtIndex:0]];
                    
                //BOOL enabled = !([propertyName isEqualToString:@"Forecast - Date"] ||[propertyName isEqualToString:@"Radar Image"]) ;
                BOOL enabled = YES;
                    
                [theArray addObject:
                            [NSMutableDictionary dictionaryWithObjects:
                                                    [NSMutableArray arrayWithObjects:
                                                                        [NSNumber numberWithBool:enabled],
                                                                        propertyName,
                                                                        suppServers,
                                                                        [[MEWeather unitsForKey:propertyName] objectAtIndex:0],
                                                                        nil]
                                        forKeys:keys]];
                                        
            }
        }
    }
}

- (NSDictionary *)dictFromEnum:(NSEnumerator *)enumer forProperty:(NSString *)prop
{
    NSDictionary *obj;
    
    while(obj = [enumer nextObject])
    {
        if([obj objectForKey:@"enabled"])
        {
            if([[obj objectForKey:@"property"] isEqualToString:prop])
                return obj;
        }
        else
        {
            NSDictionary *temp = [self dictFromEnum:[[obj objectForKey:@"subarray"] objectEnumerator] forProperty:prop];
            if(temp)
                return temp;
        }
    }
    
    return nil;
}

- (NSDictionary *)dictionaryForProperty:(NSString *)prop;
{
    //NSEnumerator *objEnum = [weather_attributes objectEnumerator];
    NSDictionary *obj;
    
    obj = [self dictFromEnum:[weather_attributes objectEnumerator] forProperty:prop];
    if(obj)
        return obj;
    
    obj = [self dictFromEnum:[forecast_attributes objectEnumerator] forProperty:prop];
    if(obj)
        return obj;
            
    return [NSDictionary dictionary];
}

@end


@implementation NSMutableArray (DuplicationAdditions)

- (id)duplicate
{
    return [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject:self]];
}

@end
