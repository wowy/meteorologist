//
//  MEWebUtils.h
//  Meteorologist
//
//  Created by Joseph Crobak on Thu Jun 17 2004.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//
//  6/21/2004
//  JRC - The goal of these two classes is to provide functionality for downloading URLs and parsing HTML for
//        the important information.  All parsing is done based on NSDictionary's that are provided by weather.xml.
//		  Currently, "fetching" is implemented using NSURLRequests.  The plan is to migrate to the CURLHandler
//		  framework to download for the next version.
//

#import "MEPrefs.h"
#import <Foundation/Foundation.h>

@class CURLHandle;

@interface MEWebFetcher : NSObject <NSURLHandleClient>
{
	CURLHandle *mURLHandle;
}

+ (MEWebFetcher *)sharedInstance;

- (NSString *)fetchURLtoString:(NSURL *)url;
- (NSString *)fetchURLtoString:(NSURL *)url withTimeout:(int)secs;
- (NSData *)fetchURLtoData:(NSURL *)url;
- (NSData *)fetchURLtoData:(NSURL *)url withTimeout:(int)secs;

@end

@interface MEWebParser : NSObject {

}

+ (NSArray *)performSearchOnURL:(NSURL *)url usingParseDict:(NSDictionary *)parseDict;
+ (NSArray *)performSearchOnURL:(NSURL *)url usingParseDict:(NSDictionary *)searchDict
											    withTimeout:(int)secs;

+ (NSArray *)parseURL:(NSURL *)url usingParseDict:(NSDictionary *)parseDict
								   usingParseArray:(NSArray *)parseArray;
@end