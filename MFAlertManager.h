//
//  MFAlertManager.h
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Fri Mar 14 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#ifdef __x86_64__
#import <QTKit/QTKit.h>
#define NSMovieView QTMovieView
#define NSMovie QTMovie
#else
#import <AppKit/AppKit.h>
#endif
//#import <Message/NSMailDelivery.h>
#import "MECity.h"

@class MFBeeper, MFSongPlayer, MFMessageDisplay, MFEmailer;

@interface MFAlertManager : NSObject 
{
	IBOutlet NSPanel *weatherAlertsPanel;
	
    NSMutableArray *alertingCities;
    
    IBOutlet MFBeeper *beeper;
    IBOutlet MFSongPlayer *player;
    IBOutlet MFMessageDisplay *displayer;
    IBOutlet MFEmailer *emailer;
	
	IBOutlet NSButton *killSoundsButton;
	IBOutlet NSButton *clearLogButton;
	int alertCount;
}

- (void)addCity:(NSArray *)array;
- (void)addCity:(MECity *)city
   alertOptions:(int)options
		  email:(NSString *)email
		    sms:(NSString *)sms
		   song:(NSString *)song
		warning:(NSArray *)warn;
- (void)removeCity:(MECity *)city;

- (IBAction)kill:(id)sender;

@end


@interface MFBeeper : NSObject
{
    NSTimer *timer;
    NSTimer *killer;
}

- (void)beginBeeping;
- (void)beep;
- (void)kill;

@end


@interface MFSongPlayer : NSObject
{
    NSMovieView *movieView;
    NSMovie *movie;
    NSTimer *timer;
    NSTimer *killer;
}

- (BOOL)playSong:(NSString *)path;
- (void)kill;

@end


@interface MFMessageDisplay : NSObject
{
    IBOutlet NSTextView *message;
}

- (void)appendMessage:(NSString *)msg;
- (IBAction)clearLog:(id)sender;

@end


@interface MFEmailer : NSObject
{
}

- (void)emailMessage:(NSString *)msg toAccount:(NSString *)email;
- (void)smsMessage:(NSString *)msg toAccount:(NSString *)email;

@end