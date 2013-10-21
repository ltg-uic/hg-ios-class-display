//
//  GameTimer.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/19/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

@interface GameTimer : NSObject {
    double start;
}

- (void) startTimer;


- (double) timeElapsedInMilliseconds;


@end
