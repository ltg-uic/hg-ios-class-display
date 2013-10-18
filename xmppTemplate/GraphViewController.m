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
    
    float starvingElapsed;
    float starvingTreshold;
    
    float survivingElapsed;
    float survivingTreshold;
    
    float prosperingElapsed;
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

    refreshRate = [[self appDelegate] refreshRate];
    
    starvingElapsed = [[self appDelegate] starvingElapsed];
    starvingTreshold = [[[self appDelegate] configurationInfo]starving_threshold];
    
    survivingElapsed = [[self appDelegate] survivingElapsed];
    survivingTreshold = [[[self appDelegate] configurationInfo] prospering_threshold];
    
    starvingColor = [CPTColor colorWithComponentRed:239.0f/255.0f green:207.0f/255.0f blue:207.0f/255.0f alpha:1.0];
    survivingColor = [CPTColor colorWithComponentRed:215.0f/255.0f green:230.0f/255.0f blue:179.0f/255.0f alpha:1.0];
    prosperingColor = [CPTColor colorWithComponentRed:191.0f/255.0f green:228.0f/255.0f blue:255.0f/255.0f alpha:1.0];


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
    
//    CPTLayer *subLayer = [[CPTLayer alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
//    subLayer.backgroundColor = [UIColor redColor].CGColor;
//    [self.graphView.layer addSublayer:subLayer];
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
    starvingElapsed = [[self appDelegate] starvingElapsed];
    survivingElapsed = [[self appDelegate] survivingElapsed];
    prosperingElapsed = [[self appDelegate] prosperousElapsed];
    
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
    

    prosperingLayer = [CALayer layer];
    prosperingLayer.backgroundColor = prosperingColor.cgColor;
    prosperingLayer.frame = CGRectMake(0, 0,  prosperingViewPoint.x, endPoint.y);
    [baseLayer addSublayer:prosperingLayer];
    
    double survivingPlotPoint[2] = {ceil(survivingElapsed), ceil(maxNumPlayers)};
    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
    
    
    survivingLayer = [CALayer layer];
    survivingLayer.backgroundColor = survivingColor.cgColor;
    survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, endPoint.y);
    [baseLayer addSublayer:survivingLayer];
    
    double starvingPlotPoint[2] = {ceil(starvingElapsed), ceil(maxNumPlayers)};
    
    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
    
    
    starvingLayer = [CALayer layer];
    starvingLayer.backgroundColor = starvingColor.cgColor;
    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, endPoint.y);
    [baseLayer addSublayer:starvingLayer];
    
    //Starving
    //double starvingPlotPoint[2] = {ceil(100), ceil(maxNumPlayers)};
//    
//    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
//    
//    CALayer *starvingLayer = [CALayer layer];
//    
//    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, (height+20.0f)*2);
//   
//    [baseLayer addSublayer:starvingLayer];
    CPTPlotSpaceAnnotation *prosperingAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:@[[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:ceil(maxNumPlayers)]]];
    
    
    prosperingAnnotation.contentLayer = baseLayer;
    prosperingAnnotation.displacement = CGPointMake(endPoint.x/2, -endPoint.y/2);
    [graph.plotAreaFrame.plotArea addAnnotation:prosperingAnnotation];
    [baseLayer removeFromSuperlayer];
    [graph.plotAreaFrame.plotArea insertSublayer:baseLayer atIndex:0];
    
}

-(void)updateGraphLayers {
    
    starvingElapsed = [[self appDelegate] starvingElapsed];
    survivingElapsed = [[self appDelegate] survivingElapsed];
    prosperingElapsed = [[self appDelegate] prosperousElapsed];

//    NSLog(@"ELAPSED STARVING %f",starvingElapsed);
//    NSLog(@"ELAPSED SURVIVING %f",survivingElapsed);
//    NSLog(@"ELAPSED PROSPERING %f",prosperingElapsed);
//    
//    
//    NSLog(@"WIDTH STARVING %f",starvingLayer.frame.size.width);
//    NSLog(@"WIDTH SURVIVING %f",survivingLayer.frame.size.width);
//    NSLog(@"WIDTH PROSPERING %f",prosperingLayer.frame.size.width);
    
    double prosperingPlotPoint[2] = {prosperingElapsed, ceil(maxNumPlayers)};
    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
    
    double survivingPlotPoint[2] = {survivingElapsed, ceil(maxNumPlayers)};
    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
    
    double starvingPlotPoint[2] = {starvingElapsed, ceil(maxNumPlayers)};
    
    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];

//    NSLog(@"NEW WIDTH STARVING %f",starvingViewPoint.x);
//    NSLog(@"NEW WIDTH SURVIVING %f",survivingViewPoint.x);
//    NSLog(@"NEW WIDTH PROSPERING %f",prosperingViewPoint.x);
    
    starvingLayer.frame = CGRectMake(0, 0,  starvingViewPoint.x, starvingLayer.frame.size.height);
    survivingLayer.frame = CGRectMake(0, 0,  survivingViewPoint.x, survivingLayer.frame.size.height);
    prosperingLayer.frame = CGRectMake(0, 0,  prosperingViewPoint.x, prosperingLayer.frame.size.height);
}
//-(void)setupAnnotations {
   
//    starvingElapsed = [[self appDelegate] starvingElapsed];
//    survivingElapsed = [[self appDelegate] survivingElapsed];
//    prosperingElapsed = [[self appDelegate] prosperousElapsed];
//    
//    double originPlotPoint[2] = {0, 0};
//    
//    CGPoint originViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:originPlotPoint];
//    
//    
//    double plotPoint[2] = {ceil(starvingElapsed), ceil(maxNumPlayers)};
//    
//    CGPoint starvingPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
//    
//    CGFloat width = starvingPoint.x-originViewPoint.x;
//    CGFloat height = starvingPoint.y-originViewPoint.y;
//    //starvingAnnotation = [[CPTLayerAnnotation alloc]initWithAnchorLayer:graph.plotAreaFrame.plotArea ];
//    CPTBorderedLayer *starvingLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectMake(0, 0,  width, (height+10.0f) * 2.5)];
//    starvingLayer.paddingLeft = 0;
//    starvingLayer.paddingRight = 0;
//    starvingLayer.paddingBottom = 0;
//    starvingLayer.paddingTop = 0;
//    starvingLayer.fill = [CPTFill fillWithColor: starvingColor];
//   
//    
//    CPTPlotSpaceAnnotation *starvingAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:@[[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:ceil(maxNumPlayers)]]];
//    
//    
//    starvingAnnotation.contentLayer = starvingLayer;
//    starvingAnnotation.displacement = CGPointMake(width/2, 0);
//    [graph.plotAreaFrame.plotArea addAnnotation:starvingAnnotation];
//    [starvingLayer removeFromSuperlayer];
//    [graph.plotAreaFrame.plotArea insertSublayer:starvingLayer atIndex:0];

//
//    //SURVIVING
//    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:originPlotPoint];
//    
//    double survivingPlotPoint[2] = {ceil(survivingElapsed), ceil(maxNumPlayers)};
//    
//    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
//
//    
//    CGFloat survivingWidth = survivingViewPoint.x-starvingViewPoint.x;
//    CGFloat survivingHeight = survivingViewPoint.y-starvingViewPoint.y;
//    
//    CPTBorderedLayer *survivingLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectMake(0, 0,  customRounding(survivingWidth), customRounding(survivingHeight+10.0f) * 2.5)];
//    survivingLayer.paddingLeft = 0;
//    survivingLayer.paddingRight = 0;
//    survivingLayer.paddingBottom = 0;
//    survivingLayer.paddingTop = 0;
//    survivingLayer.fill = [CPTFill fillWithColor: survivingColor];
//    
//    
//    
//    CPTPlotSpaceAnnotation *survivingAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:@[[NSNumber numberWithFloat:ceil(starvingElapsed)], [NSNumber numberWithFloat:ceil(maxNumPlayers)]]];
//    
//    
//    survivingAnnotation.contentLayer = survivingLayer;
//    survivingAnnotation.displacement = CGPointMake(width/2, 0);
//    [graph.plotAreaFrame.plotArea addAnnotation:survivingAnnotation];
//    [survivingLayer removeFromSuperlayer];
//    [graph.plotAreaFrame.plotArea insertSublayer:survivingLayer atIndex:0];
//    
//    //PROSPERING
//    
//    double prosperingPlotPoint[2] = {ceil(prosperingElapsed), ceil(maxNumPlayers)};
//    
//    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
//    
//    
//    CGFloat prosperingWidth = prosperingViewPoint.x-survivingViewPoint.x;
//    CGFloat prosperingHeight = prosperingViewPoint.y-survivingViewPoint.y;
//    
//    CPTBorderedLayer *prosperingLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectMake(0, 0,  prosperingWidth, (prosperingHeight+10.0f) * 2.5)];
//    prosperingLayer.paddingLeft = 0;
//    prosperingLayer.paddingRight = 0;
//    prosperingLayer.paddingBottom = 0;
//    prosperingLayer.paddingTop = 0;
//    prosperingLayer.fill = [CPTFill fillWithColor: prosperingColor];
//    
//    
//    CPTPlotSpaceAnnotation *prosperingAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:@[[NSNumber numberWithFloat:ceil(survivingElapsed)], [NSNumber numberWithFloat:ceil(maxNumPlayers)]]];
//    
//    
//    prosperingAnnotation.contentLayer = prosperingLayer;
//    prosperingAnnotation.displacement = CGPointMake(width/2, 0);
//    [graph.plotAreaFrame.plotArea addAnnotation:prosperingAnnotation];
//    [prosperingLayer removeFromSuperlayer];
//    [graph.plotAreaFrame.plotArea insertSublayer:prosperingLayer atIndex:0];
//    
//}

-(void)updateOverlays {
    
    elapsedTime = elapsedTime + refreshRate;
    
    starvingElapsed = [[self appDelegate] starvingElapsed];
    survivingElapsed = [[self appDelegate] survivingElapsed];
    prosperingElapsed = [[self appDelegate] prosperousElapsed];

    
    NSLog(@"ELAPSED STARVING %f",starvingElapsed);
    NSLog(@"ELAPSED SURVIVING %f",survivingElapsed);
    NSLog(@"ELAPSED PROSPERING %f",prosperingElapsed);

    //STARVING
    
    //if( prosperingElapsed <= maxYield ) {
    
    double originPlotPoint[2] = {0, 0};
    
    CGPoint originViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:originPlotPoint];
    
    double starvingPlotPoint[2] = {ceil(starvingElapsed), ceil(maxNumPlayers)};
    
    NSLog(@"PLOT POINTS %f, %f",starvingPlotPoint[0],starvingPlotPoint[1]);
    
    CGPoint viewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
    
    
    CGFloat starvingWidth = viewPoint.x-originViewPoint.x;
    CGFloat starvingHeight = viewPoint.y-originViewPoint.y;
    
    NSLog(@"SURVIVING WIDTH  %f",ceil(starvingWidth));
    
    CPTPlotSpaceAnnotation *starvingAnnot = [graph.plotAreaFrame.plotArea.annotations objectAtIndex:0];
    starvingAnnot.contentLayer.frame = CGRectMake(0, 0, starvingWidth, (starvingHeight+10.0f) * 2.5);
    starvingAnnot.anchorPlotPoint = @[[NSNumber numberWithFloat:0.0f], [NSNumber numberWithFloat:ceil(maxNumPlayers)]];
    starvingAnnot.displacement = CGPointMake(starvingWidth/2.0f, 0.0f);
    
    NSLog(@"DONE STARVING Annotation");
    
    //SURVIVING
    
    CGPoint starvingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:starvingPlotPoint];
    
    double survivingPlotPoint[2] = {ceil(survivingElapsed), ceil(maxNumPlayers)};
    
    NSLog(@"PLOT POINTS %f, %f",survivingPlotPoint[0],survivingPlotPoint[1]);
    
    CGPoint survivingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:survivingPlotPoint];
    
    NSLog(@"VIEW POINTS %f,%f",survivingViewPoint.x, survivingViewPoint.y);
    
    CGFloat survivingWidth =  survivingViewPoint.x - starvingViewPoint.x;
    CGFloat survivingHeight = survivingViewPoint.y;
    
    NSLog(@"SURVIVING WIDTH  %f",survivingWidth);
    NSLog(@"SURVIVING HEIGHT  %f",survivingHeight);
    
    CPTPlotSpaceAnnotation *survivingAnnot = [graph.plotAreaFrame.plotArea.annotations objectAtIndex:1];
    survivingAnnot.contentLayer.frame = CGRectMake(0, 0, survivingWidth, (survivingHeight+10.0f) * 2.5);
    survivingAnnot.anchorPlotPoint = @[[NSNumber numberWithFloat:ceil(starvingElapsed-2)], [NSNumber numberWithFloat:ceil(maxNumPlayers)]];
    survivingAnnot.displacement = CGPointMake(survivingWidth/2.0f, 0.0f);
    NSLog(@"DONE SURVIVING annotation");
    
    //PROSPERING
    
    double prosperingPlotPoint[2] = {ceil(prosperingElapsed), ceil(maxNumPlayers)};
   
    NSLog(@"PLOT PROSPERING POINTS %f, %f",prosperingPlotPoint[0],prosperingPlotPoint[1]);
    
    CGPoint prosperingViewPoint = [graph.defaultPlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:prosperingPlotPoint];
    
    NSLog(@"VIEW PROSPERING POINTS %f,%f",prosperingViewPoint.x, prosperingViewPoint.y);
  
    CGFloat prosperingWidth =  prosperingViewPoint.x - survivingViewPoint.x;
    CGFloat prosperingHeight = prosperingViewPoint.y;
  
    NSLog(@"PROSPERING WIDTH  %f",prosperingWidth);
    NSLog(@"PROSPERING HEIGHT  %f",prosperingHeight);
    
    CPTPlotSpaceAnnotation *prosperingAnnot = [graph.plotAreaFrame.plotArea.annotations objectAtIndex:2];
    prosperingAnnot.contentLayer.frame = CGRectMake(0, 0, prosperingWidth, (prosperingHeight+10.0f) * 2.5);
    prosperingAnnot.anchorPlotPoint = @[[NSNumber numberWithFloat:ceil(survivingElapsed-3)], [NSNumber numberWithFloat:ceil(maxNumPlayers)]];
    prosperingAnnot.displacement = CGPointMake(prosperingWidth/2.0f, 0.0f);
    
    [graph.plotAreaFrame.plotArea setNeedsDisplay];
    NSLog(@"DONE PROSPERING annotation");
  
}

float customRounding(float value) {
    const float roundingValue = 0.05;
    int mulitpler = floor(value / roundingValue);
    return mulitpler * roundingValue;
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

-(void)graphNeedsUpdate {
    [self updateGraph];
}


-(void)playerDataDidUpdate {
    
}

-(void)gameReset {}

-(void)playerDataDidUpdateWithArrival:(NSString *)arrival_patch_id WithDeparture:(NSString *)departure_patch_id WithPlayerDataPoint:(PlayerDataPoint *)playerDataPoint {
    //[self startTimer];
}

#pragma mark - TIMER

- (void)startTimer {
    
    if( timer == nil ) {
        timer = [NSTimer timerWithTimeInterval:self.appDelegate.refreshRate
                                        target:self
                                      selector:@selector(updateGraph)
                                      userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    } else {
        
    }
    
    
}

#pragma mark - UPDATE

-(void)updateGraph {

    [graph reloadData];
    [self updateGraphLayers];
    //[self updateOverlays];
    
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
