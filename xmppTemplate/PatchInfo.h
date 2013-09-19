//
//  PatchInfo.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 9/18/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ConfigurationInfo;

@interface PatchInfo : NSManagedObject

@property (nonatomic, retain) NSString * patch_id;
@property (nonatomic, retain) NSString * patch_label;
@property (nonatomic) float quality_per_minute;
@property (nonatomic) float quality_per_second;
@property (nonatomic) float reader_id;
@property (nonatomic, retain) NSString * quality;
@property (nonatomic, retain) NSString * risk_label;
@property (nonatomic) float risk_percent_per_second;
@property (nonatomic, retain) ConfigurationInfo *configurationInfo;

@end
