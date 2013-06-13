//
//  NSString-Additions.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Wed May 28 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "NSString-Additions.h"

@implementation NSString (MEAdditions)

- (NSString *)stripSuffix:(NSString *)suff
{
    if([self hasSuffix:suff])
        return [self substringToIndex:[self length] - [suff length]];
    else
        return nil;
}

- (NSString *)stripPrefix:(NSString *)pref
{
    if([self hasPrefix:pref])
        return [self substringFromIndex:[pref length]];
    else
        return nil;
}

- (NSString *)stripPhrase:(NSString *)phrs
{
    return [self replaceString:phrs withString:@""];
}

- (NSString *)stripCharacters:(NSString *)chars onlyBeginningAndEnd:(BOOL)only
{
    if(only)
        return [self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:chars]];
    else
    {
        NSString *temp = self;
        int i;
        
        for(i = [chars length]-1; i>=0; i--)
            temp = [self replaceString:[NSString stringWithFormat:@"%c",[chars characterAtIndex:i]]
                         withString:@""];
                         
        return temp;
    }
}

- (NSString *)replaceString:(NSString *)rpl withString:(NSString *)wth
{
    return [[self componentsSeparatedByString:rpl] componentsJoinedByString:wth];
}

- (NSString *)replaceRange:(NSRange)range withString:(NSString *)str
{
    return [NSString stringWithFormat:@"%@%@%@",
                     [self substringToIndex:range.location],
                     str,
                     [self substringFromIndex:range.location+range.length]];
}

@end
