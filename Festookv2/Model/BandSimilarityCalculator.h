//
//  BandDistance.h
//  HorarisFestival
//
//  Created by Eduard on 5/20/13.
//  Copyright (c) 2013 ebc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Festival.h"

@interface BandSimilarityCalculator : NSObject

@property (strong, nonatomic) NSMutableDictionary *distanceBetweenBands;

-(BandSimilarityCalculator*) initWithFestival:(Festival*) fest;

-(void) computeBandSimilarityToMustBands;

-(NSDictionary*) pairOfSimilarBandNames;
-(NSDictionary*) pairOfDifferentBandNames;

@end
