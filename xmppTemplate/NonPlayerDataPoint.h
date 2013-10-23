//
//  NonPlayerDataPoint.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/11/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PlayerDataPoint.h"


@interface NonPlayerDataPoint : PlayerDataPoint

@property (nonatomic, retain) NSString * type;

@end
