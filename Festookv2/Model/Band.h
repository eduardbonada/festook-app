//
//  Band.h
//  HorarisFestival
//
//  Created by Eduard on 5/10/13.
//  Copyright (c) 2013 ebc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Festival.h"

@interface Band : NSObject

/* General info */
@property (nonatomic,strong) NSString *uppercaseName;
@property (nonatomic,strong) NSString *lowercaseName;
@property (nonatomic,strong) NSString *bandId;
@property (nonatomic,strong) NSDate   *startTime;
@property (nonatomic,strong) NSDate   *endTime;
@property (nonatomic,strong) NSString *stage;
@property (nonatomic,strong) NSString *style;
@property (nonatomic,strong) NSString *infoText;

@property (nonatomic,strong) Festival *festival; // pointer to the festival where the band belongs

@property (nonatomic,strong) NSNumber *bandSimilarityToMustBands;   // Similarity of this band to the MUST bands

/* Initializer */
-(Band*)initWithUppercaseName:(NSString*) uppercaseName
                lowercaseName:(NSString*) lowercaseName
                       bandId:(NSString*) bandId
                    startTime:(NSDate*)   startTime
                      endtime:(NSDate*)   endTime
                        stage:(NSString*) stage
                //moreInfoWeb:(NSString*) moreInfoWeb
                      //image:(NSString*) image
                       origin:(NSString*) origin
                        style:(NSString*) style
                     infoText:(NSString*) infoText
                     festival:(Festival*) festival;


/* Class method that sorts a dictionary of arrays {"lowercase":Band} by different methods */
+(NSArray*) sortBandsIn:(NSDictionary*)bands by:(NSString*) sortingMode;

-(NSDate*) dayOfConcert;
-(NSDate*) weekdayOfConcert;

@end
