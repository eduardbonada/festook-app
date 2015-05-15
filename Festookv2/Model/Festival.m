//
//  Festival.m
//  HorarisFestival
//
//  Created by Eduard on 5/17/13.
//  Copyright (c) 2013 ebc. All rights reserved.
//

#import "Festival.h"

#import "Band.h"
#import "FestivalSchedule.h"
#import "BandSimilarityCalculator.h"

@implementation Festival

// Designated initializer
-(Festival*) initWithDictionary:(NSDictionary *)dict
{
    if (self = [super init]){
        
        // set basic festival information
        self.uppercaseName  = [dict objectForKey:@"uppercaseName"];
        self.lowercaseName  = [dict objectForKey:@"lowercaseName"];
        self.when           = [dict objectForKey:@"when"];
        self.where          = [dict objectForKey:@"where"];
        self.date           = [dict objectForKey:@"formattedDate"];
        self.web            = [dict objectForKey:@"web"];
        self.twitter        = [dict objectForKey:@"twitter"];
        self.facebook       = [dict objectForKey:@"facebook"];
        self.youtube        = [dict objectForKey:@"youtube"];
        self.colorA         = [UIColor colorWithRed:[[[dict objectForKey:@"colorA"] objectForKey:@"R"] doubleValue]/255
                                              green:[[[dict objectForKey:@"colorA"] objectForKey:@"G"] doubleValue]/255
                                               blue:[[[dict objectForKey:@"colorA"] objectForKey:@"B"] doubleValue]/255
                                              alpha:1.0];
        self.colorB         = [UIColor colorWithRed:[[[dict objectForKey:@"colorB"] objectForKey:@"R"] doubleValue]/255
                                              green:[[[dict objectForKey:@"colorB"] objectForKey:@"G"] doubleValue]/255
                                               blue:[[[dict objectForKey:@"colorB"] objectForKey:@"B"] doubleValue]/255
                                              alpha:1.0];
        self.listBandsFile  = [dict objectForKey:@"listBandsFile"];
        self.bandDistanceFile = [dict objectForKey:@"bandDistanceFile"];
        self.state = [dict objectForKey:@"state"];
        self.festivalId = [dict objectForKey:@"festivalId"];

        // initialize festival state that refers to must/discarded bands
        self.mustBands      = [[NSMutableDictionary alloc] init];
        self.discardedBands = [[NSMutableDictionary alloc] init];
        
        self.recomputeSchedule = YES; // first time initialization
        
    }
    return self;
}

-(void) loadBandsFromJsonList
{
    
    // read file from application support directory and store its contents into an NSData object
    NSData *listBandsJsonData;
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[self.listBandsFile objectForKey:@"filename"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        listBandsJsonData = [[NSData alloc] initWithContentsOfFile:path];
    }
    else{
        NSLog(@"ERROR FestivalsBrowserVC::loadFestivalsData => File 'listFestivals.txt' does not exist");
    }
    
    // get list of bands as dictionary of dictionaries
    NSError *error = nil;
    NSDictionary* listBands = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:listBandsJsonData
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&error];
    if(error){
        NSLog(@"ERROR Festival::loadBandsFromJsonList => %@",error);
    }
    
    // date formatter for start/end times
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"dd/MM/yyyy HH:mm";
    
    // create band objects, and identify time-limits
    NSMutableDictionary* dictBands = [[NSMutableDictionary alloc] init];
    NSDate* minStart = [NSDate distantFuture];
    NSDate* maxEnd = [NSDate distantPast];
    for(NSString* bandString in [listBands allKeys]){

        NSDictionary* bandDict = [listBands objectForKey:bandString];
        
        // manage start and end time-limits
        NSDate* bandStart = [dateFormatter dateFromString: [bandDict objectForKey: @"startTime"]];
        NSDate* bandEnd   = [dateFormatter dateFromString: [bandDict objectForKey: @"endTime"]];
        minStart = ([bandStart compare:minStart] == NSOrderedAscending) ? bandStart : minStart ;
        maxEnd   = ([maxEnd compare:bandEnd] == NSOrderedAscending) ? bandEnd : maxEnd ;

        // create band object and add it to dictionary to return
        Band* band = [[Band alloc] initWithUppercaseName:[bandDict objectForKey: @"uppercaseName"]
                                           lowercaseName:[bandDict objectForKey: @"lowercaseName"]
                                                  bandId:[bandDict objectForKey: @"bandId"]
                                               startTime:bandStart
                                                 endtime:bandEnd
                                                   stage:[bandDict objectForKey: @"stage"]
                                                  origin:[bandDict objectForKey: @"origin"]
                                                   style:[bandDict objectForKey: @"style"]
                                                infoText:[bandDict objectForKey: @"infoText"]
                                                festival:self];
        [dictBands setObject:band forKey:bandString];
        
    }
    
    // set festival time-limits
    self.start = minStart;
    self.end = maxEnd;

    // set the bands objects
    self.bands = dictBands;
    
}

-(void) updateBandSimilarityModel
{

    // lazy instantiation of FestivalSchedule
    if(!self.schedule){
        self.schedule = [[FestivalSchedule alloc] initWithFestival:self];
    }

    // lazy instantiation of BandSimilarityCalculator
    if(!self.bandSimilarityCalculator){
        self.bandSimilarityCalculator = [[BandSimilarityCalculator alloc] initWithFestival:self];
    }
    
    // calculate the band similarity with the current mustBands
    [self.bandSimilarityCalculator computeBandSimilarityToMustBands];

}

-(NSString*) summaryOfFestival
{
    NSString* summary = @"";
    
    summary = [summary stringByAppendingFormat:@"lowercaseName:\t%@\n",self.lowercaseName];
    summary = [summary stringByAppendingFormat:@"uppercaseName:\t%@\n",self.uppercaseName];
    summary = [summary stringByAppendingFormat:@"when:\t%@\n",self.when];
    summary = [summary stringByAppendingFormat:@"where:\t%@\n",self.where];
    summary = [summary stringByAppendingFormat:@"date:\t%@\n",self.date];
    summary = [summary stringByAppendingFormat:@"start:\t%@\n",self.start];
    summary = [summary stringByAppendingFormat:@"end:\t%@\n",self.end];
    summary = [summary stringByAppendingFormat:@"colorA:\t%@\n",self.colorA];
    summary = [summary stringByAppendingFormat:@"colorB:\t%@\n",self.colorB];
    summary = [summary stringByAppendingFormat:@"web:\t%@\n",self.web];
    summary = [summary stringByAppendingFormat:@"listBandsFile:\t%@\n",self.listBandsFile];
    summary = [summary stringByAppendingFormat:@"bandDistanceFile:\t%@\n",self.bandDistanceFile];
    summary = [summary stringByAppendingFormat:@"mustBands:\t%@\n",self.mustBands];
    summary = [summary stringByAppendingFormat:@"discardedBands:\t%@\n",self.discardedBands];
    summary = [summary stringByAppendingFormat:@"bands:\t%@\n",self.bands];
    
    return summary;
}

-(NSArray*) stageNames
{
    NSMutableSet* allStages = [[NSMutableSet alloc] init];
    for (Band* band in [self.bands allValues]){
        [allStages addObject:band.stage];
    }
    return [allStages allObjects];
}

-(NSNumber*) hoursOfMusic
{
    NSNumber *hours = @(0.0);
    for (Band* band in [self.bands allValues]){
        hours = @([hours doubleValue] + [band.endTime timeIntervalSinceDate:band.startTime]/3600);
    }
    return hours;
    
}

-(NSNumber*) distanceBetweenBands:(NSString*) bandNameA and:(NSString*) bandNameB
{
    return [[self.bandSimilarityCalculator.distanceBetweenBands objectForKey:bandNameA] objectForKey:bandNameB];
}

-(NSArray*) bandsPlayingAtDate:(NSDate*) date withSorting:(NSString*) sorting
{
    // returns and array of bandnames with that bands playing right now

    NSMutableArray* playingBands = [[NSMutableArray alloc] init];
    
    
    for (Band* band in [self.bands allValues]){
        if( ([band.startTime compare:date] == NSOrderedAscending) && ([date compare:band.endTime] == NSOrderedAscending) ){
            NSNumber *sortValue = @(0);
            if([sorting isEqualToString:@"progress"]){
                CGFloat progress = [band.startTime timeIntervalSinceDate:date] / [band.startTime timeIntervalSinceDate:band.endTime];
                sortValue = @(progress);
            }
            else{
                NSLog(@"ERROR in Festival:bandsPlayingAtDate => Wrong sorting option");
            }
            [playingBands addObject:@{@"bandname":band.lowercaseName,@"sortValue":sortValue}];
        }
    }
    
    // sort array by sortValue
    NSSortDescriptor *sortBySortValue = [NSSortDescriptor sortDescriptorWithKey:@"sortValue" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortBySortValue];
    NSArray *sortedPlayingBands = [playingBands sortedArrayUsingDescriptors:sortDescriptors];
    
    NSMutableArray* sortedPlayingBandsnames = [[NSMutableArray alloc] init];
    for(NSDictionary* band in sortedPlayingBands){
        [sortedPlayingBandsnames addObject:band[@"bandname"]];
    }
    
    return sortedPlayingBandsnames;
}

#pragma mark - Update from NSUserDefaults

-(void) storeMustBandsInNSUserDefaults
{
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // get actual mustBands stored in NSUserDefaults, or create it if it is the first time
    NSMutableDictionary *allFestivalsMustBands = [[defaults objectForKey:@"allFestivalsMustBands"] mutableCopy];
    if(!allFestivalsMustBands){
        allFestivalsMustBands = [[NSMutableDictionary alloc] init];
    }
    
    // update allFestivalsMustBands
    [allFestivalsMustBands setObject:[self.mustBands allKeys] forKey:self.lowercaseName];
    
    // NSLog(@"%@", [allFestivalsMustBands description]);
    
    // re-store in NSUserDefaults
    [defaults setObject:allFestivalsMustBands forKey:@"allFestivalsMustBands"];
    [defaults synchronize];
    
    self.recomputeSchedule = YES;
    self.updateReminders = YES;
    
}
-(NSMutableDictionary*) getMustBandsFromNSUserDefaults
{
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // get actual mustBands stored in NSUserDefaults
    NSMutableDictionary *allFestivalsMustBands = [[defaults objectForKey:@"allFestivalsMustBands"] mutableCopy];
    
    //NSLog(@"%@", [allFestivalsMustBands description]);
    
    // set the current festival mustBands
    for(NSString* bandName in [allFestivalsMustBands objectForKey:self.lowercaseName]){
        [self.mustBands setObject:[self.bands objectForKey:bandName] forKey:bandName];
    }
    
    self.recomputeSchedule = YES;
    
    return self.mustBands;
    
}
-(void) storeDiscardedBandsInNSUserDefaults
{
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // get actual discardedBands stored in NSUserDefaults, or create it if it is the first time
    NSMutableDictionary *allFestivalsDiscardedBands = [[defaults objectForKey:@"allFestivalsDiscardedBands"] mutableCopy];
    if(!allFestivalsDiscardedBands){
        allFestivalsDiscardedBands = [[NSMutableDictionary alloc] init];
    }
    
    // update allFestivalsDiscardedBands
    [allFestivalsDiscardedBands setObject:[self.discardedBands allKeys] forKey:self.lowercaseName];
    
    //NSLog(@"%@", [allFestivalsDiscardedBands description]);
    
    // re-store in NSUserDefaults
    [defaults setObject:allFestivalsDiscardedBands forKey:@"allFestivalsDiscardedBands"];
    [defaults synchronize];
    
    self.recomputeSchedule = YES;
    self.updateReminders = YES;
    
}
-(NSMutableDictionary*) getDiscardedBandsFromNSUserDefaults
{
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // get actual discardedBands stored in NSUserDefaults
    NSMutableDictionary *allFestivalsDiscardedBands = [[defaults objectForKey:@"allFestivalsDiscardedBands"] mutableCopy];
    
    //NSLog(@"%@", [allFestivalsMustBands description]);
    
    // set the current festival mustBands
    for(NSString* bandName in [allFestivalsDiscardedBands objectForKey:self.lowercaseName]){
        [self.discardedBands setObject:[self.bands objectForKey:bandName] forKey:bandName];
    }
    
    self.recomputeSchedule = YES;

    return self.discardedBands;
    
}


@end
