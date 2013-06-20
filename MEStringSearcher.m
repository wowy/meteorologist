//
//  MEStringSearcher.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Wed May 28 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//	03 Sep 2003	Rich Martin	made getStringWithLeftBound:rightBound: a bit more flexible in its leftBound
//

#import "MEStringSearcher.h"

@interface MEStringSearcher (PrivateMethods)
- (BOOL)isValidRange:(NSRange)range forLength:(int)len;
@end

@implementation MEStringSearcher

- (id)initWithString:(NSString *)str
{
    self = [super init];
    if(self)
    {
        string = str;
        length = [string length];
        range = NSMakeRange(0,length);
    }
    return self;
}


- (NSString *)getStringWithLeftBound:(NSString *)lft rightBound:(NSString *)rght
{
    NSString *newStr;
    NSRange newRange;    
    NSRange leftRange,rightRange;
	int endOfLeftStringIndex, endOfRightStringIndex;
    
    if(![self isValidRange:range forLength:length]) {
		range.location = length-1; // so atEnd retursn false
		range.length = 0;
		return nil;
	}
	
	// if left bound is given as nil or as empty string,
	// we look at everything from the current location to the rightBound
	if (lft == nil || [lft isEqualToString:@""]) {
		leftRange = NSMakeRange(range.location,0);
	} else {
		leftRange = [string rangeOfString:lft
							options:NSCaseInsensitiveSearch
							range:range];
	}
	
    if(![self isValidRange:leftRange forLength:length]) {
		range.location = length-1; // It wasn't found, so set range to the end of the string
		range.length = 0;
		return nil;
	}
    endOfLeftStringIndex = leftRange.location + leftRange.length;
    
	/* Find the right string in a new range past string we just found
	   and make sure that it is valid */
    rightRange = [string rangeOfString:rght
                         options:NSCaseInsensitiveSearch
                         range:NSMakeRange(endOfLeftStringIndex,length - endOfLeftStringIndex)];
    if(![self isValidRange:rightRange forLength:length]) {
		range.location = length-1; // It wasn't found, so set range to the end of the string
		range.length = 0;
        return nil;
	}
		
    endOfRightStringIndex = rightRange.location+rightRange.length;
        
	/* no characters between them */
    if(rightRange.location-endOfLeftStringIndex <= 0)
        return nil;
    
	/* calculate the range of the substring between end of left and start of right */
    newRange = NSMakeRange(endOfLeftStringIndex,rightRange.location-endOfLeftStringIndex);
    if(![self isValidRange:newRange forLength:length])
        return nil;
    
    newStr = [string substringWithRange:newRange];
    
    if(endOfRightStringIndex != 0)
        endOfRightStringIndex--;
    
    range = NSMakeRange(endOfRightStringIndex,length - endOfRightStringIndex);
        
    return newStr;
}

+ (NSString *)getStringWithLeftBound:(NSString *)start rightBound:(NSString *)end
							inString:(NSString *)str 
{
	NSString *result;
	MEStringSearcher *ss = [[MEStringSearcher alloc] initWithString:str];
							
	result = [ss getStringWithLeftBound:start rightBound:end];
	
	return result;
}

- (void)moveBack:(int)dis
{
    if(range.location >= dis)
    {
        range.location -= dis;
        range.length += dis;
    }
}

- (void)moveForward:(int)dis
{
    if(dis <= range.length)
    {
        range.location += dis;
        range.length -= dis;
    }
}

- (void)moveToString:(NSString *)str
{
    NSRange tempR = [string rangeOfString:str                                                                                                     
                            options:NSCaseInsensitiveSearch  
                            range:range];
                            
    if([self isValidRange:tempR forLength:length])
    {
        range.location = tempR.location + tempR.length;
        range.length = length - range.location;
    }
}

- (void)moveToBeginning
{
    range = NSMakeRange(0,length);
}

- (BOOL)atEnd
{
	return ((length-1) == range.location);
}

- (BOOL)isValidRange:(NSRange)theRange forLength:(int)len
{
    //if (theRange.location == NSNotFound || theRange.location < 0 || theRange.location + theRange.length > len)
    if (theRange.location == NSNotFound || theRange.location + theRange.length > len)
        return NO;
        
    else
        return YES;
}
@end
