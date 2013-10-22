//
//  ViewController.m
//  SidebarDemo
//
//  Created by Simon on 28/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "MapViewController.h"
#import "PatchMapUIView.h"
#import "PlayerMapUIView.h"
#import "PatchInfo.h"
#import "UIColor-Expanded.h"
#import "UIView+Animation.h"
#import "SWRevealViewController.h"

@interface MapViewController () {
    NSArray *patchInfos;
    NSMutableDictionary *playersAndViews;
    NSDictionary *patchRects;
    NSMutableDictionary *playersAtPatch;
}

@end

@implementation MapViewController


- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder])
    {
        self.appDelegate.playerDataDelegate = self;
        playersAndViews = [[NSMutableDictionary alloc] init];

    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
       
        
    }
    return self;
}


-(void)setupPatches {
    
    NSSet *players = [[[self appDelegate] configurationInfo ] players];
    playersAtPatch = [[self appDelegate] patchPlayerMap];
    
    patchRects = @{ @"patch-a" : [NSValue valueWithCGRect:CGRectMake(764,508,200,175)], @"patch-b" : [NSValue valueWithCGRect:CGRectMake(391,500,291,176)], @"patch-c" : [NSValue valueWithCGRect:CGRectMake(0,550,283,176)], @"patch-d" : [NSValue valueWithCGRect:CGRectMake(0,340,260,197)], @"patch-e" : [NSValue valueWithCGRect:CGRectMake(0,44,260,260)], @"patch-f" : [NSValue valueWithCGRect:CGRectMake(406,44,260,260)] };
    
    
    int i = 60;
    for (PlayerDataPoint *pdp in players) {
        
        PlayerMapUIView *pmp = [[PlayerMapUIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        
        i = i + 60;
        UIColor *hexColor = [UIColor colorWithHexString:[pdp.color stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        pmp.uiColor = hexColor;
        pmp.backgroundColor = [UIColor clearColor];
        pmp.player_id = pdp.player_id;
        pmp.nameLabel.text = [pdp.player_id uppercaseString];
        pmp.nameLabel.textColor = [self getTextColor:hexColor];
        pmp.hidden = YES;
        pmp.tag = pdp.player_id;
        [playersAndViews setObject:pmp forKey:pdp.player_id];
        
     
    
        //[self.view addSubview:pmp];
    }
}

-(void)updateMapFromCache {
    [playersAtPatch enumerateKeysAndObjectsUsingBlock: ^(NSString *player_id, NSString *patch_id, BOOL *stop) {
        
        PlayerMapUIView *moveMe = (PlayerMapUIView*)[self.view viewWithTag:player_id];
        if( moveMe == nil ) {
            PlayerMapUIView *pmp = [playersAndViews objectForKey:player_id];
            [self addPlayerToMapWith:pmp WithPatch:patch_id];
        } else {
            PlayerMapUIView *moveMe = (PlayerMapUIView*)[self.view viewWithTag:player_id];
            
            CGPoint point = [self placePlayerWithPatchId:patch_id];
            
            
            [moveMe moveTo:point duration:.4 option:UIViewAnimationOptionCurveEaseInOut];
        }
        
     
    }];
}

#pragma mark - PLAYER DATA DELEGATE



-(void)playerDataDidUpdate {
    
        [self setupPatches];
 
}

-(void)checkGameReset {
    
    if( self.appDelegate.hasReset == YES ) {
        [playersAndViews enumerateKeysAndObjectsUsingBlock: ^(NSString *key, PlayerMapUIView *pmp, BOOL *stop) {
            pmp.frame = CGRectMake(0,0,60,60);
            pmp.hidden = NO;
        }];
    }
}

-(void)graphNeedsUpdateWithProspering:(double)prosperingElapsed WithSurviving:(double)survivingElapsed WithStarving:(double)starvingElapsed {
    //used by the graph
}

-(void)graphNeedsUpdate {
  //used by the graph
}

-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint {
    
    
    if(_hasInitialized == NO ) {
        [self setupPatches];
    } else {
       _hasInitialized = YES;
    }
    
    
    //[self updateMapFromCache];
    
    //first time arriving in the game
    if( ![[NSNull null] isEqual: arrival_patch_id ] && [[NSNull null] isEqual: departure_patch_id ] ) {
    
        //get the view
        PlayerMapUIView *pmp = [playersAndViews objectForKey:playerDataPoint.player_id];
        [self addPlayerToMapWith:pmp WithPatch:arrival_patch_id];
      

        
    } else if( [ [NSNull null] isEqual: arrival_patch_id] && ![[NSNull null] isEqual: departure_patch_id ] ) {
        //reset
        
        //get the view
        PlayerMapUIView *pmp = [playersAndViews objectForKey:playerDataPoint.player_id];
        
        PlayerMapUIView *moveMe = (PlayerMapUIView*)[self.view viewWithTag:pmp.tag];

        [moveMe removeSubviewWithFadeAnimationWithDuration:.8 option:nil];
        
    } else if( ![[NSNull null] isEqual: arrival_patch_id ] && ![[NSNull null] isEqual: departure_patch_id ]  ) {
        //get the view
        PlayerMapUIView *pmp = [playersAndViews objectForKey:playerDataPoint.player_id];
        
        PlayerMapUIView *moveMe = (PlayerMapUIView*)[self.view viewWithTag:pmp.tag];
        
        CGPoint point = [self placePlayerWithPatchId:arrival_patch_id];

        
        [moveMe moveTo:point duration:.4 option:UIViewAnimationOptionCurveEaseInOut];
    }
    
    
}

-(void)addPlayerToMapWith:(PlayerMapUIView *)pmp WithPatch:(NSString *)arrival_patch_id {
    CGPoint point = [self placePlayerWithPatchId:arrival_patch_id];
    
    pmp.frame = CGRectMake(point.x, point.y, pmp.frame.size.width,pmp.frame.size.height);
    pmp.hidden = NO;
    
    //[playersAndViews setObject:pmp forKey:playerDataPoint.player_id];
    [self.view addSubviewWithFadeAnimation:pmp duration:.8 option:nil];
}


-(CGPoint)placePlayerWithPatchId:(NSString *)patchId {
    //get the patch bounds
    CGRect rect = [[patchRects objectForKey:patchId] CGRectValue];
    int x = [self randomLocationBetween:ceil(rect.origin.x) and:ceil(rect.origin.x+rect.size.width)];
    int y = [self randomLocationBetween:ceil(rect.origin.y) and:ceil(rect.origin.y+rect.size.height)];
    
    return CGPointMake(x,y);
}

-(int)randomLocationBetween:(int)lowerBound and:(int)upperBound {
    int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
    return rndValue;
}

- (UIColor *) getTextColor:(UIColor *)color
{
    const CGFloat *componentColors = CGColorGetComponents(color.CGColor);
    
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    if (colorBrightness < 0.3)
    {
        //NSLog(@"my color is dark");
        return [UIColor whiteColor];
    }
    else
    {
        //NSLog(@"my color is light");
        return [UIColor blackColor];
    }
}

- (IBAction)showMenu {
    [self.frostedViewController presentMenuViewController];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    //self.title = @"News";

    // Change button color
    //_sidebarButton.tintColor = [UIColor colorWithWhite:0.96f alpha:0.2f];

    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    
    [self.revealButtonItem setTarget: self.revealViewController];
    [self.revealButtonItem setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];


    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
   
    //check player map
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.appDelegate.playerDataDelegate = self;
    [self updateMapFromCache];
}

-(PatchMapUIView *)createPatchViewsWithPatchInfo:(PatchInfo *)patchInfo AtX:(int)x AtY:(int)y  {

    
    PatchMapUIView *patchView = [[PatchMapUIView alloc] init];
    
    CGRect frame = patchView.frame;
    frame.origin.x = x;
    frame.origin.y = y;

    patchView.frame = frame;
    patchView.richness.text = [NSString stringWithFormat:@"%.0f", patchInfo.quality_per_minute];
    patchView.title.text = patchInfo.patch_id;
    [patchView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    return patchView;
    
}

- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
