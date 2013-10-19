//
//  GameTimer.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/19/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

@interface GameTimer : NSObject {
    NSDate *start;
    NSDate *end;
}

- (void) startTimer;
- (void) stopTimer;
- (double) timeElapsedInSeconds;
- (double) timeElapsedInMilliseconds;
- (double) timeElapsedInMinutes;

@end
