//
//  AppDelegate.m
//  xmppTemplate
//
//  Created by Anthony Perritano on 9/14/12.
//  Copyright (c) 2012 Learning Technologies Group. All rights reserved.
//

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "PlayerDataPoint.h"
#import "PatchInfo.h"
#import "ConfigurationInfo.h"
#import "EventInfo.h"
#import "WizardClassPageViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SBJsonParser.h"
#import "AFNetworking.h"
#import "UIColor-Expanded.h"
#import "SidebarViewController.h"
#import "NonPlayerDataPoint.h"
#import "GameTimer.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
    static const int ddLogLevel = LOG_LEVEL_OFF;
#else
    static const int ddLogLevel = LOG_LEVEL_OFF;
#endif



@interface AppDelegate()<SWRevealViewControllerDelegate>{

    NSArray *patchInfos;
    NSOperationQueue *operationQueue;
    GameTimer *gameTimer;
    NSTimer *timer;
  
    double elapsedTime;
    double renderTime;
    double startTime;
    double previousElapsedTime;
    CADisplayLink *displayLink;
    BOOL hasStartTimer;
    double frameTimestamp;
}

@end

@implementation AppDelegate


#pragma mark APPDELEGATE METHODS

-(void)customizeGlobalAppearance {
    //[[UINavigationBar appearance] setValue:helveticaNeueMedium forKey:UITextAttributeFont];
    //[[UINavigationBar appearance] setValue:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor blackColor], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"helveticaNeue" size:21.0], NSFontAttributeName, nil]];

    

}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setupInterface];
    [self clearUserDefaults];
    //[self setupTestUser];
    //[self setupConfigurationAndRosterWithRunId:@"5ag"];
    [self pullConfigurationData];
    //Failed to instantiate the default view controller for UIMainStoryboardFile 'MainStoryboard_iPad' - perhaps the designated entry point is not set?[self setupTestUser];
    //[self setupConfigurationAndRosterWithRunId:@"5ag"];
    [self customizeGlobalAppearance];
    
    
    isMultiUserChat = YES;
    //setup test data
    
    [self deleteAllObjects:@"PlayerDataPoint"];
    [self deleteAllObjects:@"NonPlayerDataPoint"];
    [self deleteAllObjects:@"PatchInfo"];
    [self deleteAllObjects:@"ConfigurationInfo"];
    
    
    //[self pullConfigurationData];
    
    //[self importTestData];
  
    
    //setup test user
    //[self setupTestUser];
    
   
    
    //
    
    // Configure logging framework
	
	//[DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Setup the XMPP stream
    
	
    

    return YES;
}

-(void)setupInterface {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window = window;
	
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad"
                                                             bundle: nil];
    
    SidebarViewController *sideViewController = (SidebarViewController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"sidebarViewController"];
    
    UIViewController *mapViewController = (UIViewController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"mapViewController"];
    
    
    
	
	UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:mapViewController];
    
    [[sideViewController controllerMap] setObject:frontNavigationController forKey:@"mapViewController"];
    
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:sideViewController];
	
	SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
    revealController.delegate = self;
    
    
    
    //revealController.bounceBackOnOverdraw=NO;
    //revealController.stableDragOnOverdraw=YES;
    
	self.viewController = revealController;
	
	self.window.rootViewController = self.viewController;
	[self.window makeKeyAndVisible];
    
    
    
}

-(void)checkConnectionWithUser {
    if (![self connect] || _xmppStream == nil)
	{
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad"
                                                                     bundle: nil];
            
            UIViewController *controller = (UIViewController *)[mainStoryboard instantiateViewControllerWithIdentifier: @"WizardNavController"];
           // controller.modalPresentationStyle = UIModalPresentationFormSheet;
            
            
			[self.window.rootViewController presentViewController:controller animated:YES completion:nil];
		});
	}
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
   
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
#if TARGET_IPHONE_SIMULATOR
	DDLogError(@"The iPhone simulator does not process background network traffic. "
			   @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
	if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)])
	{
		[application setKeepAliveTimeout:600 handler:^{
			
			//DDLogVerbose(@"KeepAliveHandler");
			
			// Do other keep alive stuff here.
		}];
	}
    
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark XMPP SETUP STREAM

- (void)setupStream
{
	NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The xmppStream is the base class for all activity.
	// Everything else plugs into the __xmppStream, such as modules/extensions and delegates.
    
	_xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		_xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	_xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Activate xmpp modules
    
    //_xmppStream.hostName = XMPP_HOSTNAME;
    
    if( isMultiUserChat ) {
    //setup of room
  
        
        _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self jid:[self getRoomJID]];
        [_xmppRoom  activate:_xmppStream];
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
        
  	[_xmppReconnect activate:_xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
    [_xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;
}

-(XMPPJID *) getRoomJID {
    NSString *roomJID = [[NSUserDefaults standardUserDefaults] objectForKey:kXMPProomJID];
    XMPPJID *fullRoomJID = [XMPPJID jidWithString:[roomJID stringByAppendingString:XMPP_CONFERENCE_TAIL]];
    return fullRoomJID;
}
- (void)teardownStream
{
	[_xmppStream removeDelegate:self];
	[_xmppReconnect deactivate];
	[_xmppStream disconnect];
	
	_xmppStream = nil;
	_xmppReconnect = nil;
    
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

#pragma mark XMPP ONLINE OFFLINE

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[_xmppStream sendElement:presence];
    
    [_xmppBaseOnlineDelegate isAvailable:YES];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[_xmppStream sendElement:presence];
}

#pragma mark CONNECT/DISCONNECT

- (BOOL)connect
{
	if (![_xmppStream isDisconnected]) {
		return YES;
	}
    
	NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
	
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    

    
	[_xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    [_xmppStream setHostName:[[XMPPJID jidWithString:myJID] domain ] ];
    
	password = myPassword;
    
    
	NSError *error = nil;
	if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
        
		//DDLogError(@"ERROR CONNECTING\n: %@", error);
        
		return NO;
	}

	return YES;
}

- (void)disconnect
{
	[self goOffline];
	[_xmppStream disconnect];
}

#pragma mark XMPPStream DELEGATE

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = _xmppStream.hostName;
		NSString *virtualDomain = [_xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
	
	NSError *error = nil;
	
	if (![_xmppStream authenticateWithPassword:password error:&error])
	{
		DDLogError(@"Error authenticating: %@", error);
	} else {
        //play sound
        
    
    
    }
}

-(void)playLoginSound {
    NSString *logonSoundPath = [[NSBundle mainBundle] pathForResource:@"logon_sound" ofType:@"aif"];
    NSURL *logonSoundURL = [NSURL fileURLWithPath:logonSoundPath];
    
    SystemSoundID _logonSound;
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)logonSoundURL, &_logonSound);
    
    //Just sound
    //AudioServicesPlaySystemSound(_logonSound);
    
    //sound and vibrate
    AudioServicesPlayAlertSound(_logonSound);
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if( isMultiUserChat ) {
        NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
        [_xmppRoom joinRoomUsingNickname:myJID history:nil];
    }
    
	[self goOnline];
    
    [self playLoginSound];
  
    
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    
    
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];

    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message"
                                                        message:[myJID stringByAppendingString:@"DID NOT AUTH"]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Ok"
                                                          otherButtonTitles:nil];
    [alertView show];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    

	// A simple example of inbound message handling.
    if( [message isGroupChatMessageWithBody]) {
        NSString *msg = [[message elementForName:@"body"] stringValue];
        
        [self processXmppMessage:msg];
        

	} else if ([message isChatMessageWithBody]) {

        
        NSString *msg = [[message elementForName:@"body"] stringValue];
        
        
        NSString *from = [[message attributeForName:@"from"] stringValue];
        
        lastMessageDict = [[NSMutableDictionary alloc] init];
        [lastMessageDict setObject:msg forKey:@"msg"];
        [lastMessageDict setObject:from forKey:@"sender"];
        
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"test"
                                                                message:msg
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
			[alertView show];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			//localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
        //[_xmppBaseNewMessageDelegate newMessageReceived:lastMessageDict];

	}
}

-(void)processXmppMessage: (NSString *)msg {
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    
    NSDictionary *jsonObjects = [jsonParser objectWithString:msg];
    
    if( jsonObjects != nil){
        
        
        NSString *event = [jsonObjects objectForKey:@"event"];
        
        if( event != nil) {
            if( [event isEqualToString:@"reset_bout"] ) {
                _isGameRunning = NO;
                _hasReset = YES;
                
                [self resetGame];
                
            } else if([event isEqualToString:@"start_bout"] ) {
                _isGameRunning = YES;
                _hasReset = NO;
                [self startTimer];
            } else if( [event isEqualToString:@"stop_bout"] ) {
                _isGameRunning = NO;
                _hasReset = NO;
                [self stopTimer];
            } else if( [event isEqualToString:@"kill_tag"]) {
                NSDictionary *payload = [jsonObjects objectForKey:@"payload"];
                NSString *player_id = [payload objectForKey:@"id"];
                [_killList addObject:player_id];
            } else if( [event isEqualToString:@"resurrect_tag"]) {
                NSDictionary *payload = [jsonObjects objectForKey:@"payload"];
                NSString *player_id = [payload objectForKey:@"id"];
                [_killList removeObject:player_id];
            } else if( [event isEqualToString:@"rfid_update"] && (_isGameRunning == YES) ){
                
            
                NSDictionary *payload = [jsonObjects objectForKey:@"payload"];
                NSString *player_id = [payload objectForKey:@"id"];
                NSString *arrival_patch_id = [payload objectForKey:@"arrival"];
                NSString *departure_patch_id = [payload objectForKey:@"departure"];
                
                 PlayerDataPoint *player = [[_playerDataPoints filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"player_id == %@", player_id] ] objectAtIndex:0];
                
                if( [[NSNull null] isEqual: arrival_patch_id ] && [[NSNull null] isEqual: departure_patch_id ] ) {
                    [_patchPlayerMap setObject:[NSNull null] forKey:player.player_id];
                     player.currentPatch = nil;
                } else if( [ [NSNull null] isEqual: arrival_patch_id] && ![[NSNull null] isEqual: departure_patch_id ] ) {
                    [_patchPlayerMap setObject:[NSNull null] forKey:player.player_id];
                    player.currentPatch = nil;
                } else if( ![[NSNull null] isEqual: arrival_patch_id ]  ) {
                    [_patchPlayerMap setObject:arrival_patch_id forKey:player.player_id];
                    player.currentPatch = arrival_patch_id;
                }
                
                [_playerDataDelegate playerDataDidUpdateWithArrival:arrival_patch_id WithDeparture:departure_patch_id WithPlayerDataPoint:player];
            }
            
            
        }
    }
    
   // NSLog(@"message %@", msg);


}



- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
	//DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    
    NSString *presenceType = [presence type]; // online/offline
	NSString *myUsername = [[sender myJID] user];
	NSString *presenceFromUser = [[presence from] user];
	
	if ([presenceFromUser isEqualToString:myUsername]) {
		
		if ([presenceType isEqualToString:@"available"]) {
            
            NSString *t = [NSString stringWithFormat:@"%@@%@", presenceFromUser, @"jerry.local"];
            //DDLogVerbose(@"%@",t);
			
            [_xmppBaseOnlineDelegate isAvailable:YES];
			
		} else if ([presenceType isEqualToString:@"unavailable"]) {
			
            NSString *t = [NSString stringWithFormat:@"%@@%@", presenceFromUser, @"jerry.local"];
            //DDLogVerbose(@"%@",t);
            
            [_xmppBaseOnlineDelegate isAvailable:NO];
			
		}
		
	}
    
    
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
	{
		//DDLogError(@"Unable to connect to server. Check _xmppStream.hostName");
	}
}

#pragma mark - XMPP ROOM DELEGATE

- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
	DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
	//DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	[_xmppRoom fetchConfigurationForm];
	[_xmppRoom fetchBanList];
	[_xmppRoom fetchMembersList];
	[_xmppRoom fetchModeratorsList];
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{
    [_xmppBaseOnlineDelegate isAvailable:YES];
	//DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items
{
	//DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError
{
	//DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items
{
	//DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError
{
	//DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items
{
	DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError
{
	DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)handleDidLeaveRoom:(XMPPRoom *)room
{
	DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppRoom:(XMPPRoom *)sender didChangeOccupants:(NSDictionary *)occupants {
   // DDLogVerbose(@"xmpp room did receiveMessage");
    //this is not correct should tell when leaves room
    [_xmppBaseOnlineDelegate isAvailable:NO];
}

#pragma CONFIGURATION SETUP

-(void)setupConfigurationAndRosterWithRunId:(NSString *)run_id WithPatchId: (NSString*)currentPatchId {
    
    _configurationInfo = [self getConfigurationInfoWithRunId:run_id];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"player_id" ascending:NO selector:@selector(caseInsensitiveCompare:)];
    
    _playerDataPoints  = [[[_configurationInfo players] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    _patcheInfos = [[_configurationInfo patches] allObjects];

    
    [self setupPlayerMap];
    
    if( _xmppStream == nil ) {
        [self setupStream];
    } else {
        [_xmppRoom deactivate];
        _xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:self jid:[self getRoomJID]];
        [_xmppRoom  activate:_xmppStream];

    }
    
}


-(void)setupPlayerMap {
    if ( _patchPlayerMap == nil ) {
        
        _patchPlayerMap = [[NSMutableDictionary alloc] init];
        
        for( PlayerDataPoint *pdp in _playerDataPoints ) {
            if( pdp.currentPatch == nil ) {
                [_patchPlayerMap setObject:[NSNull null] forKey:pdp.player_id];
            } else {
                [_patchPlayerMap setObject:pdp.currentPatch forKey:pdp.player_id];
            }
        }
    }
}

-(void)resetPlayerMap {
    [_patchPlayerMap enumerateKeysAndObjectsUsingBlock:^(NSString *player_id, id patch_id, BOOL *stop){
        patch_id = [NSNull null];
    }];
}



#pragma mark - TIMER

- (void)startTimer {
    
    frameTimestamp = 0;
    elapsedTime = 0;
    hasStartTimer = NO;
    //start the game timer
    gameTimer = [[GameTimer alloc] init];
    [gameTimer startTimer];
    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshCalorieTotals)];
 
  

	[displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
}



- (void)stopTimer {
    //elapsedTime = 0;
    //frameTimestamp = 0;
    //elapsedTime = 0;
    hasStartTimer = NO;
    displayLink.paused = YES;
    
    
}

-(void) resetGame {
    _starvingElapsed = 0;
    _prosperousElapsed = 0;
    _survivingElapsed = 0;
    elapsedTime = 0;
    frameTimestamp = 0;
    startTime = 0;
    hasStartTimer = NO ;
    patch_a = 0;
    patch_b = 0;
    patch_c = 0;
    patch_d = 0;
    
    [displayLink invalidate];
    
    NSArray *players = [[_configurationInfo players] allObjects];
    
    for(PlayerDataPoint *pdp in players) {
        pdp.score = [NSNumber numberWithFloat:0];
        pdp.currentPatch = nil;
    }
    
    [self.managedObjectContext save:nil];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"player_id" ascending:NO selector:@selector(caseInsensitiveCompare:)];
    
    _playerDataPoints  = [[[_configurationInfo players] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    [_killList removeAllObjects];
    [self resetPlayerMap];
    
    [self setupPlayerMap];
    
    [_playerDataDelegate graphNeedsUpdateWithProspering:_prosperousElapsed WithSurviving:_survivingElapsed WithStarving:_starvingElapsed];
    
    [_playerDataDelegate resetMap];
    
}


-(void) refreshCalorieTotals {
    
    if( hasStartTimer == NO ) {
        startTime = [displayLink timestamp];
        hasStartTimer = YES;
    }
    
    double currentTime = [displayLink timestamp];
    elapsedTime =  currentTime - startTime;
	renderTime = currentTime - frameTimestamp;
	frameTimestamp = currentTime;
    [self updateDataOverlay];
    [self updatePlayerScores];
    [self calcPatchTimes];
    //NSLog(@"FRAME RATE  %f",1/renderTime);

   // NSLog(@"ELAPSED TIME %f",elapsedTime);
}

-(void)updateDataOverlay {

  //  if( _prosperousElapsed <= _configurationInfo.maximum_harvest ) {
    //starving
           
    _starvingElapsed = (_configurationInfo.starving_threshold/60) * elapsedTime;
   // NSLog(@"STARVING ELAPSED %f",_starvingElapsed);
    
    //surviving
   
    _survivingElapsed = ((_configurationInfo.prospering_threshold/60) * elapsedTime);
   // NSLog(@"SURVIVING ELAPSED %f",_survivingElapsed);
    
    //prosperous
    
    _prosperousElapsed = ((_configurationInfo.maximum_harvest/300) * elapsedTime);
    //NSLog(@"PROPSPERING ELAPSED %f",_prosperousElapsed);
    
        //NSLog(@"PROSPERING E APPD %f", _prosperousElapsed);
   // [_playerDataDelegate overlayNeedsUpdateWith:_starvingElapsed With:_survivingElapsed With:_prosperousElapsed];
}

double patch_a = 0;
double patch_b = 0;
double patch_c = 0;
double patch_d = 0;
double patch_e = 0;
double patch_f = 0;
-(void)updatePlayerScores {
 
        
        for(NSString * player_id in _patchPlayerMap) {
           
            
            
            if( [_patchPlayerMap objectForKey:player_id] != [NSNull null] ) {
                NSString *patch_id = [_patchPlayerMap objectForKey:player_id];
                NSArray *pis = [_patcheInfos filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"patch_id == %@", patch_id]];
                
                if( pis != nil && pis.count > 0) {
                    
                    PatchInfo *patchInfo = [pis objectAtIndex:0];
                    
                    NSArray *playersAtPatch = [_playerDataPoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"currentPatch == %@", patch_id]];
                    
                    if( playersAtPatch != nil  && playersAtPatch.count > 0 ) {
                        
                        NSMutableArray *playersNotKilled = [[NSMutableArray alloc] init];
                        
                        for( PlayerDataPoint *p in playersAtPatch ) {
                            if( [_killList containsObject:p.player_id] == NO) {
                                [playersNotKilled addObject:p];
                            }
                        }
                        
                        NSArray *thePlayers = [_playerDataPoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"player_id == %@", player_id]];
                        
                        if( (thePlayers != nil && thePlayers.count > 0 ) && playersNotKilled.count > 0 ) {
                            
                            PlayerDataPoint *pdp = [thePlayers objectAtIndex:0];
                            
                            if( [pdp.score floatValue] <= _configurationInfo.maximum_harvest ) {
                            
                                if( ![_killList containsObject:pdp.player_id] ) {
                                    //number of the patches at the patch
                                    int numberOfPlayerAtPatches = playersNotKilled.count;
                                    
                                    //get the old
                                    float playerOldScore = [pdp.score floatValue];
                                    
                                    //calc new richness
                                    float adjustedRate = ((patchInfo.quality_per_second * renderTime) / numberOfPlayerAtPatches );
                                    
                                   
                                    
                                    //NSLog(@"ADJUSTED %@ RATE %f",pdp.player_id, adjustedRate);

                                    //figure out the adjusted rate for the refreshrate
                                    //float adjustedRate = (adjustedRichness) * _refreshRate;
                                    
                                    pdp.score = [NSNumber numberWithFloat:(playerOldScore + adjustedRate)];
                                    
                                   // NSLog(@"PLAYER %@ NEW score %f",pdp.player_id, [pdp.score floatValue]);
                                }
                            }
                        }
                        
                    }
                    
                }
              
            }
            
        }
        

    [_playerDataDelegate graphNeedsUpdateWithProspering:_prosperousElapsed WithSurviving:_survivingElapsed WithStarving:_starvingElapsed];
}

-(void)calcPatchTimes {
    
    for(PatchInfo *patch in _patcheInfos) {
        
        NSArray *playersAtPatch = [_playerDataPoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"currentPatch == %@", patch.patch_id]];
        NSMutableArray *playersNotKilled = [[NSMutableArray alloc] init];
        
        for( PlayerDataPoint *p in playersAtPatch ) {
            if( [_killList containsObject:p.player_id] == NO) {
                [playersNotKilled addObject:p];
            }
        }
        
        if( [patch.patch_id isEqual:@"patch-a"] ) {
            patch_a += renderTime * playersNotKilled.count;
            [_playerDataDelegate timeMapUpdateWithPatch:patch.patch_id WithTime:patch_a];
           // NSLog(@"PATCH A TIME %f",patch_a);
        } else if( [patch.patch_id isEqual:@"patch-b"] ) {
            patch_b += renderTime * playersNotKilled.count;
            [_playerDataDelegate timeMapUpdateWithPatch:patch.patch_id WithTime:patch_b];
            //NSLog(@"PATCH B TIME %f",patch_b);
        } else if( [patch.patch_id isEqual:@"patch-c"] ) {
            patch_c += renderTime * playersNotKilled.count;
            [_playerDataDelegate timeMapUpdateWithPatch:patch.patch_id WithTime:patch_c];
            //NSLog(@"PATCH C TIME %f",patch_c);
        } else if( [patch.patch_id isEqual:@"patch-d"] ) {
            patch_d += renderTime * playersNotKilled.count;
            [_playerDataDelegate timeMapUpdateWithPatch:patch.patch_id WithTime:patch_d];
            //NSLog(@"PATCH D TIME %f",patch_d);
        } else if( [patch.patch_id isEqual:@"patch-e"] ) {
            patch_e += renderTime * playersNotKilled.count;
            [_playerDataDelegate timeMapUpdateWithPatch:patch.patch_id WithTime:patch_e];
            //NSLog(@"PATCH E TIME %f",patch_e);
        }else if( [patch.patch_id isEqual:@"patch-f"] ) {
            patch_f += renderTime * playersNotKilled.count;
            [_playerDataDelegate timeMapUpdateWithPatch:patch.patch_id WithTime:patch_f];
            //NSLog(@"PATCH F TIME %f",patch_f);
        }
        
        
    }
    
    
}

#pragma NETWORK OPERATIONS

-(void)pullConfigurationData {
    
    NSURL *url = [NSURL URLWithString:@"http://ltg.evl.uic.edu:9292/hunger-games-fall-13/configuration"];
    operationQueue = [[NSOperationQueue alloc] init];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //AFNetworking asynchronous url request
    AFJSONRequestOperation *operation1 = [AFJSONRequestOperation
                                         JSONRequestOperationWithRequest:request
                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseObject)
                                         {
                                             //NSLog(@"JSON RESULT %@", responseObject);
                                             
                                             
                                             for(NSDictionary *someConfig in responseObject) {
                                                 
                                                 
                                                 NSString *run_id = [someConfig objectForKey:@"run_id"];
                                                 NSString *boutLength = [someConfig objectForKey:@"harvest_calculator_bout_length_in_minutes"];
                                                 NSArray *patches = [someConfig objectForKey:@"patches"];
                                                 
                                                 NSString *maximum_harvest = [someConfig objectForKey:@"maximum_harvest"];
                                                 NSString *predation_penalty_length_in_seconds = [someConfig objectForKey:@"predation_penalty_length_in_seconds"];
                                                 NSString *prospering_threshold = [someConfig objectForKey:@"prospering_threshold"];
                                                 NSString *starving_threshold = [someConfig objectForKey:@"starving_threshold"];
                                                 
                                                 
                                                 ConfigurationInfo *ci = [self insertConfigurationWithRunId:run_id withHarvestCalculatorBoutLengthInMinutes:[boutLength floatValue] WithMaximumHarvest:[maximum_harvest floatValue] WithPredationPenalty: [predation_penalty_length_in_seconds floatValue] WithProperingThreshold: [prospering_threshold floatValue] WithStravingThreshold: [starving_threshold floatValue ]];
                                                 
                                                 for(NSDictionary *somePatch in patches) {
                                                     
                                                     NSString *patch_id = [somePatch objectForKey:@"patch_id"];
                                                     NSString *patch_label = [somePatch objectForKey:@"patch_label"];
                                                     float reader_id = [[somePatch objectForKey:@"reader_id"] floatValue];
                                                     NSString * risk_label = [somePatch objectForKey:@"risk_label"];
                                                     float risk_percent_per_second = [[somePatch objectForKey:@"risk_percent_per_second"] floatValue];
                                                     NSString *quality = [somePatch objectForKey:@"quality"];
                                                     float qualityPerMinute = [[somePatch objectForKey:@"quality_per_minute"] floatValue];
                                                     float qualityPerSecond = [[somePatch objectForKey:@"quality_per_second"] floatValue];
                                                     
                                            
                                                     PatchInfo *pi = [self insertPatchInfoWithPatchId:patch_id WithPatchLabel:patch_label WithReaderId:reader_id withQuality:quality withQualityPerSecond:qualityPerSecond withQualityPerMinute:qualityPerMinute WithRiskLabel:risk_label WithRiskPercentPerSecond:risk_percent_per_second];
                                                     
                                                     
                                                     [ci addPatchesObject:pi];
                                                 }
                                                 
                                                 [self.managedObjectContext save:nil];
                                                 
                                                 
                                                 [operationQueue addOperation:[self pullRosterDataWithRunId:ci WithCompletionBlock:nil]];
                                             }
                                             
                                             [operationQueue addOperationWithBlock:^{
                                             
                                                  [self checkConnectionWithUser];
                                             
                                             }];
                                         }
                                         
                                         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id responseObject)
                                         {
                                             NSLog(@"Request Failed: %@, %@", error, error.userInfo);
                                         }];
    
    [operationQueue waitUntilAllOperationsAreFinished];
    [operationQueue setMaxConcurrentOperationCount:1];
    [operationQueue addOperation:operation1];
}

-(NSOperation *)pullRosterDataWithRunId:(ConfigurationInfo *)configurationInfo WithCompletionBlock:(void(^)())block  {
    NSURL *url = [NSURL URLWithString:[@"http://ltg.evl.uic.edu:9000/runs/" stringByAppendingString:configurationInfo.run_id]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //AFNetworking asynchronous url request
    AFJSONRequestOperation *operation = [AFJSONRequestOperation
                                         JSONRequestOperationWithRequest:request
                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id responseObject)
                                         {
                                             //NSLog(@"JSON RESULT %@", responseObject);
                                             
                                             
                                             NSDictionary *data = [responseObject objectForKey:@"data"];
                                             NSArray *students = [data objectForKey:@"roster"];
                                             
                                             for (NSDictionary *someStudent in students) {
                                                 
                                                 BOOL isStudent = YES;
                                                 
                                                 NSString *rfid = [someStudent objectForKey:@"rfid_tag"];
                                                 
                                                 if( rfid == nil ) {
                                                     isStudent = NO;
                                                      NonPlayerDataPoint *npdp = [self insertNonPlayerDataPointWithColor:[someStudent objectForKey:@"color"] WithLabel:[someStudent objectForKey:@"label"] WithPatch:nil WithRfid:[someStudent objectForKey:@"rfid_tag"] WithScore:[NSNumber numberWithInt:0] WithId:[someStudent objectForKey:@"_id"] asStudent:isStudent WithType:@"teacher"];
                                                     [configurationInfo addNonPlayersObject:npdp];
                                                 } else {
                                                     PlayerDataPoint *pdp = [self insertPlayerDataPointWithColor:[someStudent objectForKey:@"color"] WithLabel:[someStudent objectForKey:@"label"] WithPatch:nil WithRfid:[someStudent objectForKey:@"rfid_tag"] WithScore:[NSNumber numberWithInt:0] WithId:[someStudent objectForKey:@"_id"] asStudent:isStudent];
                                                     
                                                     [configurationInfo addPlayersObject:pdp];
                                                 }
                                                 
                                            
                                                 
                                                
                                             }
                                             

                                             [self.managedObjectContext save:nil];
                                             
                                         }
                                         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id responseObject)
                                         {
                                             NSLog(@"Request Failed: %@, %@", error, error.userInfo);
                                         }];
    

  
    return operation;
}


#pragma mark CORE DATA DELETES

- (void) deleteAllObjects: (NSString *) entityDescription  {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext: [self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [[self managedObjectContext ] executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
    	[[self managedObjectContext ] deleteObject:managedObject];
    	NSLog(@"%@ object deleted",entityDescription);
    }
    if (![[self managedObjectContext ] save:&error]) {
    	NSLog(@"Error deleting %@ - error:%@",entityDescription,error);
    }
    
}


#pragma mark CORE DATA INSERTS

-(PatchInfo *)insertPatchInfoWithPatchId: (NSString *)patch_id WithPatchLabel:(NSString *)patch_label WithReaderId:(float)reader_id withQuality:(NSString*)quality withQualityPerSecond: (float)quality_per_second withQualityPerMinute:(float)quality_per_minute WithRiskLabel:(NSString*)risk_label WithRiskPercentPerSecond:(float)risk_percent_per_second {
    
    PatchInfo *pi = [NSEntityDescription insertNewObjectForEntityForName:@"PatchInfo"
                                                  inManagedObjectContext:self.managedObjectContext];
    
    pi.patch_id = patch_id;
    pi.reader_id = reader_id;
    pi.patch_label = patch_label;
    pi.quality = quality;
    pi.quality_per_minute = quality_per_minute;
    pi.quality_per_second = quality_per_second;
    pi.risk_percent_per_second = risk_percent_per_second;
    
    return pi;
}



-(ConfigurationInfo *)insertConfigurationWithRunId: (NSString *)run_id withHarvestCalculatorBoutLengthInMinutes:(float)harvest_calculator_bout_length_in_minutes WithMaximumHarvest:(float)maximum_harvest WithPredationPenalty: (float)predation_penalty_length_in_seconds WithProperingThreshold: (float)prospering_threshold WithStravingThreshold: (float)starving_threshold {

    
    ConfigurationInfo *ci = [NSEntityDescription insertNewObjectForEntityForName:@"ConfigurationInfo"
                                                  inManagedObjectContext:self.managedObjectContext];
    
    ci.run_id = run_id;
    ci.harvest_calculator_bout_length_in_minutes = harvest_calculator_bout_length_in_minutes;
    ci.maximum_harvest = maximum_harvest;
    //ci.maximum_harvest = 3000;
    //ci.prospering_threshold = 270;
    //ci.starving_threshold = 240;
    ci.predation_penalty_length_in_seconds = predation_penalty_length_in_seconds;
    ci.prospering_threshold = prospering_threshold;
    ci.starving_threshold = starving_threshold;
    ci.players = nil;

    return ci;
}


-(NonPlayerDataPoint *)insertNonPlayerDataPointWithColor:(NSString *)color WithLabel:(NSString *)label WithPatch:(NSString *)patch WithRfid:(NSString *)rfid_tag WithScore:(NSNumber *)score WithId: (NSString *)player_id asStudent:(BOOL) isStudent WithType: (NSString *)type{
    NonPlayerDataPoint *pdp = [NSEntityDescription insertNewObjectForEntityForName:@"NonPlayerDataPoint"
                                                         inManagedObjectContext:self.managedObjectContext];
    pdp.color = color;
    pdp.currentPatch = patch;
    pdp.rfid_tag = rfid_tag;
    pdp.score = [NSNumber numberWithInt:(arc4random() % 1000)];
    pdp.player_id = player_id;
    pdp.student = [NSNumber numberWithBool:isStudent];
    pdp.type = type;
    
    if( _colorMap == nil ) {
        _colorMap = [[NSMutableDictionary alloc] init];
    }
    
    if( color != nil ) {
        UIColor *hexColor = [UIColor colorWithHexString:[color stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        [_colorMap setObject:hexColor forKey:color];
    } else {
        
        color = [NSString stringWithFormat:@"black%d",(arc4random() % 10)];
        pdp.color = color;
        [_colorMap setObject:[UIColor redColor] forKey:color];
    }
    
    
    
    
    
    
    return pdp;
}


-(PlayerDataPoint *)insertPlayerDataPointWithColor:(NSString *)color WithLabel:(NSString *)label WithPatch:(NSString *)patch WithRfid:(NSString *)rfid_tag WithScore:(NSNumber *)score WithId: (NSString *)player_id asStudent:(BOOL) isStudent {
    PlayerDataPoint *pdp = [NSEntityDescription insertNewObjectForEntityForName:@"PlayerDataPoint"
                                                         inManagedObjectContext:self.managedObjectContext];
    pdp.color = color;
    pdp.currentPatch = patch;
    pdp.rfid_tag = rfid_tag;
    pdp.score =score;
    //pdp.score = [NSNumber numberWithInt:(arc4random() % 1000)];
    pdp.player_id = player_id;
    pdp.student = [NSNumber numberWithBool:isStudent];
    
    if( _colorMap == nil ) {
        _colorMap = [[NSMutableDictionary alloc] init];
    }
    
    if( color != nil ) {
        UIColor *hexColor = [UIColor colorWithHexString:[color stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        [_colorMap setObject:hexColor forKey:color];
    } else {
        
        color = [NSString stringWithFormat:@"black%d",(arc4random() % 10)];
        pdp.color = color;
        [_colorMap setObject:[UIColor redColor] forKey:color];
    }
   
    
   
    
    
    
    return pdp;
}



-(void)createEventInfoWithRFID: (NSString *)rfid WithEventType: (NSString *)eventType WithScore: (NSNumber *) score {
    EventInfo *ei = [NSEntityDescription insertNewObjectForEntityForName:@"EventInfo"
                                                  inManagedObjectContext:self.managedObjectContext];
    ei.rfid = rfid;
    ei.event_type = eventType;
    ei.score = score;
    ei.timestamp = [NSDate date];
    
    [self.managedObjectContext save:nil];
}

#pragma mark CORE DATA FETCHES

-(PlayerDataPoint *)getPlayerDataPointWithRFID: (NSString *)rfid {
    NSManagedObjectModel* model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest* request = [model fetchRequestFromTemplateWithName:@"playerDataPointWithRFID" substitutionVariables:@{@"RFID" : rfid}];
    NSError* error = nil;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( results.count == 0 ) {
        return nil;
    }
    
    return [results objectAtIndex:0];
}

-(NSArray *)getAllPatchInfos {
    NSManagedObjectModel* model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest* request = [model fetchRequestFromTemplateWithName:@"allPatchInfos" substitutionVariables:nil];
    NSError* error = nil;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    return results;
    
}

-(NSArray *)getAllPlayerDataPoints {
    NSManagedObjectModel* model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest* request = [model fetchRequestFromTemplateWithName:@"allPlayerDataPoints" substitutionVariables:nil];
    NSError* error = nil;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    return results;
    
}

-(NSArray *)getAllNonPlayerDataPoints {
    NSManagedObjectModel* model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest* request = [model fetchRequestFromTemplateWithName:@"allNonPlayerDataPoints" substitutionVariables:nil];
    NSError* error = nil;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    return results;
    
}

-(NSArray *)getAllConfigurationsInfos {
    NSManagedObjectModel* model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest* request = [model fetchRequestTemplateForName:@"allConfigurationInfos"];
    NSError* error = nil;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( results.count == 0 ) {
        return nil;
    }
    
    return results;
    
}

-(ConfigurationInfo *)getConfigurationInfoWithRunId: (NSString *)run_id {
    NSManagedObjectModel* model = [[self.managedObjectContext persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest* request = [model fetchRequestFromTemplateWithName:@"configurationInfoWithRunId"
                                                substitutionVariables:@{@"RUN_ID" : run_id}];
    NSError* error = nil;
    NSArray* results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( results.count == 0 ) {
        return nil;
    }
    
    return [results objectAtIndex:0];
}



- (void)importCoreDataDefaultGraphWithConfigurationInfo:(ConfigurationInfo *)configurationInfo {
    
    NSLog(@"Importing Core Data Default Values for Graph.......");

    NSLog(@"Importing Core Data Default Values for Graph Completed!");
}



-(void)importTestData {
    NSLog(@"Importing Core Data Default Values for DataPoints...");
    
    
    //[self createConfigurationWithRunId:@"test-run" withHarvestCalculatorBoutLengthInMinutes:5.0];
    
    ConfigurationInfo *ci = [self getConfigurationInfoWithRunId:@"test-run"];
    
    [self importCoreDataDefaultGraphWithConfigurationInfo:ci];
    
    //[self setupConfigurationAndRosterWithRunId:@"test-run"];
    
    
//    [self insertDataPointWith:@"Obama" To:@"Biden" WithMessage:@"Don't fuck up"];
//    [self insertDataPointWith:@"TEster" To:@"Biden" WithMessage:@"Don't fuck up asshole"];
    NSLog(@"Importing Core Data Default Values for DataPoints Completed!");
}

-(void)setupTestUser {
    [[NSUserDefaults standardUserDefaults] setObject:@"tester@ltg.evl.uic.edu" forKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults] setObject:@"tester" forKey:kXMPPmyPassword];
}

-(void)clearUserDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kXMPPmyPassword];
    _killList = [[NSMutableArray alloc] init];

}

#pragma mark XMPPRoomStorage PROTOCOL


- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room
{
    
}

- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    
}

- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    
}

- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
	return YES;
}

#pragma mark CoreDataManagement PROTOCOL

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)saveContext
{
    
    NSError *error = nil;
    NSManagedObjectContext *objectContext = self.managedObjectContext;
    if (objectContext != nil)
    {
        if ([objectContext hasChanges] && ![objectContext save:&error])
        {
            // add error handling here
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    
    if (managedObjectContext != nil)
    {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil)
    {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    
    if (persistentStoreCoordinator != nil)
    {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"localdb.sqlite"];
    
    NSError *error = nil;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return persistentStoreCoordinator;
}

@end
