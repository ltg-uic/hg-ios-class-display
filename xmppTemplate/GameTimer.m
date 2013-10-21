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
        start = 0;
    }
    return self;
}

- (void) startTimer {
    start =  CACurrentMediaTime();
}

- (double) timeElapsedInMilliseconds {
    return CACurrentMediaTime() - start;
}

@end
