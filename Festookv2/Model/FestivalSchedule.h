//
//  FestivalSchedule.h
//  FestivalSchedule
//
//  Created by Eduard Bonada Cruells on 29/08/14.
//  Copyright (c) 2014 ebc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Festival.h"

@interface FestivalSchedule : NSObject

-(FestivalSchedule*) initWithFestival:(Festival*) fest;

-(void) computeSchedule;

-(NSArray*) daysToAttendWithOptions:(NSString*) options;
-(NSArray*) bandsToAttendSortedByTimeBetween:(NSDate*) startDate and:(NSDate*) endDate withOptions:(NSString*) options;

-(NSArray*) initialLettersOFBands;
-(NSArray*) bandsWithInitial:(NSString*) initial;

-(NSAttributedString*) textRepresentationOfTheSchedule;

@end
