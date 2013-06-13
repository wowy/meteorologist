//
//  NSString-Additions.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Wed May 28 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (MEAdditions)

- (NSString *)stripSuffix:(NSString *)suff;
- (NSString *)stripPrefix:(NSString *)pref;
- (NSString *)stripPhrase:(NSString *)phrs;
- (NSString *)stripCharacters:(NSString *)chars onlyBeginningAndEnd:(BOOL)only;

- (NSString *)replaceString:(NSString *)rpl withString:(NSString *)wth;

- (NSString *)replaceRange:(NSRange)range withString:(NSString *)str;

@end
