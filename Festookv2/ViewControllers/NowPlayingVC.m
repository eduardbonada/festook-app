//
//  NowPlayingVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 13/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "NowPlayingVC.h"

#import "EbcEnhancedView.h"

#import "Band.h"
#import "NowPlayingTableViewCell.h"
#import "BandInfoVC.h"

#import "Flurry.h"

@interface NowPlayingVC ()

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (weak, nonatomic) IBOutlet UITextView *emptyListTextView;

@property (weak, nonatomic) IBOutlet UITableView *nowPlayingTableView;

@property (strong, nonatomic) NSArray* nowPlayingBands; // of {"arcadefire","thenational",...}

@end

@implementation NowPlayingVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self logPresenceEventInFlurry];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setup];
}

-(void) setup
{
    // set background image
    self.backgroundView.roundedRects = NO;
    //[self.backgroundView setBackgroundImage:[UIImage imageNamed:self.festival.image] withAlpha:@(1.0)];
    [self.backgroundView setBackgroundGradientFromColor:self.festival.colorA
                                                toColor:self.festival.colorB];

    // temporary date formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"dd/MM/yyyy HH:mm";

    // get the bands playing right now
    NSDate *now = [NSDate date]; //[dateFormatter dateFromString:@"29/05/2015 22:05"]
    self.nowPlayingBands = [self.festival bandsPlayingAtDate:now withSorting:@"progress"]; //@[@"belleandsebastian",@"derpanther",@"damienrice",@"altj"];
    
    if([self.nowPlayingBands count] > 0){
        // there are bands playing right now
        self.emptyListTextView.hidden = YES;
    }
    else{
        // there are no bands playing right now
        self.emptyListTextView.hidden = NO;
    }
    
    [self.nowPlayingTableView setContentInset:UIEdgeInsetsMake(5,0,0,0)];
    
    [self.nowPlayingTableView reloadData];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowBandInfo"]) {
        
        if ([segue.destinationViewController isKindOfClass:[BandInfoVC class]]) {
            
            // set title of 'back' button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStylePlain target:nil action:nil];
            
            // Configure destination VC
            BandInfoVC *bivc = segue.destinationViewController;
            if ([bivc isKindOfClass:[BandInfoVC class]]) {
                //[bivc setTitle:self.festival.uppercaseName];
                NSIndexPath* indexPath = [self.nowPlayingTableView indexPathForSelectedRow];
                bivc.band = [self.festival.bands objectForKey:[self.nowPlayingBands objectAtIndex:indexPath.row]];
                bivc.userID = self.userID;
            }
        }
    }
}

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Now_Playing_Shown" withParameters:@{@"userID":self.userID,@"festival":self.festival.lowercaseName}];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.nowPlayingBands count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // hour formatter
    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    hourFormatter.dateFormat=@"HH:mm";

    NowPlayingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Now Playing Cell" forIndexPath:indexPath];
    
    Band* bandToShow = ((Band*)[self.festival.bands objectForKey:[self.nowPlayingBands objectAtIndex:indexPath.item]]);
    
    // set background
    cell.background.roundedRects = YES;
    cell.background.cornerRadius = @(10.0);
    [cell.background setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];

    // set attributes of band name
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    UIColor* bandColorDependingOnMustDiscard;
    if([self.festival.mustBands objectForKey:bandToShow.lowercaseName]){
        bandColorDependingOnMustDiscard = [UIColor colorWithRed:140.0/255 green:180.0/255 blue:15.0/255 alpha:1.0];
    }
    else if([self.festival.discardedBands objectForKey:bandToShow.lowercaseName]){
        bandColorDependingOnMustDiscard = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.6];
    }
    else{
        bandColorDependingOnMustDiscard = [UIColor darkGrayColor];
    }
    NSDictionary* attributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:17],
                                 NSForegroundColorAttributeName : bandColorDependingOnMustDiscard,
                                 NSParagraphStyleAttributeName : paragraphStyle};


    // set labels
    cell.bandName.attributedText = [[NSAttributedString alloc] initWithString:bandToShow.uppercaseName attributes:attributes];
    cell.stage.text = bandToShow.stage;
    cell.startEndTime.text = [NSString stringWithFormat:@"%@-%@",[hourFormatter stringFromDate:bandToShow.startTime],[hourFormatter stringFromDate:bandToShow.endTime]];

    // set progress view
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"dd/MM/yyyy HH:mm";
    NSDate* now = [NSDate date]; //[dateFormatter dateFromString:@"29/05/2015 22:05"]
    cell.concertProgressView.trackTintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    cell.concertProgressView.progressTintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    CGFloat progress = [bandToShow.startTime timeIntervalSinceDate: now] / [bandToShow.startTime timeIntervalSinceDate:bandToShow.endTime];
    
    // present progress view
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [cell.concertProgressView setProgress:progress animated:YES];
    });
    

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

@end
