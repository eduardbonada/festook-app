//
//  FestivalSchedule.m
//  FestivalSchedule
//
//  Created by Eduard Bonada Cruells on 29/08/14.
//  Copyright (c) 2014 ebc. All rights reserved.
//

#import "FestivalSchedule.h"

#import "Band.h"

@interface FestivalSchedule ()

@property (strong, nonatomic) Festival *festival;

@property (strong, nonatomic) NSMutableArray *freeSlots;            // array of dictionaries => [{"start":NSDate,"end":NSDate},...]
@property (strong, nonatomic) NSMutableDictionary *bandsToAttend;   // lowercaseName:Band

@property (strong, nonatomic) NSString *algorithmMode;   // "FullConcert" / "FullConcert" / "SecondHalfConcert" / "LastHalfHour"

@end

@implementation FestivalSchedule


#pragma mark - Public interface

-(FestivalSchedule*) initWithFestival:(Festival*) fest
{
    if (self = [super init]){
        
        self.festival = fest;
        
        self.festival.schedule = self;
                
        [self resetFestival];
        
    }
    return self;
}

-(void) resetFestival
{
    // reset data structures to manage free slots (unique free slot) and bands to attend (no bands yet)
    self.freeSlots = [[NSMutableArray alloc] initWithArray: @[ @{ @"startTime":self.festival.start, @"endTime":self.festival.end } ] ];
    self.bandsToAttend = [[NSMutableDictionary alloc] init]; // no bands selected yet
}

-(void) computeSchedule
{
    [self resetFestival];
    
    // get algorithm mode from NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *algorithmMode = [defaults objectForKey:@"scheduleAlgorithmMode"];
    if(!algorithmMode){
        algorithmMode = @"FullConcertWithFreeTime"; // FullConcertWithFreeTime - FullConcert - SecondHalfConcert - LastHalfHour
        [defaults setObject:algorithmMode forKey:@"scheduleAlgorithmMode"];
        [defaults synchronize];
    }

    self.algorithmMode = algorithmMode;
    
    [self generateScheduleWithSFFSwithOptions:@{@"mode":self.algorithmMode}];
    
    self.changeInAlgorithmMode = NO;
}

-(NSAttributedString*) textRepresentationOfTheSchedule
{
    // sort the bandsToAttend by startTime
    NSArray* bandsSortedByStartTime = [Band sortBandsIn:self.bandsToAttend by:@"startTime"];
    
    // DateFormatter for text easier to read
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"HH:mm";

    // construct string
    NSMutableAttributedString* attributedTextSchedule = [[NSMutableAttributedString alloc] initWithString:@""];
    for(NSString* bandString in bandsSortedByStartTime){
        Band* band = [self.festival.bands objectForKey:bandString];
        
        // rounded WhiteColor
        CGFloat whiteColor;
        if([band.bandSimilarityToMustBands doubleValue] <= 0.25){
            whiteColor = 1-0.25;
        }
        else if([band.bandSimilarityToMustBands doubleValue] <= 0.50){
            whiteColor = 1-0.50;
        }
        else if([band.bandSimilarityToMustBands doubleValue] <= 0.75){
            whiteColor = 1-0.75;
        }
        else{
            whiteColor = 1-1;
        }

        //CGFloat whiteColor = (-0.8*[band.bandSimilarityToMustBands doubleValue]+0.8) // gradual
        
        NSAttributedString* attributedString =
        [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ => [%0.3f] [%@-%@]\n",
                                                    band.uppercaseName,
                                                    [band.bandSimilarityToMustBands doubleValue],
                                                    [dateFormatter stringFromDate: band.startTime],
                                                    [dateFormatter stringFromDate: band.endTime]
                                                    ]
                                        attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:whiteColor alpha:1.0]
                                                     }
         ];
        
        [attributedTextSchedule appendAttributedString:attributedString];
    }
    
    return attributedTextSchedule;
}

-(NSArray*) initialLettersOFBands
{
    /*
     Returns an array of strings with the found initials ["a","c","k"...,"w"]
     */
    
    NSMutableArray* initials = [[NSMutableArray alloc] init];
    
    for (Band* band in [self.festival.bands allValues]){
        NSString* bandInitial = [band.lowercaseName substringToIndex:1];
        if(![initials containsObject:bandInitial]){
            [initials addObject:bandInitial];
        }
    }
    
    return [initials sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];
}

-(NSArray*) bandsWithInitial:(NSString*) initial
{
    /*
     Returns an array of "lowercaseName" with the bands starting by the indicated initial, and sorted alphabetically
     */
    
    NSMutableArray* bandsWithInitial = [[NSMutableArray alloc] init];
    
    for (Band* band in [self.festival.bands allValues]){
        NSString* bandInitial = [band.lowercaseName substringToIndex:1];
        if([bandInitial isEqualToString:initial]){
            [bandsWithInitial addObject:band.lowercaseName];
        }
    }

    return [bandsWithInitial sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];
    
}

-(NSArray*) daysToAttendWithOptions:(NSString*) options
{
    /*
     Returns an array of dictionaries of the form {"day":"dd/mm/yyyy","start":NSDate,"end":NSDate} with the bands days to attend the festival, looking at bandstoAttend.
     If there are no bandsToAttend selected (for example when no Must bands are still chosen, it returns the days to attend assuming attendance to all bands)
     */

    NSString* lastDayAdded;
    NSUInteger currentIndexOfDay = 0;
    
    // date formatters
    NSDateFormatter *dayDateFormatter = [[NSDateFormatter alloc] init];
    dayDateFormatter.dateFormat=@"dd/MM/yyyy";
    NSDateFormatter *hourDateFormatter = [[NSDateFormatter alloc] init];
    hourDateFormatter.dateFormat=@"HH";

    // sort the bandsToAttend by startTime
    NSArray* bandsSortedByStartTime;
    if([options isEqualToString:@"recommendedBands"]){
        bandsSortedByStartTime = [Band sortBandsIn:self.bandsToAttend by:@"startTime"];
    }
    else if([options isEqualToString:@"allBands"]){
        bandsSortedByStartTime = [Band sortBandsIn:self.festival.bands by:@"startTime"];
    }
    
    // loop the bands and select the days to attend
    NSMutableArray* days = [[NSMutableArray alloc] init];
    for (Band* bandString in bandsSortedByStartTime){
        Band* band = [self.festival.bands objectForKey:bandString];
        
        // get the day of the band (avoiding a change of day for concerts after midnight)
        NSString* dayOfBand;
        if( [[hourDateFormatter stringFromDate:band.startTime] integerValue] >= 9 // after 9am
            &&
            [[hourDateFormatter stringFromDate:band.startTime] integerValue] <= 23 // before 0pm
           )
        {
            dayOfBand = [dayDateFormatter stringFromDate:band.startTime];
        }
        else if([[hourDateFormatter stringFromDate:band.startTime] integerValue] >= 0 // after 0pm
                &&
                [[hourDateFormatter stringFromDate:band.startTime] integerValue] <= 8 // before 9am
                )
        {
            dayOfBand = [dayDateFormatter stringFromDate:[band.startTime dateByAddingTimeInterval:-60*60*24]];
        }
        
        // dayOfBand still not in the list
        if( ![[days valueForKey:@"day"] containsObject:dayOfBand] ){
            
            [days addObject:@{@"day":dayOfBand,@"start":band.startTime,@"end":band.endTime}];
            
            lastDayAdded = dayOfBand;
            
            currentIndexOfDay = [days count] - 1;
            
        }
        // dayOfBand already in the list
        else{
            
            // update the end of the day
            NSMutableDictionary* dayTemp = [[days objectAtIndex:currentIndexOfDay] mutableCopy];
            if( [(NSDate*)[dayTemp objectForKey:@"end"] compare:band.endTime] == NSOrderedAscending ){
                [dayTemp setObject:band.endTime forKey:@"end"];
                [days replaceObjectAtIndex:currentIndexOfDay withObject:dayTemp];
            }
            
        }
    }
    
    return days;

}

-(NSArray*) bandsToAttendSortedByTimeBetween:(NSDate*) startDate and:(NSDate*) endDate withOptions:(NSString*) options
{
    /*
      Returns an array of "lowercaseName" with the bands in the indicated time period (between startDate and endDate)
        and sorted by band.endTime
     If there are no bandsToAttend selected (for example when no Must bands are still chosen), it assumes attendance to all bands
    */
    
    NSDictionary* bandsToLoop;
    if([options isEqualToString:@"recommendedBands"]){
        bandsToLoop = self.bandsToAttend;
    }
    else if([options isEqualToString:@"allBands"]){
        bandsToLoop = self.festival.bands;
    }
    
    // filter the bands between startDate and endDate
    NSMutableDictionary* bandsWithinRange = [[NSMutableDictionary alloc] init];
    for (Band* bandString in bandsToLoop){
        Band* band = [self.festival.bands objectForKey:bandString];
        //NSLog(@"range: %@ - %@",[startDate description], [endDate description]);
        //NSLog(@"band:  %@ - %@",[band.startTime description], [band.endTime description]);
        if( ( [band.startTime compare:startDate] == NSOrderedDescending
                ||
              [band.startTime compare:startDate] == NSOrderedSame
            )
            &&
            (
              [endDate compare:band.endTime] == NSOrderedDescending
                ||
              [endDate compare:band.endTime] == NSOrderedSame
            )
          )
        {
            [bandsWithinRange setObject:band forKey:band.lowercaseName];
        }
    }
    
    // sort the bandsToAttend by startTime
    NSArray* bandsSortedByStartTime = [Band sortBandsIn:bandsWithinRange by:@"endTime"];
    
    return bandsSortedByStartTime;
}


#pragma mark - Internal data management

-(void) addBand:(Band*) band inFreeSlotIndex:(NSInteger) freeSlotIndex
{
    
    // add band to array of attending bands
    [self.bandsToAttend setObject:[self.festival.bands objectForKey:band.lowercaseName] forKey:band.lowercaseName];
    
    // update the free slot that now is filled with the band
    [self updateFreeSlot:freeSlotIndex afterAddingBand:band];

}

-(void) updateFreeSlot:(NSInteger) freeSlotIndex afterAddingBand:(Band*)band
{
    
    // temporary store the limits of the old free slot
    NSDate* freeSlotStart = [self.freeSlots[freeSlotIndex] objectForKey:@"startTime"];
    NSDate* freeSlotEnd = [self.freeSlots[freeSlotIndex] objectForKey:@"endTime"];
    
    // remove old free slot
    [self.freeSlots removeObjectAtIndex:(NSUInteger)freeSlotIndex];
    
    // create new slot(s) after adding the band concert (both for "FullConcert" and "SecondHalfConcert")
    if([self.algorithmMode isEqualToString:@"FullConcert"]
       || [self.algorithmMode isEqualToString:@"FullConcertWithFreeTime"]
       || [self.algorithmMode isEqualToString:@"SecondHalfConcert"]
       || [self.algorithmMode isEqualToString:@"LastHalfHour"]){
        
        if( [freeSlotStart compare:band.startTime] == NSOrderedAscending && [freeSlotEnd compare:band.endTime] == NSOrderedDescending ){
            // the full band slot falls in the middle of the free slot => two new free slots are created
            [self.freeSlots addObject: @{@"startTime":freeSlotStart,@"endTime":band.startTime}];
            [self.freeSlots addObject: @{@"startTime":band.endTime,@"endTime":freeSlotEnd}];
        }
        
        if( [freeSlotStart compare:band.startTime] == NSOrderedSame && [freeSlotEnd compare:band.endTime] == NSOrderedDescending ){
            // the full band slot falls at the beginning of the free slot => one new free slots is created
            [self.freeSlots addObject: @{@"startTime":band.endTime,@"endTime":freeSlotEnd}];
        }
        
        if( [freeSlotStart compare:band.startTime] == NSOrderedAscending && [freeSlotEnd compare:band.endTime] == NSOrderedSame ){
            // the full band slot falls at the end of the free slot => one new free slots is created
            [self.freeSlots addObject: @{@"startTime":freeSlotStart,@"endTime":band.startTime}];
        }
        
        if( [freeSlotStart compare:band.startTime] == NSOrderedSame && [freeSlotEnd compare:band.endTime] == NSOrderedSame ){
            // the full band slot is the same as the free slot => no new slot is created
        }
        
    }
    
    // create new slot(s) after adding the band concert (only for "SecondHalfConcert" and "LastHalfHour")
    if( [self.algorithmMode isEqualToString:@"SecondHalfConcert"] || [self.algorithmMode isEqualToString:@"LastHalfHour"]){
        
        NSDate* intraConcertTime;
        
        if( [self.algorithmMode isEqualToString:@"SecondHalfConcert"]){
            intraConcertTime = [band.startTime dateByAddingTimeInterval:[band.endTime timeIntervalSinceDate:band.startTime]/2];
        }
        if( [self.algorithmMode isEqualToString:@"LastHalfHour"]){
            intraConcertTime = [band.endTime dateByAddingTimeInterval:-30*60];
        }
        
        if( [freeSlotStart compare:intraConcertTime] == NSOrderedSame && [freeSlotEnd compare:band.endTime] == NSOrderedDescending ){
            // exactly the second half of the concert slot falls at the beginning of the free slot => one new free slots is created
            [self.freeSlots addObject: @{@"startTime":band.endTime,@"endTime":freeSlotEnd}];
        }
        
        if( [freeSlotStart compare:band.startTime] == NSOrderedDescending && [freeSlotStart compare:intraConcertTime] == NSOrderedAscending && [freeSlotEnd compare:band.endTime] == NSOrderedDescending){
            // the second half (and earlier) of the concert slot falls at the beginning of the free slot => one new free slots is created
            [self.freeSlots addObject: @{@"startTime":band.endTime,@"endTime":freeSlotEnd}];
        }
        
        if( [freeSlotStart compare:intraConcertTime] == NSOrderedSame && [freeSlotEnd compare:band.endTime] == NSOrderedSame ){
            // exactly the second half of the concert slot is the same as the free slot => no new slot is created
        }
       
    }

}

-(void) removeBandFromSchedule:(Band*) band
{
    /*
     should update bandSlots, freeSlots, bandsToAttend,...
     */
}


#pragma mark - Schedule calculation

-(NSInteger) isThereAFreeSlotBetweenDate:(NSDate*) start andDate:(NSDate*) end
{
    /*
     Returns the index of the free slot, otherwise -1.
     */
 
    for(NSDictionary* freeSlot in self.freeSlots){
        
        NSDate* freeSlotStart = [freeSlot objectForKey:@"startTime"];
        NSDate* freeSlotEnd = [freeSlot objectForKey:@"endTime"];
        
        if(  ( [freeSlotStart compare:start] == NSOrderedAscending || [freeSlotStart compare:start] == NSOrderedSame )
             &&
             ( [freeSlotEnd compare:end] == NSOrderedDescending || [freeSlotEnd compare:end] == NSOrderedSame )
           )
        {
            return [self.freeSlots indexOfObject:freeSlot];
        }
    }
    return -1;
}

-(void) generateScheduleWithSFFSwithOptions:(NSDictionary*) options
{
    /*
     SFFS: Simply Fill Free Slots
     Options: 
        "mode" : "FullConcert" / "FullConcertWithFreeTime" / "SecondHalfConcert" / "LastHalfHour"
     */
    
    // read options
    NSString* mode = [options objectForKey:@"mode"];
    
    // sort bands by similarity
    NSMutableArray* bandsSortedBySimilarity = [[Band sortBandsIn:self.festival.bands by:@"bandSimilarity"] mutableCopy];
    
    // remove discarded bands
    for(NSString* discardedBand in [self.festival.discardedBands allKeys]){
        [bandsSortedBySimilarity removeObject:discardedBand];
    }
    
    // mode FullConcert: add band if there is a free slot for the full concert
    if([mode isEqualToString:@"FullConcert"]){
        
        for(NSString* bandString in bandsSortedBySimilarity){
            Band* band = [self.festival.bands objectForKey:bandString];
            NSInteger freeSlotIndex = [self isThereAFreeSlotBetweenDate: band.startTime andDate:band.endTime];
            if(freeSlotIndex >= 0){
                [self addBand:band inFreeSlotIndex:freeSlotIndex];
            }
            
            /*
             TODO: break if schedule is full
             */
        }
        
    }
    // mode FullConcertWithFreeTime: add band if there is a free slot for the full concert and free time around it
    else if([mode isEqualToString:@"FullConcertWithFreeTime"]){
        
        for(NSString* bandString in bandsSortedBySimilarity){
            Band* band = [self.festival.bands objectForKey:bandString];

            // 10 minutes of free time
            NSDate* startWithFreeTime = [band.startTime dateByAddingTimeInterval:-10*60];
            NSDate* endWithFreetime = [band.endTime dateByAddingTimeInterval:+10*60];
            
            NSInteger freeSlotIndex = [self isThereAFreeSlotBetweenDate:startWithFreeTime andDate:endWithFreetime];
            if(freeSlotIndex >= 0){
                [self addBand:band inFreeSlotIndex:freeSlotIndex];
            }
            
            /*
             TODO: break if schedule is full
             */
        }
    }
    // mode SecondHalfConcert: add band if there is a free slot for the second half of the concert
    else if([mode isEqualToString:@"SecondHalfConcert"]){
        
        for(NSString* bandString in bandsSortedBySimilarity){
            Band* band = [self.festival.bands objectForKey:bandString];
            
            NSDate* halfConcert = [band.startTime dateByAddingTimeInterval:[band.endTime timeIntervalSinceDate:band.startTime]/2];
            NSInteger freeSlotIndex = [self isThereAFreeSlotBetweenDate: halfConcert andDate:band.endTime];
            if(freeSlotIndex >= 0){
                [self addBand:band inFreeSlotIndex:freeSlotIndex];
            }
            
            /*
             TODO: break if schedule is full
             */
        }
    }
    // mode LastHalfHour: add band if there is a free slot for the last half hour of the concert
    else if([mode isEqualToString:@"LastHalfHour"]){
        
        for(NSString* bandString in bandsSortedBySimilarity){
            Band* band = [self.festival.bands objectForKey:bandString];
            
            NSDate* lastHalfHour = [band.endTime dateByAddingTimeInterval:-30*60];
            NSInteger freeSlotIndex = [self isThereAFreeSlotBetweenDate: lastHalfHour andDate:band.endTime];
            if(freeSlotIndex >= 0){
                [self addBand:band inFreeSlotIndex:freeSlotIndex];
            }
            
            /*
             TODO: break if schedule is full
             */
        }
    }

}

-(void) generateScheduleWithBUBBLE
{
    /*
     BUBBLE: ...
     */
}

@end
