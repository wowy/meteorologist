//
//  MEStringSearcher.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Wed May 28 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
// 
//  6/21/2004
//  JRC - Provides a class for finding text within a string.  The static (class) method 
//        getStringWithLeftBound:rightBound:inString: provides an easy way to do a one-time search.
//        A MEStringSearcher object, on the otherhand, is used when it is useful to search for information
//        in a particular order.  Subsequent searches start where the last one left off.
//        If at anytime a left bound or right bound was not found, then "atEnd" will return false.
//        The other methods are rather self-explanatory.
//

#import <Foundation/Foundation.h>

@interface MEStringSearcher : NSObject
{
    NSString *string;
    NSRange range;
    int length;
}

- (id)initWithString:(NSString *)str;

- (NSString *)getStringWithLeftBound:(NSString *)lft rightBound:(NSString *)rght;
+ (NSString *)getStringWithLeftBound:(NSString *)start rightBound:(NSString *)end
							inString:(NSString *)string;

- (void)moveBack:(int)dis;
- (void)moveForward:(int)dis;
- (void)moveToString:(NSString *)str;
- (void)moveToBeginning;

- (BOOL)atEnd;
@end
