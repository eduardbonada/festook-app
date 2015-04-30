//
//  FestivalScheduleVC.m
//  Festook
//
//  Created by Eduard Bonada Cruells on 14/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "FestivalScheduleVC.h"

#import "FestivalRevealVC.h"
#import "SWRevealViewController.h"

#import "Flurry.h"

#import "EbcEnhancedView.h"
#import "FestivalSchedule.h"
#import "Band.h"
#import "BandInfoVC.h"

@interface FestivalScheduleVC () <SWRevealViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *daysSegmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *scheduleTableView;

@property (weak, nonatomic) IBOutlet UIButton *emptyScheduleBandsButton;
@property (weak, nonatomic) IBOutlet UITextView *emptyScheduleTextView;

@property (strong, nonatomic) FestivalSchedule* schedule;
@property (strong, nonatomic) NSMutableArray* bandsToAttend;

@property (strong, nonatomic) NSMutableArray* daysToAttend; // of dictionaries {"day":"dd/mm/yyyy","start":NSDate,"end":NSDate}
@property (strong, nonatomic) NSNumber* currentDayShown; // as the index of the segmentel control

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@end

@implementation FestivalScheduleVC

#pragma mark - Initialization


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set navigation bar title
    self.title = @"Personalized Schedule";
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

    self.festival.changeInMustOrDiscarded = YES; // mark to perform schedule computations
    
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
    
    // create the FestivalSchedule object
    self.schedule = self.festival.schedule;
    if(!self.schedule){
        self.schedule = [[FestivalSchedule alloc] initWithFestival:self.festival];
    }
    
    // if there are mustBands selected
    if([self.festival.mustBands count] > 0){
        
        // hide textView&Button for the case of no mustBands
        self.emptyScheduleTextView.hidden = YES;
        self.emptyScheduleBandsButton.hidden = YES;
        
        // unhide table view and segmented control
        self.scheduleTableView.hidden = NO;
        self.daysSegmentedControl.hidden = NO;
        
        // configure day segmented control
        [self.daysSegmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:14.0],
                                                            NSForegroundColorAttributeName:[UIColor darkGrayColor]
                                                            }
                                                 forState:UIControlStateNormal];
        
        // update schedule
        [self updateSchedule];
        
    }
    // if there are no mustBands selected
    else{
        
        // hide table view and segmented control
        self.scheduleTableView.hidden = YES;
        self.daysSegmentedControl.hidden = YES;
        
        // show text and button
        self.emptyScheduleTextView.hidden = NO;
        self.emptyScheduleBandsButton.hidden = NO;
        self.emptyScheduleBandsButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.emptyScheduleBandsButton.layer.borderWidth = 1.0;
        self.emptyScheduleBandsButton.layer.cornerRadius = 6;
        
        // clear bandsToAttend
        [self.bandsToAttend removeAllObjects];
        
        // hide 'Groups' button in the nav bar
        self.navigationItem.rightBarButtonItem = nil;
        
        // unhide 'Help' button in the nav bar
        // [self.navigationItem setRightBarButtonItems:@[self.helpButtonNavigationBar] animated:TRUE];
        
    }
    
    // set tableView top offset to add distance to segm. control
    [self.scheduleTableView setContentInset:UIEdgeInsetsMake(10,0,0,0)];
    
    [self reloadScheduleTableDataWithAnimation:0];
    
    // set background image
    self.backgroundView.roundedRects = NO;
    //[self.backgroundView setBackgroundImage:[UIImage imageNamed:self.festival.image] withAlpha:@(1.0)];
    [self.backgroundView setBackgroundGradientFromColor:self.festival.colorA
                                                toColor:self.festival.colorB];
    
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

-(void) updateSchedule
{
    
    // compute the schedule
    if(self.festival.changeInMustOrDiscarded){
        
        [self.festival updateBandSimilarityModel];
        
        [self.schedule computeSchedule];
        
        // get the days to attend and update segmented control (only of days have changed)
        if([self.daysToAttend count] != [[self.schedule daysToAttendWithOptions:@"recommendedBands"] count]){
            self.daysToAttend = [[self.schedule daysToAttendWithOptions:@"recommendedBands"] mutableCopy];
            [self setupDaysSegmentedControlForDays: self.daysToAttend];
        }
        
        // get the bands to attend
        [self updateTableViewForDay:[self.daysToAttend objectAtIndex:[self.currentDayShown integerValue]]];
        
        self.festival.changeInMustOrDiscarded = NO;
    }
    
}


#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Schedule_Shown" withParameters:@{@"userID":self.userID,@"festival":[self.festival lowercaseName]}];
}



#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    /*
     if ([segue.identifier isEqualToString:@"ShowFestivalBands"]) {
        if ([segue.destinationViewController isKindOfClass:[FestivalBandsBrowserVC class]]) {
            
            // set title of 'back' button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Horari" style:UIBarButtonItemStylePlain target:nil action:nil];
            
            // Configure destination VC
            FestivalBandsBrowserVC *fbbvc = segue.destinationViewController;
            if ([fbbvc isKindOfClass:[FestivalBandsBrowserVC class]]) {
                //[fbbvc setTitle:self.festival.uppercaseName];
                fbbvc.festival = self.festival;
            }
            
        }
    }
    else
     */
    
     
    if ([segue.identifier isEqualToString:@"ShowBandInfo"]) {
        
        if ([segue.destinationViewController isKindOfClass:[BandInfoVC class]]) {
            
            // set title of 'back' button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Schedule" style:UIBarButtonItemStylePlain target:nil action:nil];
            
            // Configure destination VC
            BandInfoVC *bivc = segue.destinationViewController;
            if ([bivc isKindOfClass:[BandInfoVC class]]) {
                //[bivc setTitle:self.festival.uppercaseName];
                NSIndexPath* indexPath = [self.scheduleTableView indexPathForSelectedRow];
                bivc.band = [self.festival.bands objectForKey:[self.bandsToAttend objectAtIndex:indexPath.row]];
                bivc.userID = self.userID;
            }
        }
    }
}

/*
- (IBAction)swipeRightInCollectionView:(UISwipeGestureRecognizer *)sender
{
    
    if(self.daysSegmentedControl.selectedSegmentIndex > 0){
        self.daysSegmentedControl.selectedSegmentIndex--;
        self.currentDayShown = @(self.daysSegmentedControl.selectedSegmentIndex);
        [self updateTableViewForDay:[self.daysToAttend objectAtIndex:self.daysSegmentedControl.selectedSegmentIndex]];
        [self reloadScheduleTableDataWithAnimation: UITableViewRowAnimationRight];
        [self.scheduleTableView setContentOffset:CGPointMake(0.0, -10.0) animated:YES]; // scroll to the top
    }
    
}

- (IBAction)swipeLeftInCollectionView:(UISwipeGestureRecognizer *)sender
{
    
    if(self.daysSegmentedControl.selectedSegmentIndex < self.daysSegmentedControl.numberOfSegments - 1){
        self.daysSegmentedControl.selectedSegmentIndex++;
        self.currentDayShown = @(self.daysSegmentedControl.selectedSegmentIndex);
        [self updateTableViewForDay:[self.daysToAttend objectAtIndex:self.daysSegmentedControl.selectedSegmentIndex]];
        [self reloadScheduleTableDataWithAnimation: UITableViewRowAnimationLeft];
        [self.scheduleTableView setContentOffset:CGPointMake(0.0, -10.0) animated:YES]; // scroll to the top
    }
}
*/

#pragma mark - day to attend views configuration

-(void) setupDaysSegmentedControlForDays:(NSArray*) days
{
    NSUInteger originalNumberOfSegments = self.daysSegmentedControl.numberOfSegments;
    
    [self.daysSegmentedControl removeAllSegments];
    
    NSUInteger segmentCounter = 0;
    for(NSString* dayString in [days valueForKey:@"day"]){
        [self.daysSegmentedControl insertSegmentWithTitle:[[dayString componentsSeparatedByString:@"/"] objectAtIndex:0]
                                                  atIndex:segmentCounter animated:YES];
        segmentCounter++;
    }
    
    if(originalNumberOfSegments != self.daysSegmentedControl.numberOfSegments){
        self.currentDayShown = 0;
    }
    self.daysSegmentedControl.selectedSegmentIndex = [self.currentDayShown integerValue];
    
}

-(void) updateTableViewForDay:(NSDictionary*) day
{
    self.bandsToAttend = [[self.schedule bandsToAttendSortedByTimeBetween:[day objectForKey:@"start"]
                                                                      and:[day objectForKey:@"end"]
                                                              withOptions:@"recommendedBands"
                           ]
                          mutableCopy];
    
}

- (IBAction)dayToAttendSegmentedControlPressed:(UISegmentedControl *)sender
{
    self.currentDayShown = @(self.daysSegmentedControl.selectedSegmentIndex);
    
    [self updateTableViewForDay:[self.daysToAttend objectAtIndex:self.daysSegmentedControl.selectedSegmentIndex]];
    
    [self reloadScheduleTableDataWithAnimation: 0];
    
    [self.scheduleTableView setContentOffset:CGPointMake(0.0, -10.0) animated:YES]; // scroll to the top
    
}

- (void) reloadScheduleTableDataWithAnimation: (UITableViewRowAnimation) animation
{
    if(animation == 0){
        [self.scheduleTableView reloadData];
    }
    else{
        [self.scheduleTableView beginUpdates];
        [self.scheduleTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];
        [self.scheduleTableView endUpdates];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.bandsToAttend count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Concert Cell" forIndexPath:indexPath];
    
    if([self.bandsToAttend count] > 0){
        
        // reference to the EbcEnhancedView
        EbcEnhancedView *bandConcertView = (EbcEnhancedView *)[cell.contentView viewWithTag:100];
        bandConcertView.roundedRects = YES;
        bandConcertView.cornerRadius = @(10.0);
        [bandConcertView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
        
        // set text to show in row
        bandConcertView.centeredText = [self attributedStringForRow:indexPath.row];
        
        // set 'heart' text in must bands
        /*
         Band* band = [self.festival.bands objectForKey:[self.bandsToAttend objectAtIndex:indexPath.row]];
         if([self.festival.mustBands objectForKey:band.lowercaseName]){
         NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
         paragraphStyle.alignment = NSTextAlignmentRight;
         NSDictionary* attributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue" size:16.0],
         NSForegroundColorAttributeName : [UIColor colorWithRed:140.0/255 green:180.0/255 blue:15.0/255 alpha:1.0],
         NSParagraphStyleAttributeName : paragraphStyle};
         bandConcertView.rightJustifiedText = [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"♡"]
         attributes:attributes
         ];
         }
         else{
         bandConcertView.rightJustifiedText = [[NSAttributedString alloc] initWithString:@""];
         }
         */
        
    }
    
    return cell;
}

- (NSAttributedString *)attributedStringForRow:(NSUInteger) row
{
    
    NSMutableAttributedString* bandConcertText = [[NSMutableAttributedString alloc] init];
    
    // date formatter for the concert hours
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"HH:mm";
    
    // band playing at the concert at row
    Band* band = [self.festival.bands objectForKey:[self.bandsToAttend objectAtIndex:row]];
    
    // create and set the attributed text to show
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    // set color and character of must bands of band string
    UIColor* bandColorDependingOnMust;
    if([self.festival.mustBands objectForKey:band.lowercaseName]){
        bandColorDependingOnMust = [UIColor colorWithRed:140.0/255 green:180.0/255 blue:15.0/255 alpha:1.0];
    }
    else{
        bandColorDependingOnMust = [UIColor darkGrayColor];
    }
    
    // create string for band name
    CGFloat fontSizeBandName;
    if(band.uppercaseName.length <= 20){
        fontSizeBandName = 18;
    }
    else if(band.uppercaseName.length <= 26){
        fontSizeBandName = 16;
    }
    else{
        fontSizeBandName = 14;
    }
    NSDictionary* attributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSizeBandName],
                                 NSForegroundColorAttributeName : bandColorDependingOnMust,
                                 NSParagraphStyleAttributeName : paragraphStyle};
    [bandConcertText appendAttributedString: [[NSAttributedString alloc] initWithString:[band.uppercaseName stringByAppendingString:@"\n"]
                                                                             attributes:attributes]
     ];
    
    // create string for hour
    attributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
                   NSForegroundColorAttributeName : [UIColor darkGrayColor],
                   NSParagraphStyleAttributeName : paragraphStyle};
    [bandConcertText appendAttributedString: [[NSAttributedString alloc] initWithString:[[NSString alloc] initWithFormat:@"%@-%@\n",
                                                                                         [dateFormatter stringFromDate:band.startTime],
                                                                                         [dateFormatter stringFromDate:band.endTime]
                                                                                         ]
                                                                             attributes:attributes]
     ];
    
    // create string for stage
    attributes = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
                   NSForegroundColorAttributeName : [UIColor darkGrayColor],
                   NSParagraphStyleAttributeName : paragraphStyle};
    [bandConcertText appendAttributedString: [[NSAttributedString alloc] initWithString:band.stage
                                                                             attributes:attributes]
     ];
    
    return bandConcertText;
    
}


#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Band* band = [self.festival.bands objectForKey:[self.bandsToAttend objectAtIndex:indexPath.row]];
    
    NSTimeInterval durationInMinutes = [band.endTime timeIntervalSinceDate:band.startTime]/60;
    durationInMinutes = durationInMinutes < 45 ? 45 : durationInMinutes; // at least 45-minutes-high for enough space to show all info
    
    return (CGFloat)durationInMinutes*1.5; // 1.5 points per minute
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Band* band = [self.festival.bands objectForKey:[self.bandsToAttend objectAtIndex:indexPath.row]];
    //if(band.infoText && ![band.infoText isEqualToString:@""]){
    [self performSegueWithIdentifier:@"ShowBandInfo" sender:self];
    //}
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
        self.scheduleTableView.userInteractionEnabled = YES;
        self.daysSegmentedControl.userInteractionEnabled = YES;
        self.overlayView.hidden = YES;
        
    } else {
        self.scheduleTableView.userInteractionEnabled = NO;
        self.daysSegmentedControl.userInteractionEnabled = NO;
        self.overlayView.hidden = NO;
    }
}

@end
