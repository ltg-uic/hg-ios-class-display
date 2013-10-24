//
//  PlayerDataDelegate.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 9/7/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import "PlayerDataPoint.h"

@protocol PlayerDataDelegate


-(void)graphNeedsUpdateWithProspering:(double)prosperingElapsed WithSurviving:(double)survivingElapsed WithStarving:(double)starvingElapsed;

-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint;

-(void)resetMap;

-(void)timeMapUpdateWithPatch:(NSString *)patch_id WithTime:(double)time;

@end
