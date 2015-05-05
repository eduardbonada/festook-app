//
//  Festival.h
//  HorarisFestival
//
//  Created by Eduard on 5/17/13.
//  Copyright (c) 2013 ebc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FestivalSchedule;
@class BandSimilarityCalculator;

@interface Festival : NSObject

/* General info */
@property (nonatomic, strong) NSString      *lowercaseName;
@property (nonatomic, strong) NSString      *uppercaseName;
@property (nonatomic, strong) NSString      *when;
@property (nonatomic, strong) NSString      *where;
@property (nonatomic, strong) NSString      *date;
@property (nonatomic, strong) UIColor       *colorA;
@property (nonatomic, strong) UIColor       *colorB;
@property (nonatomic, strong) NSString      *web;
@property (nonatomic, strong) NSString      *twitter;
@property (nonatomic, strong) NSString      *facebook;
@property (nonatomic, strong) NSString      *youtube;
@property (nonatomic, strong) NSDictionary  *listBandsFile;
@property (nonatomic, strong) NSDictionary  *bandDistanceFile;
@property (nonatomic, strong) NSString      *festivalId;
@property (nonatomic, strong) NSString      *state;

/* time-limits */
@property (nonatomic, strong) NSDate *start;
@property (nonatomic, strong) NSDate *end;

/* Festival bands */
@property (nonatomic, strong) NSDictionary        *bands;           // of lowercaseName:Band
@property (nonatomic, strong) NSMutableDictionary *mustBands;       // of lowercaseName:Band
@property (nonatomic, strong) NSMutableDictionary *discardedBands;  // of lowercaseName:Band
@property (nonatomic)         BOOL changeInMustOrDiscarded;         // flag if there has been a change in must/discarded bands (to recompute schedule)

/* band similarity */
@property (nonatomic, strong) BandSimilarityCalculator* bandSimilarityCalculator;
@property (nonatomic, strong) FestivalSchedule* schedule;

/* Initializer */
-(Festival*) initWithDictionary:(NSDictionary*) dict;

/* Public methods */
-(void) loadBandsFromJsonList;
-(void) updateBandSimilarityModel;
-(NSString*) summaryOfFestival;
-(NSArray*) stageNames;
-(NSNumber*) hoursOfMusic;
-(NSNumber*) distanceBetweenBands:(NSString*) bandNameA and:(NSString*) bandNameB;

/* Interface with NSUserDefaults */
-(void) storeMustBandsInNSUserDefaults;
-(NSMutableDictionary*) getMustBandsFromNSUserDefaults;
-(void) storeDiscardedBandsInNSUserDefaults;
-(NSMutableDictionary*) getDiscardedBandsFromNSUserDefaults;


@end
