
#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "PlayerDataDelegate.h"
#import "REFrostedViewController.h"

@interface GraphViewController : UIViewController <CPTBarPlotDataSource, CPTBarPlotDelegate, PlayerDataDelegate> {
    
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealButtonItem;


@property (nonatomic, strong) IBOutlet CPTGraphHostingView *graphView;

//ploting methods
-(void)initPlot;
-(void)setupGraph;
-(void)setupAxes;

- (IBAction)showMenu;

@end
