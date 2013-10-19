//
//  GameTimer.m
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/19/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import "GameTimer.h"

@implementation GameTimer

- (id) init {
    self = [super init];
    if (self != nil) {
        start = nil;
        end = nil;
    }
    return self;
}

- (void) startTimer {
    start = [NSDate date];
}

- (void) stopTimer {
    end = [NSDate date];
}

- (double) timeElapsedInSeconds {
    return [end timeIntervalSinceDate:start];
}

- (double) timeElapsedInMilliseconds {
    return [self timeElapsedInSeconds] * 1000.0f;
}

- (double) timeElapsedInMinutes {
    return [self timeElapsedInSeconds] / 60.0f;
}

@end
