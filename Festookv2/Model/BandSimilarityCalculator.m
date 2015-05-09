//
//  BandDistance.m
//  HorarisFestival
//
//  Created by Eduard on 5/20/13.
//  Copyright (c) 2013 ebc. All rights reserved.
//

#import "BandSimilarityCalculator.h"
#import "Festival.h"
#import "Band.h"

@interface BandSimilarityCalculator ()

@property (strong, nonatomic) Festival *festival;

@property (strong, nonatomic) NSMutableArray* allPairs; // of {'bandA':'xxx','bandB':'yyy','distance':'zzz'}

@end


@implementation BandSimilarityCalculator

# pragma mark - Designated initializer
-(BandSimilarityCalculator*) initWithFestival:(Festival*) fest
{
    if (self = [super init]){
        self.festival = fest;
        [self loadDistanceBetweenBandsInFestival];
    }
    return self;
}



# pragma mark - External interface methods

-(void) computeBandSimilarityToMustBands
{    
    double maxDistanceToMustBands;
    double minDistanceToMustBands;
    
    NSArray* bandsStrings       = [self.festival.bands allKeys];
    NSArray* mustBandsStrings   = [self.festival.mustBands allKeys];
    
    // look for MustBands and set their own similarity to 1
    for(NSString *must in mustBandsStrings){
        Band *band = [self.festival.bands objectForKey:must];
        band.bandSimilarityToMustBands = @(1);
    }
    
    // look for max distance
    NSMutableArray *allDistancesToMustBands = [[NSMutableArray alloc] init];
    for(NSString *band in bandsStrings){
        for(NSString *mustBand in mustBandsStrings){
            if(![band isEqualToString: mustBand]){
                [allDistancesToMustBands addObject:self.distanceBetweenBands[band][mustBand]];
            }
        }
    }
    maxDistanceToMustBands = [[allDistancesToMustBands valueForKeyPath:@"@max.self"] doubleValue];
    minDistanceToMustBands = 0.0;
    
    // compute similarity for each band
    for(NSString *band in bandsStrings){
        if(![mustBandsStrings containsObject:band]){
            if([mustBandsStrings count] > 0){
                // there is mustBands
                
                NSMutableArray *distancesToMustBands = [[NSMutableArray alloc] init];
                NSMutableArray *invDistancesToMustBands = [[NSMutableArray alloc] init];
                for(NSString *mustBand in mustBandsStrings){
                    [distancesToMustBands addObject:self.distanceBetweenBands[band][mustBand]];
                    [invDistancesToMustBands addObject:@(1.0/[self.distanceBetweenBands[band][mustBand] doubleValue])];
                }
                
                // similarity = normalized arithmetic mean distance to all mustBands
                /*
                double sumDistancesToMustBands          = [[distancesToMustBands valueForKeyPath:@"@sum.self"] doubleValue];
                double arithMeanBandDistanceToMustBands = (1/[@([mustBandsStrings count]) doubleValue]) * sumDistancesToMustBands;
                double normArithMeanBandSimilarityTmp   = (arithMeanBandDistanceToMustBands - maxDistanceToMustBands ) / (minDistanceToMustBands - maxDistanceToMustBands );
                ((Band*)([self.festival.bands objectForKey:band])).bandSimilarityToMustBands = @(normArithMeanBandSimilarityTmp);
                 */
                
                // similarity = normalized geometric mean distance to all mustBands ?

                
                // similarity = normalized harmonic mean distance to all mustBands
                double sumInvDistancesToMustBands      = [[invDistancesToMustBands valueForKeyPath:@"@sum.self"] doubleValue];
                double harmMeanBandDistanceToMustBands = [@([mustBandsStrings count]) doubleValue] / sumInvDistancesToMustBands;
                double normHarmMeanBandSimilarityTmp   = (harmMeanBandDistanceToMustBands - maxDistanceToMustBands ) / (minDistanceToMustBands - maxDistanceToMustBands );
                ((Band*)([self.festival.bands objectForKey:band])).bandSimilarityToMustBands = @(normHarmMeanBandSimilarityTmp);

                // similarity = normalized minimum distance to a mustBands
                //((Band*)([self.festival.bands objectForKey:band])).bandSimilarityToMustBands = @(1-[[distancesToMustBands valueForKeyPath:@"@min.self"] doubleValue] / maxDistanceToMustBands);

            }
            else{
                // there is no mustBands
                ((Band*)([self.festival.bands objectForKey:band])).bandSimilarityToMustBands = @(0);
            }
        }
    }
    
}


-(NSDictionary*) pairOfSimilarBandNames
{
    
    if(!self.allPairs){
        self.allPairs = [[NSMutableArray alloc] init];
        [self extractAllPairsOfBands];
    }
    
    NSArray* sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES]];
    NSArray* sortedArray = [self.allPairs sortedArrayUsingDescriptors:sortDescriptors];
    
    // select one position of the top 5%
    NSUInteger randomPosition = arc4random_uniform( [@([self.allPairs count]*0.01) doubleValue] );
    
    return [sortedArray objectAtIndex:randomPosition];
    
}

-(NSDictionary*) pairOfDifferentBandNames
{
    
    if(!self.allPairs){
        self.allPairs = [[NSMutableArray alloc] init];
        [self extractAllPairsOfBands];
    }
    
    NSArray* sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"distance" ascending:NO]];
    NSArray* sortedArray = [self.allPairs sortedArrayUsingDescriptors:sortDescriptors];
    
    // select one position of the bottom 5%
    NSUInteger randomPosition = arc4random_uniform( [@([self.allPairs count]*0.05) doubleValue] );
    
    return [sortedArray objectAtIndex:randomPosition];
    
}

-(void) extractAllPairsOfBands
{
    for(NSString* bandNameA in [self.distanceBetweenBands allKeys]){
        for(NSString* bandNameB in [[self.distanceBetweenBands objectForKey:bandNameA] allKeys]){
            if(![bandNameA isEqualToString:bandNameB]){
                [self.allPairs addObject:@{@"bandA":bandNameA,@"bandB":bandNameB,@"distance":self.distanceBetweenBands[bandNameA][bandNameB]}];
            }
        }
    }
}

# pragma mark - Loading distance data

-(void) loadDistanceBetweenBandsInFestival
{
    
    // read file from application support directory and store its contents into an NSData object
    NSData *bandDistanceJsonData;
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[self.festival.bandDistanceFile objectForKey:@"filename"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        bandDistanceJsonData = [[NSData alloc] initWithContentsOfFile:path];
    }
    else{
        NSLog(@"ERROR BandSimilarityCalculator::loadDistanceBetweenBandsInFestival => File does not exist");
    }
    
    //NSLog(@"%@",[[NSString alloc] initWithData:bandDistanceJsonData encoding:NSUTF8StringEncoding]);
    
    // get list of bands as dictionary of dictionaries
    NSError *error = nil;
    self.distanceBetweenBands       = [NSJSONSerialization JSONObjectWithData:bandDistanceJsonData
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&error];
    if(error){
        NSLog(@"ERROR BandSimilarityCalculator::loadDistanceBetweenBandsInFestival => %@",error);
    }

    // look up maximum distance
    double maxDistance;
    NSMutableArray *allDistances = [[NSMutableArray alloc] init];
    for(NSString *bandNameA in [self.festival.bands allKeys]){
        for(NSString *bandNameB in [self.festival.bands allKeys]){
            [allDistances addObject:self.distanceBetweenBands[bandNameA][bandNameB]];
        }
    }
    maxDistance = [[allDistances valueForKeyPath:@"@max.self"] doubleValue];
    
    // fix 'not connected' bands
    for(NSString *bandNameA in [self.festival.bands allKeys]){
        for(NSString *bandNameB in [self.festival.bands allKeys]){
            if( [self.distanceBetweenBands[bandNameA][bandNameB]  isEqual: @(-1)]){
                self.distanceBetweenBands[bandNameA][bandNameB] = @(maxDistance);
            }
        }
    }
    
}

@end
