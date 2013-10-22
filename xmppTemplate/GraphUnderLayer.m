//
//  GraphUnderLayer.m
//  hg-ios-class-display
//
//  Created by Anthony Perritano on 10/21/13.
//  Copyright (c) 2013 Learning Technologies Group. All rights reserved.
//

#import "GraphUnderLayer.h"

@implementation GraphUnderLayer

-(void)layoutSublayers
{
//    CGRect selfBounds    = self.bounds;
//    NSArray *mySublayers = self.sublayers;
//    
//    if ( mySublayers.count > 0 ) {
//        //CGFloat leftPadding, topPadding, rightPadding, bottomPadding;
//        
//        //[self sublayerMarginLeft:&leftPadding top:&topPadding right:&rightPadding bottom:&bottomPadding];
//        
//        CGSize subLayerSize = selfBounds.size;
//        subLayerSize.width  -= leftPadding + rightPadding;
//        subLayerSize.width   = MAX( subLayerSize.width, CPTFloat(0.0) );
//        subLayerSize.width   = round(subLayerSize.width);
//        subLayerSize.height -= topPadding + bottomPadding;
//        subLayerSize.height  = MAX( subLayerSize.height, CPTFloat(0.0) );
//        subLayerSize.height  = round(subLayerSize.height);
//        
//        CGRect subLayerFrame;
//        subLayerFrame.origin = CGPointMake( round(leftPadding), round(bottomPadding) );
//        subLayerFrame.size   = subLayerSize;
//        
//        NSSet *excludedSublayers = [self sublayersExcludedFromAutomaticLayout];
//        Class layerClass         = [CPTLayer class];
//        for ( CALayer *subLayer in mySublayers ) {
//            if ( [subLayer isKindOfClass:layerClass] && ![excludedSublayers containsObject:subLayer] ) {
//                subLayer.frame = subLayerFrame;
//            }
//        }
//    }
}

@end
