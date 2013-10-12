//
//  MapViewController.m
//  RevealControllerStoryboardExample
//
//  Created by Nick Hodapp on 1/9/13.
//  Copyright (c) 2013 CoDeveloper. All rights reserved.
//

#import "GraphViewController.h"
#import "PlayerDataPoint.h"
#import "PatchInfo.h"
#import "UIColor-Expanded.h"
#import "SWRevealViewController.h"

@interface GraphViewController() {
    
    NSMutableDictionary *localColorMap;
    NSArray *localPatches;
    NSArray *sorted;
    NSTimer *timer;

    //corePlot
    CPTColor *blueColor;
    CPTColor *redColor;
    CPTXYGraph *graph;
    CPTBarPlot *harvestBarPlot;
    CPTXYPlotSpace *plotSpace;
    
    CGFloat minNumPlayers;
    CGFloat maxNumPlayers;
    
    CGFloat minYield;
    CGFloat maxYield;
    
    bool isRUNNING;
    bool isGAME_STOPPED;
    bool graphNeedsReload;
}

@end


@implementation GraphViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setupDelegates];
        [self setupLocalData];
       
    }
     return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder])
    {
        
        [self setupDelegates];
        [self setupLocalData];
    }
    return self;
}

-(void)setupLocalData {
    localColorMap = [[self appDelegate] colorMap];
    localPatches = [[[[self appDelegate] configurationInfo ] patches ] allObjects];
}

-(void)setupDelegates {
    self.appDelegate.xmppBaseNewMessageDelegate = self;
    self.appDelegate.playerDataDelegate = self;
}

#pragma mark - VIEWS

-(void)viewDidAppear:(BOOL)animated {
    [self initPlot];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = graphViewTitle;
    
    // Change button color
    //_sidebarButton.tintColor = [UIColor colorWithWhite:0.96f alpha:0.2f];
    
    // Set the side bar button action. When it's tapped, it'll show up the sidebar.
    
    [self.revealButtonItem setTarget: self.revealViewController];
    [self.revealButtonItem setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];

   // [self setupDelegates];
   // [self initPlot];
    //[self.graphView.];
    
    //[graph reloadData];
    
}


#pragma mark - Chart behavior

-(void)initPlot {
    
    //setup colors
    
    blueColor = [CPTColor colorWithComponentRed:67.0f/255.0f green:155.0f/255.0f blue:255.0f/255.0f alpha:1.0];
    redColor = [CPTColor colorWithComponentRed:198.0f/255.0f green:42.0f/255.0f blue:0.0f/255.0f alpha:1.0];
    
    minNumPlayers = -0.5f;
    maxNumPlayers = [[[self appDelegate] playerDataPoints] count];
    
    minYield = 0.0f;
    maxYield = [self getMaximumHarvest];
    
    [self setupGraph];
    [self setupAxes];
    [self setupBarPlot];
    [self setupAnnotations];
   
    [harvestBarPlot setHidden:NO];
    
}


-(void)setupGraph {
    // 1 - Create the graph
    graph = [[CPTXYGraph alloc] initWithFrame: self.graphView.bounds];
    self.graphView.hostedGraph = graph;
    
    graph.plotAreaFrame.masksToBorder = YES;
    self.graphView.allowPinchScaling = NO;
    
    graph.paddingBottom = 1.0f;
    graph.paddingRight  = 1.0f;
    graph.paddingLeft  =  1.0f;
    graph.paddingTop    = 10.0f;
    //
    
    graph.plotAreaFrame.paddingLeft   = 75.0;
    graph.plotAreaFrame.paddingTop    = 0.0;
    graph.plotAreaFrame.paddingRight  = 0.0;
    graph.plotAreaFrame.paddingBottom = 0.0;
    
    plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;

    
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minYield) length:CPTDecimalFromFloat(maxYield)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minNumPlayers) length:CPTDecimalFromFloat(maxNumPlayers)];
    
//    CPTLayer *subLayer = [[CPTLayer alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
//    subLayer.backgroundColor = [UIColor redColor].CGColor;
//    [self.graphView.layer addSublayer:subLayer];
}


-(void)setupBarPlot {
    // 1 - Set up the three plots
    harvestBarPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor redColor] horizontalBars:YES];
    //harvestBarPlot.backgroundColor = [[UIColor redColor] CGColor];
    // 2 - Set up line style
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineColor = [CPTColor blackColor];
    barLineStyle.lineWidth = 0;
    
    // 3 - Add plot to graph
    harvestBarPlot.dataSource = self;
    harvestBarPlot.identifier = harvestPlotId;
    harvestBarPlot.delegate = self;
    harvestBarPlot.cornerRadius = 2.0;
    
    harvestBarPlot.lineStyle = barLineStyle;
    [graph addPlot:harvestBarPlot toPlotSpace:graph.defaultPlotSpace];
}

-(void)setupAnnotations {
   
    //graph.plotAreaFrame.plotArea.fill = [CPTFill ]
    
    
//    CPTColor *areaColor       = [CPTColor colorWithComponentRed:1.0 green:1.0 blue:1.0 alpha:0.6];
//    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
//    areaGradient.angle = -90.0f;
//    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
//    
//    CPTPlotSpaceAnnotation *ann = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace  anchorPlotPoint:anchorPoint];
//    ann.contentLayer = areaGradient;
//    ann.displacement =  viewPoint;
//    [graph.plotAreaFrame.plotArea addAnnotation:ann];
    
    
    // Create a new annotation
    //    CPTAnnotation *annot = [[CPTAnnotation alloc]init];
    //    annot.contentLayer = logoLayer;
    //annot.displacement = CGPointMake(50,50);
    
    //     [graph.plotAreaFrame.plotArea addAnnotation:annot];
    
    //    double plotPoint[2] = {0, 240};
    //    CGPoint viewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
    
    //    CPTLayerAnnotation *instructionsAnnotation = [[CPTLayerAnnotation alloc] initWithAnchorLayer:graph.plotAreaFrame.plotArea];
    //    instructionsAnnotation.contentLayer       = subLayer;
    ////    instructionsAnnotation.rectAnchor         = CPTRectAnchorBottom;
    //   instructionsAnnotation.contentAnchorPoint = viewPoint;
    ////    instructionsAnnotation.displacement       = CGPointMake(0.0, 10.0);
    //    [graph.plotAreaFrame.plotArea addAnnotation:instructionsAnnotation];
}

-(void)setupAxes {

    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.graphView.hostedGraph.axisSet;

    // Line styles
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = .5;
    axisLineStyle.lineColor = [CPTColor lightGrayColor];
    
    
    // Text styles
    CPTMutableTextStyle *labelTitleTextStyleBlue = [CPTMutableTextStyle textStyle];
    labelTitleTextStyleBlue.fontName = helveticaNeueRegular;
    labelTitleTextStyleBlue.fontSize = 28.0;
    labelTitleTextStyleBlue.color = blueColor;
    
    CPTMutableTextStyle *labelTitleTextStyleBlack = [CPTMutableTextStyle textStyle];
    labelTitleTextStyleBlack.fontName = helveticaNeueRegular;
    labelTitleTextStyleBlack.fontSize = 28.0;
    labelTitleTextStyleBlack.color = [CPTColor blackColor];
    
    CPTXYAxis *y = axisSet.yAxis;
    
    y.plotSpace                   = graph.defaultPlotSpace;
    y.labelingPolicy              = CPTAxisLabelingPolicyNone;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(1);
    y.tickDirection               = CPTSignNone;
    y.axisLineStyle               = axisLineStyle;
    y.majorTickLength             = 0.0f;
    y.labelOffset                 = 5.5f;



    NSMutableSet *newAxisLabels = [NSMutableSet set];
    for ( NSUInteger i = 0; i < [[[self appDelegate] playerDataPoints] count]; i++ ) {
        
        PlayerDataPoint *pdp = [[[self appDelegate] playerDataPoints] objectAtIndex:i];
        
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[pdp.player_id uppercaseString]
                                                          textStyle:labelTitleTextStyleBlack];
        newLabel.tickLocation = CPTDecimalFromUnsignedInteger(i);
        newLabel.offset       = y.labelOffset + y.majorTickLength;

        [newAxisLabels addObject:newLabel];
    }
    y.axisLabels = newAxisLabels;

    CPTXYAxis *x = axisSet.xAxis;
    
    x.plotSpace                   = graph.defaultPlotSpace;
    x.labelingPolicy              = CPTAxisLabelingPolicyNone;
    x.axisLineStyle               = nil;
    x.majorTickLineStyle          = nil;
    x.minorTickLineStyle          = nil;
    x.majorTickLength             = 4.0f;
    x.minorTickLength             = 2.0f;
    x.tickDirection               = CPTSignNegative;

    x.majorIntervalLength         = CPTDecimalFromString(@"1");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"1");
    graph.axisSet.axes = @[x,y];

    
}

#pragma mark - CPTPlotDataSource methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [[[self appDelegate] playerDataPoints] count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
	if ((fieldEnum == CPTBarPlotFieldBarTip) && (index < [[[self appDelegate] playerDataPoints] count])) {
		if ([plot.identifier isEqual:harvestPlotId]) {
            
            PlayerDataPoint *pdp = [[[self appDelegate] playerDataPoints] objectAtIndex:index];
            
            return [pdp score];
        }
	}
	return [NSDecimalNumber numberWithUnsignedInteger:index];
}


-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index {
    CPTMutableTextStyle *axisTitleTextStyle = [CPTMutableTextStyle textStyle];
    axisTitleTextStyle.fontName = helveticaNeueRegular;
    axisTitleTextStyle.fontSize = 26.0;
    
   
    
    PlayerDataPoint *pdp = [[[self appDelegate] playerDataPoints] objectAtIndex:index];
    
    
    CPTTextLayer *label =[[CPTTextLayer alloc] initWithText: [NSString stringWithFormat:@"%.0f",[pdp.score floatValue]] style:axisTitleTextStyle];
        
    return label;
}


#pragma mark - Annotation methods

-(void)hideAnnotation {
//none at this time
}

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot
                  recordIndex:(NSUInteger)index {
    
    if ( [barPlot.identifier isEqual:harvestPlotId] ) {
        NSString *hexColor = [[[[self appDelegate] playerDataPoints] objectAtIndex:index] valueForKey:@"color"];
        UIColor *rgbColor = [localColorMap objectForKey:hexColor];
        CPTFill *fill = [CPTFill fillWithColor:[CPTColor colorWithCGColor:rgbColor.CGColor]];
        return fill;
    }
    return [CPTFill fillWithColor:redColor];
    
}

#pragma mark - PLAYER DATA DELEGATE

-(void)playerDataDidUpdate {
    
}

-(void)gameReset {}

-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint {
    [self startTimer];
    [graph reloadData];
//    if( arrival_patch_id == nil && departure_patch_id != nil ) {
//        [patchPlayerMap setObject:[NSNull null] forKey:playerDataPoint.rfid_tag];
//    } else if( arrival_patch_id != nil ) {
//        [patchPlayerMap setObject:arrival_patch_id forKey:playerDataPoint.rfid_tag];
//        [self startTimer];
//    }
//    
//    if( departure_patch_id != nil ) {
//        [patchPlayerMap setObject: [NSNull null] forKey:playerDataPoint.rfid_tag];
//    }
}

#pragma mark - TIMER

- (void)startTimer {
    
    if( timer == nil )
        timer = [NSTimer timerWithTimeInterval:self.appDelegate.refreshRate
                                        target:self
                                      selector:@selector(updateGraph)
                                      userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    
}

#pragma mark - UPDATE

-(void)updateGraph {
    [graph reloadData];
}

- (void)stopTimer {
    
    if( timer != nil ) {
        [timer invalidate];
    }
    
    
}

#pragma mark - XMPP New Message Delegate

- (void)newMessageReceived:(NSDictionary *)messageContent {
    NSLog(@"NEW MESSAGE RECIEVED");
}

- (void)replyMessageTo:(NSString *)from {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(NSArray *)getPatches {
    return [[[[self appDelegate] configurationInfo ] patches ] allObjects];
}

-(float)getMaximumHarvest {
    return [[[self appDelegate] configurationInfo ] maximum_harvest];
}

-(float)getStarvingThreshold {
    return [[[self appDelegate] configurationInfo ] starving_threshold];
}

-(float)getProsperingThreshold {
    return [[[self appDelegate] configurationInfo ] prospering_threshold];
}


- (AppDelegate *)appDelegate {
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
