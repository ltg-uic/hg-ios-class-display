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
#import "GraphUnderLayer.h"
@interface GraphViewController() {
    
    NSMutableDictionary *localColorMap;

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
    
    float starvingElapsed;
    float starvingTreshold;
    
    float survivingElapsed;
    float survivingTreshold;
    
    float prosperingElapsed;
    float prosperingTreshold;
    
    int numOfPlayers;
    
    CPTLayer *prosperingLayer;
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
}

-(void)setupDelegates {
    self.appDelegate.playerDataDelegate = self;
}

#pragma mark - VIEWS

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    self.title = graphViewTitle;
    
    [self.revealButtonItem setTarget: self.revealViewController];
    [self.revealButtonItem setAction: @selector( revealToggle: )];
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];

    starvingElapsed = [[self appDelegate] starvingElapsed];
    survivingElapsed = [[self appDelegate] survivingElapsed];
    prosperingElapsed = [[self appDelegate] prosperousElapsed];
    
    
    [self initPlot];
}


#pragma mark - Chart behavior

-(void)initPlot {
    
    starvingColor = [CPTColor colorWithComponentRed:239.0f/255.0f green:207.0f/255.0f blue:207.0f/255.0f alpha:1.0];
    survivingColor = [CPTColor colorWithComponentRed:215.0f/255.0f green:230.0f/255.0f blue:179.0f/255.0f alpha:1.0];
    prosperingColor = [CPTColor colorWithComponentRed:191.0f/255.0f green:228.0f/255.0f blue:255.0f/255.0f alpha:1.0];
    
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
    
    
    double endPlotPoint[2] = {ceil(maxYield), ceil(maxNumPlayers)};
    
    CGPoint endPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:endPlotPoint];

    
    GraphUnderLayer *baseLayer = [[GraphUnderLayer alloc] initWithFrame:CGRectMake(0, 0,  endPoint.x, endPoint.y)];
    baseLayer.paddingLeft = 0;
    baseLayer.paddingRight = 0;
    baseLayer.paddingBottom = 0;
    baseLayer.paddingTop = 0;
    baseLayer.backgroundColor = [[CPTColor whiteColor] cgColor];
    
    
    double prosperingPlotPoint[2] = {ceil(prosperingElapsed), ceil(maxNumPlayers)};
    
    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
    

    prosperingLayer = [[CPTLayer alloc] initWithLayer:baseLayer];
    prosperingLayer.frame = CGRectMake(0, 0,  prosperingViewPoint.x, prosperingViewPoint.y);
    prosperingLayer.paddingLeft = 0;
    prosperingLayer.paddingRight = 0;
    prosperingLayer.paddingBottom = 0;
    prosperingLayer.paddingTop = 0;
    prosperingLayer.backgroundColor = prosperingColor.cgColor;

    [baseLayer addSublayer:prosperingLayer];
    
     double survivingPlotPoint[2] = {ceil(survivingElapsed), ceil(maxNumPlayers)};
     CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];

     survivingLayer = [[CPTLayer alloc] initWithLayer:baseLayer];
     survivingLayer.backgroundColor = survivingColor.cgColor;
     survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, endPoint.y);
    [baseLayer addSublayer:survivingLayer];
  
    double starvingPlotPoint[2] = {ceil(starvingElapsed), ceil(maxNumPlayers)};
    
    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
  
    starvingLayer =  [[CPTLayer alloc] initWithLayer:baseLayer];
    starvingLayer.backgroundColor = starvingColor.cgColor;
    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, endPoint.y);
    [baseLayer addSublayer:starvingLayer];
    
    [graph.plotAreaFrame.plotArea insertSublayer:baseLayer atIndex:0];
    [baseLayer logLayers];
}

-(void)graphNeedsUpdateWithProspering:(double)ep WithSurviving:(double)se WithStarving:(double)ste {
    [graph reloadData];
    
    double prosperingPlotPoint[2] = {ceil(ep), ceil(maxNumPlayers)};
    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
    
    prosperingLayer.frame  = CGRectMake(0, 0,  prosperingViewPoint.x, prosperingLayer.frame.size.height);
    
    double survivingPlotPoint[2] = {ceil(se), ceil(maxNumPlayers)};
    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
    
    survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, survivingLayer.frame.size.height);
    
    double starvingPlotPoint[2] = {ceil(ste), ceil(maxNumPlayers)};
    
    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, starvingLayer.frame.size.height);

}



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


-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint {
    
}

-(void)resetMap {
    //used by map
}


#pragma mark - UPDATE

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
