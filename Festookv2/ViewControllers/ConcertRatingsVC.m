//
//  ConcertRatingsVC.m
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 04/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "ConcertRatingsVC.h"

#import "Band.h"
#import "FestivalSchedule.h"
#import "ConcertRatingTableViewCell.h"

#import "FestivalRevealVC.h"
#import "SWRevealViewController.h"

#import "EbcEnhancedView.h"

#import "Flurry.h"

@interface ConcertRatingsVC () <SWRevealViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UITextView *emptyListTextView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (strong, nonatomic) NSArray* allBandsThatAlreadyPlayed;

@end


#pragma mark - Initialization

@implementation ConcertRatingsVC

- (void)viewDidLoad
{

    [super viewDidLoad];
    
    // set navigation bar title
    self.title = @"Concerts Ratings";
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16],
                              NSForegroundColorAttributeName:[UIColor darkGrayColor]
                              }
     ];

    // SWRevealViewController: configure target/action to menu button
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    self.festival = ((FestivalRevealVC*)self.revealViewController).festival;
    self.userID = ((FestivalRevealVC*)self.revealViewController).userID;
    
    [self logPresenceEventInFlurry];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    [self setup];
}

-(void) setup
{
    // temporary dat formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"dd/MM/yyyy HH:mm";

    // set background image
    self.backgroundView.roundedRects = NO;
    //[self.backgroundView setBackgroundImage:[UIImage imageNamed:self.festival.image] withAlpha:@(1.0)];
    [self.backgroundView setBackgroundGradientFromColor:self.festival.colorA
                                                toColor:self.festival.colorB];

    BOOL concertHasStarted = [[NSDate date] compare: self.festival.start] == NSOrderedDescending;
    if(concertHasStarted){
        
        if([self.festival.mustBands count] > 0){
            self.titleLabel.hidden = NO;
            self.subtitleLabel.hidden = NO;
            self.emptyListTextView.hidden = YES;
            
            // get which bands have already played
            [self.festival.schedule computeSchedule];
            NSArray *allRecommendedBands = [self.festival.schedule bandsToAttendSortedByTimeBetween:self.festival.start and:self.festival.end withOptions:@"recommendedBands"];
            NSMutableArray *allBandsThatAlreadyPlayed = [[NSMutableArray alloc] init];
            for(NSString* bandName in allRecommendedBands){
                NSDate *currentTime = [NSDate date]; //[dateFormatter dateFromString:@"29/05/2014 23:59"];
                
                NSDate *bandEndingTime = ((Band*)[self.festival.bands objectForKey:bandName]).endTime;
                if([currentTime compare:bandEndingTime] == NSOrderedDescending){
                    [allBandsThatAlreadyPlayed addObject:bandName];
                }
                else{
                    break;
                }
            }
            
            // inverse list of bands so the latest is on top
            self.allBandsThatAlreadyPlayed = [[allBandsThatAlreadyPlayed reverseObjectEnumerator] allObjects];
            
        }
        else{
            // No must bands

            self.titleLabel.hidden = YES;
            self.subtitleLabel.hidden = YES;
            self.emptyListTextView.hidden = NO;
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            self.emptyListTextView.attributedText = [[NSAttributedString alloc] initWithString:@"There are no concerts to rate because your schedule is still empty."
                                                                                    attributes:@{NSParagraphStyleAttributeName:paragraphStyle,
                                                                                                 NSForegroundColorAttributeName:[UIColor whiteColor],
                                                                                                 NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16]}
                                                     ];

        }
        
    }
    else{
        // Festival has not started yet
        
        self.titleLabel.hidden = YES;
        self.subtitleLabel.hidden = YES;
        self.emptyListTextView.hidden = NO;
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        self.emptyListTextView.attributedText = [[NSAttributedString alloc] initWithString:@"There are no concerts to rate because the festival has not started yet."
                                                                                attributes:@{NSParagraphStyleAttributeName:paragraphStyle,
                                                                                             NSForegroundColorAttributeName:[UIColor whiteColor],
                                                                                             NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16]}
                                                 ];
    }

    // set self as revealVC delegate
    self.revealViewController.delegate = self;
    
    // hide the overlay view
    if(self.revealViewController.frontViewPosition != FrontViewPositionLeft){
        self.overlayView.hidden = NO;
    }
    else{
        self.overlayView.hidden = YES;
    }

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allBandsThatAlreadyPlayed count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConcertRatingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Concert Rating Cell" forIndexPath:indexPath];
    
    Band* bandToShow = ((Band*)[self.festival.bands objectForKey:[self.allBandsThatAlreadyPlayed objectAtIndex:indexPath.item]]);

    // set background
    cell.background.roundedRects = YES;
    cell.background.cornerRadius = @(10.0);
    [cell.background setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    
    // set label
    cell.bandName.text = bandToShow.uppercaseName;
    
    // set segmented control
    [cell.bandRating setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0]}
                                   forState:UIControlStateNormal];
    [cell.bandRating setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Bold" size:13.0],
                                              NSForegroundColorAttributeName:[UIColor lightTextColor]}
                                   forState:UIControlStateSelected];
    [cell.bandRating setBackgroundColor:[UIColor clearColor]];
    [cell.bandRating addTarget:self
                        action:@selector(ratingSegmentedControlValueChanged:)
              forControlEvents:UIControlEventValueChanged];
    cell.bandRating.tag = indexPath.item; // the tag stores the row index
    
    // get the selectedIndex from the NSUserDefaults
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSMutableDictionary *concertRatings = [[[NSUserDefaults standardUserDefaults] valueForKeyPath:[NSString stringWithFormat:@"concertRatings.%@",self.festival.lowercaseName]] mutableCopy];
    NSString* bandRating = [concertRatings objectForKey:bandToShow.lowercaseName];
    
    // obtain the index to select
    NSUInteger selectedSegment = -1;
    if([bandRating isEqualToString:[cell.bandRating titleForSegmentAtIndex:0]]){
        selectedSegment = 0;
    }
    else if([bandRating isEqualToString:[cell.bandRating titleForSegmentAtIndex:1]]){
        selectedSegment = 1;
    }
    else if([bandRating isEqualToString:[cell.bandRating titleForSegmentAtIndex:2]]){
        selectedSegment = 2;
    }
    
    // paint the segmented control with the right color
    [self highlightSegmentedControl:cell.bandRating AtSegment:selectedSegment];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

#pragma mark - Rating action

- (void)ratingSegmentedControlValueChanged:(id)sender
{
    UISegmentedControl *bandRatingSegmentedControl = (UISegmentedControl *)sender;
    Band* bandRated = (Band*)[self.festival.bands objectForKey:[self.allBandsThatAlreadyPlayed objectAtIndex:bandRatingSegmentedControl.tag]];
    
    // update appearance of segmented control
    [self highlightSegmentedControl:bandRatingSegmentedControl AtSegment:bandRatingSegmentedControl.selectedSegmentIndex];

    // update band rating in NSUserDefaults
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *concertRatings = [[defaults objectForKey:@"concertRatings"] mutableCopy];
    if(!concertRatings){
        // create the concertRatings if it does not exist
        concertRatings = [[NSMutableDictionary alloc] init];
    }
    if(![concertRatings objectForKey:self.festival.lowercaseName]){
        // create the festival ratings if it does not exist
        [concertRatings setObject:[[NSMutableDictionary alloc] init] forKey:self.festival.lowercaseName];
    }
    NSMutableDictionary* festivalRatings = [[concertRatings objectForKey:self.festival.lowercaseName] mutableCopy];
    [festivalRatings setObject:[bandRatingSegmentedControl titleForSegmentAtIndex:bandRatingSegmentedControl.selectedSegmentIndex]
                       forKey:bandRated.lowercaseName];
    [concertRatings setObject:festivalRatings forKey:self.festival.lowercaseName];
    [defaults setObject:concertRatings forKey:@"concertRatings"];
    [defaults synchronize];

    // log in Flurry
    [self logConcertRatingInFlurryForBand:bandRated andRating:[bandRatingSegmentedControl titleForSegmentAtIndex:bandRatingSegmentedControl.selectedSegmentIndex]];

}

-(void) highlightSegmentedControl:(UISegmentedControl*) segmentedControl AtSegment:(NSUInteger) segment
{
    if(segment == 0){
        // show YES
        segmentedControl.tintColor = [UIColor colorWithRed:147.0/255 green:197.0/255 blue:14.0/255 alpha:0.7];
    }
    else if(segment == 1){
        // show ?
        segmentedControl.tintColor = [UIColor grayColor];
    }
    else if(segment == 2){
        // show NO
        segmentedControl.tintColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    }
    else{
        segmentedControl.tintColor = [UIColor lightGrayColor];
    }
    
    segmentedControl.selectedSegmentIndex = segment;
}

#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Concert_Ratings_Shown" withParameters:@{@"userID":self.userID,@"festival":self.festival.lowercaseName}];
}

-(void)logConcertRatingInFlurryForBand:(Band*)band andRating:(NSString*) rating
{
    [Flurry logEvent:@"Concert_Rating" withParameters:@{@"userID":self.userID,
                                                        @"festival":self.festival.lowercaseName,
                                                        @"bandName":band.lowercaseName,
                                                        @"rating":rating}];
}


#pragma mark - SWRevealViewController delegate

- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
    [self updateInteractionWhenFrontViewMovesToPosition:position];
    
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    [self updateInteractionWhenFrontViewMovesToPosition:position];
}

-(void) updateInteractionWhenFrontViewMovesToPosition:(FrontViewPosition) position
{
    if(position == FrontViewPositionLeft) {
        self.tableView.userInteractionEnabled = YES;
        self.overlayView.hidden = YES;
        
    } else {
        self.tableView.userInteractionEnabled = NO;
        self.overlayView.hidden = NO;
    }
}


@end
