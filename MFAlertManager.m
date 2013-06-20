//
//  MFAlertManager.m
//  Meteorologist
//
//  Created by Matthew Fahrenbacher on Fri Mar 14 2003.
//  Copyright (c) 2004 The Meteorologist Group. All rights reserved.
//

#import "MFAlertManager.h"


@implementation MFAlertManager

- (void)awakeFromNib
{
	[weatherAlertsPanel setTitle:NSLocalizedString(@"weatherAlertPanelTitle",nil)];
	[killSoundsButton setTitle:NSLocalizedString(@"killSoundsButtonTitle",nil)];
	[clearLogButton setTitle:NSLocalizedString(@"clearLogButtonTitle",nil)];
}

- (id)init
{
    self = [super init];
    if(self)
        alertingCities = [NSMutableArray array];
	
    return self;
}

- (void)addCity:(NSArray *)array
{
    [self addCity:[array objectAtIndex:0]
	 alertOptions:[[array objectAtIndex:2] alertOptions]
			email:[[array objectAtIndex:2] alertEmail]
			  sms:[[array objectAtIndex:2] alertSMS]
			 song:[[array objectAtIndex:2] alertSong]
		  warning:[array objectAtIndex:1]];
}

- (void)addCity:(MECity *)city
   alertOptions:(int)options
		  email:(NSString *)email
		    sms:(NSString *)sms
		   song:(NSString *)song
		warning:(NSArray *)warn
{
    if((![alertingCities containsObject:city]) ||
	   ((alertCount != [warn count]) &&
		([warn count])))
	{
		alertCount = [warn count];
        [alertingCities addObject:city];
		BOOL bFirstTime = TRUE;
        
        NSString *warnMsg = NSLocalizedString(@"",nil);
        NSString *warnLink = NSLocalizedString(@"",nil);

        NSEnumerator *warnEnum = [warn objectEnumerator];
        NSDictionary *dict;
        
        while(dict = [warnEnum nextObject])
        {
			if (bFirstTime)
			{
				bFirstTime = FALSE;
			}
            NSString *temp;
            
            //if(temp = [dict objectForKey:@"title"])
			//{
                //warnMsg = [NSString stringWithFormat:@"%@%@\n",warnMsg,temp];
			//}
            
            temp = [dict objectForKey:@"link"];
            if(temp)
			{
                warnLink = [NSString stringWithFormat:@"%@",temp];
			}
			
            temp = [dict objectForKey:@"description"];
            if(temp)
			{
                warnMsg = [NSString stringWithFormat:@"%@%@\n",warnMsg,temp];
			}
			
        }

		warnMsg = [NSString stringWithFormat:@"%@\n\n%@\n\n%@",
				   warnLink,
				   [city cityName],
				   warnMsg];
		
		//email
		if(options & 1)
		{
			[emailer emailMessage:warnMsg toAccount:email];
		}
		//beep
		if(options & 2)
		{
			[beeper beginBeeping];
			options = (options | 16); //Force on a message
		}
		//song
		if(options & 4)
		{
			if(![player playSong:song])
				[beeper beginBeeping];
			options = options | 16; //Force on a message
		}
		//bounce
		if(options & 8)
		{
			[NSApp deactivate];
			[NSApp requestUserAttention:NSCriticalRequest];
			options = options | 16; //Force on a message
		}
		
		if(options & 16)
		{
			//display a text view with this info
			[displayer appendMessage:warnMsg];
		}
		//sms
		if(options & 32)
		{
			[emailer smsMessage:warnMsg toAccount:sms];
		}
    }
}

- (void)removeCity:(MECity *)city
{
    [alertingCities removeObjectIdenticalTo:city];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [self kill:nil];
}

- (IBAction)kill:(id)sender
{
    [beeper kill];
    [player kill];
}

@end


@implementation MFBeeper

- (id)init
{
    self = [super init];
    if(self)
    {
        timer = nil;
        killer = nil;
    }
    return self;
}

- (void)beginBeeping
{
    if(!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(beep) userInfo:nil repeats:YES];
        [timer setTolerance:0.2];
        killer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(kill) userInfo:nil repeats:NO];
        [killer setTolerance:30];
    }
}

- (void)beep
{
    NSBeep();
}

- (void)kill
{
    if(timer && [timer isValid])
        [timer invalidate];
    
    if(killer && [killer isValid])
        [killer invalidate];
    
    killer = nil;
    timer = nil;
}

@end


@implementation MFSongPlayer

- (id)init
{
    self = [super init];
    if(self)
    {
        movieView = [[NSMovieView alloc] init];
        [[[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1,1) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES] contentView] addSubview:movieView];
        [[movieView window] orderFront:nil];
        [[movieView window] setOpaque:NO];
        [[movieView window] setAlphaValue:0];

        killer = nil;
    }
    return self;
}

- (BOOL)playSong:(NSString *)path
{
    if(!movie)
    {
#ifdef __x86_64__
#else
        movie = [[[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:path] byReference:YES] autorelease];
        [movieView setMovie:movie];
        
        [movieView start:nil];
        killer = [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(kill) userInfo:nil repeats:NO];
        [killer setTolerance:30];
#endif
    }
    
    return (movie != nil);
}

- (void)kill
{
#ifdef __x86_64__
#else
    if(movie)
    {
        [movieView stop:nil];
        [movieView setMovie:nil];
        movie = nil;
    }
    
    if(killer && [killer isValid])
        [killer invalidate];
    
    killer = nil;
#endif
}

@end


@implementation MFMessageDisplay

- (void)appendMessage:(NSString *)msg
{
    [NSApp activateIgnoringOtherApps:YES];
    [[message window] makeKeyAndOrderFront:nil];
    [message setEditable:YES];
    [message setSelectedRange:NSMakeRange([[message string] length],0)];
    [message insertText:[NSString stringWithFormat:@"%@\n\n\n",msg]];
    [message setEditable:NO];
}

- (IBAction)clearLog:(id)sender
{
    [message setString:@""];
}

@end


@implementation MFEmailer

- (void)emailMessage:(NSString *)msg toAccount:(NSString *)email
{
	NSURL *     url;
	NSString *message;
	
    message = [NSString stringWithFormat:@"mailto:%@"
			   "?subject=%@"
			   "&body=%@",
			   email,@"Weather Alert",msg];

    // Create the URL.
	
    url = [NSURL URLWithString:(NSString*)
								CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)message,
																		NULL, NULL, kCFStringEncodingUTF8))];
    assert(url != nil);
	
    // Open the URL.
	
    (void) [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)smsMessage:(NSString *)msg toAccount:(NSString *)sms
{
	NSURL *     url;
	NSString *message;
	
    message = [NSString stringWithFormat:@"mailto:%@"
			   "?body=%@",
			   sms,msg];
	
    // Create the URL.
	
    url = [NSURL URLWithString:(NSString*)
								CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)message,
																		NULL, NULL, kCFStringEncodingUTF8))];
	//NSLog(@"Email URL: %@.",message);
    assert(url != nil);
	
    // Open the URL.
	
    (void) [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
