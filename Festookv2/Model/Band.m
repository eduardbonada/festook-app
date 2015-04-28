//
//  Band.m
//  HorarisFestival
//
//  Created by Eduard on 5/10/13.
//  Copyright (c) 2013 ebc. All rights reserved.
//

#import "Band.h"

@implementation Band

// Designated initializer
-(Band*)initWithUppercaseName:(NSString*) uppercaseName
                lowercaseName:(NSString*) lowercaseName
                       bandId:(NSString*) bandId
                    startTime:(NSDate*)   startTime
                      endtime:(NSDate*)   endTime
                        stage:(NSString*) stage
                       origin:(NSString*) origin
                        style:(NSString*) style
                     infoText:(NSString*) infoText
                     festival:(Festival *)festival
{
    if (self = [super init]){
        self.uppercaseName = uppercaseName;
        self.lowercaseName = lowercaseName;
        self.bandId = bandId;
        self.startTime = startTime;
        self.endTime = endTime;
        self.stage = stage;
        self.style = style;
        self.infoText = infoText;

        self.festival = festival;
        
        self.bandSimilarityToMustBands = @0;
    }
    return self;
}

+(NSArray*) sortBandsIn:(NSDictionary*)bands by:(NSString*) sortingMode
{
    /*
     bands: {"lowercaseName":Band, ...}
     sortingMode: "alphabetically", "bandSimilarity", "bandIdentifier", "startTime", "endTime"...
     returned array: ["lowercaseName",...]
     */
    
    if([sortingMode isEqualToString:@"alphabetically"]){
        return [bands.allKeys sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];
    }
    
    else if([sortingMode isEqualToString:@"bandSimilarity"]){
        return [bands keysSortedByValueUsingComparator:
                    ^NSComparisonResult(Band* bandA, Band* bandB)
                    {
                        return [bandB.bandSimilarityToMustBands compare:bandA.bandSimilarityToMustBands];
                    }
                ];
    }

    else if([sortingMode isEqualToString:@"startTime"]){
        return [bands keysSortedByValueUsingComparator:
                    ^NSComparisonResult(Band* bandA, Band* bandB)
                    {
                        return [bandA.startTime compare:bandB.startTime];
                    }
                ];
    }

    else if([sortingMode isEqualToString:@"endTime"]){
        return [bands keysSortedByValueUsingComparator:
                    ^NSComparisonResult(Band* bandA, Band* bandB)
                    {
                        return [bandA.endTime compare:bandB.endTime];
                    }
                ];
    }

    else if([sortingMode isEqualToString:@"bandIdentifier"]){
        return [bands keysSortedByValueUsingComparator:
                    ^NSComparisonResult(Band* bandA, Band* bandB)
                    {
                        return [bandA.bandId compare:bandB.bandId];
                    }
                ];
    }

    else{
        NSLog(@"ERROR FestivalBandsBrowserVC sortBandsIn:by: => sortingMode not available");
        return @[];
    }
    
}

-(NSDate*) dayOfConcert
{
    /*
     Retuns the day of the concert, considering that an hour after 0:00 really refers to the previous day
    */
    
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    dayFormatter.dateFormat=@"dd/MM/yyyy";

    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    hourFormatter.dateFormat=@"HH";
    
    NSDate* day = [dayFormatter dateFromString:[dayFormatter stringFromDate:self.startTime]];
    NSInteger hour = [[hourFormatter stringFromDate: self.startTime] integerValue];
    if (hour < 9) {
        day = [day dateByAddingTimeInterval:-3600*24];
    }
    
    return day;
}

-(NSString*) weekdayOfConcert
{
    /*
     Returns a string with the day of the week of the concert
     */

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [gregorian setFirstWeekday:2];
    
    NSUInteger weekdayNumber = [gregorian ordinalityOfUnit:NSCalendarUnitWeekday inUnit:NSCalendarUnitWeekOfMonth forDate:[self dayOfConcert]];    
    NSArray *daysOfWeek = @[@"",@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"];


	return [[NSString alloc] initWithFormat:@"%@",[daysOfWeek objectAtIndex:weekdayNumber]];
}


@end
