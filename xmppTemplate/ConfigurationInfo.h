//
//  ConfigurationInfo.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/11/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NonPlayerDataPoint, PatchInfo, PlayerDataPoint;

@interface ConfigurationInfo : NSManagedObject

@property (nonatomic) float harvest_calculator_bout_length_in_minutes;
@property (nonatomic) float maximum_harvest;
@property (nonatomic) float predation_penalty_length_in_seconds;
@property (nonatomic) float prospering_threshold;
@property (nonatomic, retain) NSString * run_id;
@property (nonatomic) float starving_threshold;
@property (nonatomic, retain) NSSet *patches;
@property (nonatomic, retain) NSSet *players;
@property (nonatomic, retain) NSSet *nonPlayers;
@end

@interface ConfigurationInfo (CoreDataGeneratedAccessors)

- (void)addPatchesObject:(PatchInfo *)value;
- (void)removePatchesObject:(PatchInfo *)value;
- (void)addPatches:(NSSet *)values;
- (void)removePatches:(NSSet *)values;

- (void)addPlayersObject:(PlayerDataPoint *)value;
- (void)removePlayersObject:(PlayerDataPoint *)value;
- (void)addPlayers:(NSSet *)values;
- (void)removePlayers:(NSSet *)values;

- (void)addNonPlayersObject:(NonPlayerDataPoint *)value;
- (void)removeNonPlayersObject:(NonPlayerDataPoint *)value;
- (void)addNonPlayers:(NSSet *)values;
- (void)removeNonPlayers:(NSSet *)values;

@end
