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
    
    CPTColor *starvingColor;
    CPTColor *survivingColor;
    CPTColor *prosperingColor;

    
    CGFloat minNumPlayers;
    CGFloat maxNumPlayers;
    
    CGFloat minYield;
    CGFloat maxYield;
    CGFloat maximumHarvest;
    
    float leftPadding;
    
    float elapsedTime;
    float refreshRate;
    
    float starving;
    float starvingTreshold;
    
    float surviving;
    float survivingTreshold;
    
    float prospering;
    float prosperingTreshold;
    
    bool isRUNNING;
    bool isGAME_STOPPED;
    bool graphNeedsReload;
    
    int numOfPlayers;
    
    CALayer *prosperingLayer;
    CALayer *starvingLayer;
    CALayer *survivingLayer;
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

    refreshRate = [[self appDelegate] refreshRate];
    
    starving = [[self appDelegate] starvingElapsed];
    starvingTreshold = [[[self appDelegate] configurationInfo]starving_threshold];
    
    surviving = [[self appDelegate] survivingElapsed];
    survivingTreshold = [[[self appDelegate] configurationInfo] prospering_threshold];
    
    starvingColor = [CPTColor colorWithComponentRed:239.0f/255.0f green:207.0f/255.0f blue:207.0f/255.0f alpha:1.0];
    survivingColor = [CPTColor colorWithComponentRed:215.0f/255.0f green:230.0f/255.0f blue:179.0f/255.0f alpha:1.0];
    prosperingColor = [CPTColor colorWithComponentRed:191.0f/255.0f green:228.0f/255.0f blue:255.0f/255.0f alpha:1.0];

    [self initPlot];
}


#pragma mark - Chart behavior

-(void)initPlot {
    
    //setup colors
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
    graph.paddingTop    = 1.0f;
    
    
    leftPadding = 55.0;
    
    graph.plotAreaFrame.paddingLeft   = leftPadding;
    graph.plotAreaFrame.paddingTop    = 0.0;
    graph.plotAreaFrame.paddingRight  = 0.0;
    graph.plotAreaFrame.paddingBottom = 0.0;
    
    plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;

    
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minYield) length:CPTDecimalFromFloat(maxYield)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minNumPlayers) length:CPTDecimalFromFloat(maxNumPlayers)];
    
}


-(void)setupBarPlot {
    // 1 - Set up the three plots
    harvestBarPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor redColor] horizontalBars:YES];
    //harvestBarPlot.backgroundColor = [[UIColor whiteColor] CGColor];
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
//    starving = [[self appDelegate] starvingElapsed];
//    surviving = [[self appDelegate] survivingElapsed];
//    prospering = [[self appDelegate] prosperousElapsed];
    
    double originPlotPoint[2] = {0, 0};
    
    CGPoint originViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:originPlotPoint];
    
    double endPlotPoint[2] = {ceil(maxYield), ceil(maxNumPlayers)};
    
    CGPoint endPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:endPlotPoint];

    
    CPTLayer *baseLayer = [[CPTLayer alloc] initWithFrame:CGRectMake(0, 0,  endPoint.x, endPoint.y)];
    baseLayer.paddingLeft = 0;
    baseLayer.paddingRight = 0;
    baseLayer.paddingBottom = 0;
    baseLayer.paddingTop = 0;
    baseLayer.backgroundColor = [[CPTColor whiteColor] cgColor];
    
    
    double prosperingPlotPoint[2] = {ceil(0), ceil(maxNumPlayers)};
    
    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
    

    CPTLayer *pl = [[CPTLayer alloc] initWithFrame:CGRectMake(0, 0,  endPoint.x, endPoint.y)];
    pl.paddingLeft = 0;
    pl.paddingRight = 0;
    pl.paddingBottom = 0;
    pl.paddingTop = 0;
    pl.backgroundColor = [[CPTColor whiteColor] cgColor];
    
    prosperingLayer = [CALayer layer];
    prosperingLayer.backgroundColor = prosperingColor.cgColor;
    prosperingLayer.frame = CGRectMake(0, 0,  prosperingViewPoint.x, endPoint.y);
    [baseLayer addSublayer:prosperingLayer];
    
//    double survivingPlotPoint[2] = {ceil(surviving), ceil(maxNumPlayers)};
//    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
//    
//    
//    survivingLayer = [CALayer layer];
//    survivingLayer.backgroundColor = survivingColor.cgColor;
//    survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, endPoint.y);
//    [baseLayer addSublayer:survivingLayer];
//    
//    double starvingPlotPoint[2] = {ceil(starving), ceil(maxNumPlayers)};
//    
//    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
//    
//    
//    starvingLayer = [CALayer layer];
//    starvingLayer.backgroundColor = starvingColor.cgColor;
//    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, endPoint.y);
//    [baseLayer addSublayer:starvingLayer];
    

    CPTPlotSpaceAnnotation *prosperingAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:@[[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:ceil(maxNumPlayers)]]];
    
    
    prosperingAnnotation.contentLayer = baseLayer;
    prosperingAnnotation.displacement = CGPointMake(endPoint.x/2, -endPoint.y/2);
    [graph.plotAreaFrame.plotArea addAnnotation:prosperingAnnotation];
    [baseLayer removeFromSuperlayer];
    [graph.plotAreaFrame.plotArea insertSublayer:baseLayer atIndex:0];
    
}

-(void)graphNeedsUpdateWithProspering:(double)prosperingElapsed {
    
    NSLog(@"PROSPERING E GRAPH %f", prosperingElapsed);
    
    
    CPTPlotSpaceAnnotation *annot = [graph.plotAreaFrame.plotArea.annotations objectAtIndex:0];
    CPTLayer *baseLayer = annot.contentLayer;
    NSArray *sublayers = [baseLayer sublayers];
    
    CALayer *pLayer = sublayers[0];
    
    
    
    double prosperingPlotPoint[2] = {prosperingElapsed, ceil(maxNumPlayers)};
    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
    
    pLayer.frame  = CGRectMake(0, 0,  prosperingViewPoint.x, pLayer.frame.size.height);
    
    [baseLayer insertSublayer:pLayer atIndex:0];
    annot.contentLayer = baseLayer;
    
    
    
    [graph reloadData];
    
    
    CPTPlotSpaceAnnotation *annot2 = [graph.plotAreaFrame.plotArea.annotations objectAtIndex:0];

}

//-(void)updateGraphLayers {
//    
//    starvingElapsed = [[self appDelegate] starvingElapsed];
//    survivingElapsed = [[self appDelegate] survivingElapsed];
//    prosperingElapsed = [[self appDelegate] prosperousElapsed];
//    
//    double prosperingPlotPoint[2] = {prosperingElapsed, ceil(maxNumPlayers)};
//    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
//    
//    double survivingPlotPoint[2] = {survivingElapsed, ceil(maxNumPlayers)};
//    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
//    
//    double starvingPlotPoint[2] = {starvingElapsed, ceil(maxNumPlayers)};
//    
//    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
//
//    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, starvingLayer.frame.size.height);
//    survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, survivingLayer.frame.size.height);
//    prosperingLayer.frame = CGRectMake(0, 0,  prosperingViewPoint.x, prosperingLayer.frame.size.height);
//}



-(void)setupAxes {

    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.graphView.hostedGraph.axisSet;

    // Line styles
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = .5;
    axisLineStyle.lineColor = [CPTColor lightGrayColor];
    
    CPTMutableTextStyle *labelTitleTextStyleBlack = [CPTMutableTextStyle textStyle];
    labelTitleTextStyleBlack.fontName = helveticaNeueRegular;
    labelTitleTextStyleBlack.fontSize = 20.0;
    labelTitleTextStyleBlack.color = [CPTColor blackColor];
    
    CPTXYAxis *y = axisSet.yAxis;
    
    y.plotSpace                   = graph.defaultPlotSpace;
    y.labelingPolicy              = CPTAxisLabelingPolicyNone;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(1);
    y.tickDirection               = CPTSignNone;
    y.axisLineStyle               = axisLineStyle;
    y.majorTickLength             = 0.0f;
    y.labelOffset                 = 5.0f;



    NSMutableSet *newAxisLabels = [NSMutableSet set];
    for ( NSUInteger i = 0; i < [[[self appDelegate] playerDataPoints] count]; i++ ) {
        
        PlayerDataPoint *pdp = [[[self appDelegate] playerDataPoints] objectAtIndex:i];
        
        
        
//        NSString *hexColor = [pdp color];
//        UIColor *rgbColor = [localColorMap objectForKey:hexColor];
//        labelTitleTextStyleBlack = [CPTMutableTextStyle textStyle];
//        labelTitleTextStyleBlack.fontName = helveticaNeueRegular;
//        labelTitleTextStyleBlack.fontSize = 20.0;
//
//        labelTitleTextStyleBlack.color = [CPTColor colorWithCGColor:rgbColor.CGColor];
        
        
        CPTAxisLabel *newLabel = [[CPTAxisLabel alloc] initWithText:[pdp.player_id uppercaseString]
                                                          textStyle:labelTitleTextStyleBlack];
        
        float left_offset = (leftPadding - newLabel.contentLayer.frame.size.width)/2;
        
        newLabel.alignment = CPTAlignmentLeft;
        newLabel.tickLocation = CPTDecimalFromUnsignedInteger(i);
        newLabel.offset       = left_offset + y.majorTickLength;

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
    axisTitleTextStyle.fontSize = 20.0;
    PlayerDataPoint *pdp = [[[self appDelegate] playerDataPoints] objectAtIndex:index];
    CPTTextLayer *label =[[CPTTextLayer alloc] initWithText: [NSString stringWithFormat:@"%.0f",[pdp.score floatValue]] style:axisTitleTextStyle];
    return label;
}


#pragma mark - Annotation methods

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

-(void)graphNeedsUpdate {
    [self updateGraph];
}


-(void)playerDataDidUpdate {
    
}

-(void)gameReset {}

-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint {
    
}


#pragma mark - UPDATE

-(void)updateGraph {

   // [graph reloadData];
    
}



-(void)overlayNeedsUpdateWith:(double)starvingElapsed With:(double)survivingElapsed With:(double)prosperingElapsed {
//    starving = [[self appDelegate] starvingElapsed];
//    surviving = [[self appDelegate] survivingElapsed];
//    prospering = [[self appDelegate] prosperousElapsed];
    
//    double prosperingPlotPoint[2] = {prosperingElapsed, ceil(maxNumPlayers)};
//    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
//    
//    double survivingPlotPoint[2] = {survivingElapsed, ceil(maxNumPlayers)};
//    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
//    
//    double starvingPlotPoint[2] = {starvingElapsed, ceil(maxNumPlayers)};
//    
//    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
//    
//    
//    NSLog(@"PROSPERING X %f",prosperingViewPoint.x);
//    
//    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, starvingLayer.frame.size.height);
//    survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, survivingLayer.frame.size.height);
//    prosperingLayer.frame = CGRectMake(0, 0,  prosperingViewPoint.x, prosperingLayer.frame.size.height);
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

- (IBAction)showMenu
{
    [self.frostedViewController presentMenuViewController];
}

- (IBAction)toggleBarTotalAnnotation:(id)sender {
    
    if( harvestBarPlot.showLabels == NO ) {
        harvestBarPlot.showLabels = YES;
    } else {
        harvestBarPlot.showLabels = NO;

    }
}

@end
