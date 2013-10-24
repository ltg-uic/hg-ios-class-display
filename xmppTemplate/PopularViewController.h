//
//  PopularViewController.h
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/24/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopularViewController : UIViewController<PlayerDataDelegate> {
    
    __weak IBOutlet UILabel *patch_a_label;
    __weak IBOutlet UILabel *patch_b_label;
    __weak IBOutlet UILabel *patch_c_label;
    __weak IBOutlet UILabel *patch_d_label;
    __weak IBOutlet UILabel *patch_e_label;
    __weak IBOutlet UILabel *patch_f_label;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealButtonItem;


@end
