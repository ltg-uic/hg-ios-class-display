//
//  PopularViewController.m
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/24/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import "PopularViewController.h"

@interface PopularViewController ()

@end

@implementation PopularViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder])
    {
        self.appDelegate.playerDataDelegate = self;
        
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


#pragma mark - PLAYER DATA DELEGATE


-(void)resetMap {
    patch_a_label.text = @"";
    patch_b_label.text = @"";
    patch_c_label.text = @"";
    patch_d_label.text = @"";
    patch_e_label.text = @"";
    patch_f_label.text = @"";
}

-(void)graphNeedsUpdateWithProspering:(double)prosperingElapsed WithSurviving:(double)survivingElapsed WithStarving:(double)starvingElapsed {
    //used by the graph
    
}

-(void)graphNeedsUpdate {
    //used by the graph
}

-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint {

}

-(void)timeMapUpdateWithPatch:(NSString *)patch_id WithTime:(double)time {
    
    
    if( [patch_id isEqualToString:@"patch-a"] ) {
        patch_a_label.text = [NSString stringWithFormat:@"%.0f", trunc(time/60)];
    } else if( [patch_id isEqualToString:@"patch-b"] ) {
        patch_b_label.text = [NSString stringWithFormat:@"%.0f", trunc(time/60)];
    } else if( [patch_id isEqualToString:@"patch-c"] ) {
        patch_c_label.text = [NSString stringWithFormat:@"%.0f", trunc(time/60)];
    } else if( [patch_id isEqualToString:@"patch-d"] ) {
        patch_d_label.text = [NSString stringWithFormat:@"%.0f", trunc(time/60)];
    } else if( [patch_id isEqualToString:@"patch-e"] ) {
        patch_e_label.text = [NSString stringWithFormat:@"%.0f", trunc(time/60)];

    } else if( [patch_id isEqualToString:@"patch-f"] ) {
        patch_f_label.text = [NSString stringWithFormat:@"%.0f", trunc(time/60)];
        
    }
}




- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    
    [self.revealButtonItem setTarget: self.revealViewController];
    [self.revealButtonItem setAction: @selector( revealToggle: )];
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    
    
    
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.appDelegate.playerDataDelegate = self;
}



- (AppDelegate *)appDelegate
{
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


@end
