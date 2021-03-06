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
#import "NowPlayingVC.h"

@interface FestivalScheduleVC () <SWRevealViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *daysSegmentedControl;

@property (weak, nonatomic) IBOutlet UITableView *scheduleTableView;

@property (weak, nonatomic) IBOutlet UITextView *emptyScheduleTextView;

@property (strong, nonatomic) FestivalSchedule* schedule;
@property (strong, nonatomic) NSMutableArray* bandsToAttend;

@property (strong, nonatomic) NSMutableArray* daysToAttend; // of dictionaries {"day":"dd/mm/yyyy","start":NSDate,"end":NSDate}
@property (strong, nonatomic) NSNumber* currentDayShown; // as the index of the segmentel control

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sharingButton;
@property (weak, nonatomic) IBOutlet UIButton *nowPlayingButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (assign) BOOL markedToUpdateReminders;

@end

@implementation FestivalScheduleVC

#pragma mark - Initialization


- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // set navigation bar title
    self.title = @"Schedule";
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

    self.festival.recomputeSchedule = YES; // mark to perform initial schedule computations
    
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
        
        // hide textView for the case of no mustBands
        self.emptyScheduleTextView.hidden = YES;
        
        // unhide table view and segmented control
        self.scheduleTableView.hidden = NO;
        self.daysSegmentedControl.hidden = NO;
        self.settingsButton.hidden = NO;
        self.nowPlayingButton.hidden = NO;
        
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
        self.settingsButton.hidden = YES;
        self.nowPlayingButton.hidden = YES;
        
        // show text
        self.emptyScheduleTextView.hidden = NO;
        
        // clear bandsToAttend
        [self.bandsToAttend removeAllObjects];
        
        // hide 'Groups' button in the nav bar
        self.navigationItem.rightBarButtonItem = nil;
        
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
    if(self.festival.recomputeSchedule){
        
        [self.festival updateBandSimilarityModel];
        
        [self.schedule computeSchedule];
        
        if(self.festival.updateReminders){
            [self updateAllConcertReminders];
            self.festival.updateReminders = NO;
        }
        
        // get the days to attend and update segmented control (only if days have changed)
        NSArray* days = [self.schedule daysToAttendWithOptions:@"recommendedBands"];
        if([self.daysToAttend count] != [days count]){
            self.daysToAttend = [days mutableCopy];
            [self setupDaysSegmentedControlForDays: self.daysToAttend];
        }
        
        // get the bands to attend
        [self updateTableViewForDay:[self.daysToAttend objectAtIndex:[self.currentDayShown integerValue]]];
        
        self.festival.recomputeSchedule = NO;

    }
    
}


#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Schedule_Shown" withParameters:@{@"userID":self.userID,@"festival":[self.festival lowercaseName]}];
}
-(void)logScheduleAlgorithmInFlurry:(NSString*) algorithmMode
{
    [Flurry logEvent:@"Schedule_Algorithm" withParameters:@{@"userID":self.userID,@"festival":[self.festival lowercaseName],@"algorithm":algorithmMode}];
}
-(void)logRemindersInFlurry:(NSString*) reminderTime
{
    [Flurry logEvent:@"Schedule_Reminders" withParameters:@{@"userID":self.userID,@"festival":[self.festival lowercaseName],@"reminders":reminderTime}];
}
-(void)logScheduleSharingInFlurry
{
    [Flurry logEvent:@"Schedule_Sharing" withParameters:@{@"userID":self.userID,@"festival":[self.festival lowercaseName]}];
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
    else if ([segue.identifier isEqualToString:@"ShowNowPlaying"]) {
        
        if ([segue.destinationViewController isKindOfClass:[NowPlayingVC class]]) {
            
            // set title of 'back' button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

            // Configure destination VC
            NowPlayingVC *npvc = segue.destinationViewController;
            if ([npvc isKindOfClass:[NowPlayingVC class]]) {
                npvc.title = @"Now Playing";
                npvc.festival = self.festival;
                npvc.userID = self.userID;
            }
            
        }
    }
}


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
    
    // now date creation
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"dd/MM/yyyy HH:mm";
    NSDate* now = [NSDate date]; // [dateFormatter dateFromString:@"29/05/2015 20:05"];
    
    if(originalNumberOfSegments != self.daysSegmentedControl.numberOfSegments){
        if( ([self.festival.start compare:now] == NSOrderedAscending) && ([now compare:self.festival.end] == NSOrderedAscending) ){
            // if date is during the festival, select the right day

            NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
            dayFormatter.dateFormat=@"dd";
            NSString* dayNumber = [dayFormatter stringFromDate:now];
            
            NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
            hourFormatter.dateFormat=@"HH";
            NSInteger hour = [[hourFormatter stringFromDate: now] integerValue];
            if(hour < 9){
                dayNumber = @([dayNumber integerValue] - 1).stringValue;
            }

            for(NSInteger index=0 ; index<self.daysSegmentedControl.numberOfSegments ; index++){
                if( [[self.daysSegmentedControl titleForSegmentAtIndex:index] isEqualToString:dayNumber] ){
                    self.currentDayShown = @(index);
                }
            }
        }
        else{
            self.currentDayShown = 0;
        }
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


#pragma mark - Selecting Algorithm
- (IBAction)settingsPressed:(UIButton *)sender
{
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController.view setTintColor:[UIColor grayColor]];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action){}
                                   ];
    UIAlertAction *algorithm  = [UIAlertAction actionWithTitle:@"Edit schedule mode" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action)
                                 {
                                     [self showAlgorithmActionSheet];
                                 }
                                 ];
    UIAlertAction *notifications = [UIAlertAction actionWithTitle:@"Edit reminders" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action)
                                    {
                                        [self showRemindersActionSheet];
                                    }
                                    ];
    [alertController addAction:algorithm];
    [alertController addAction:notifications];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) showRemindersActionSheet
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *reminderTime = [defaults objectForKey:@"reminderBeforeConcert"];
    if(!reminderTime){
        reminderTime = @"None"; // Minutes before concert
        [defaults setObject:reminderTime forKey:@"reminderBeforeConcert"];
        [defaults synchronize];
    }
    NSString* minutesString;
    if([reminderTime isEqualToString:@"None"]){
        minutesString = @"None";
    }
    else{
        minutesString = [NSString stringWithFormat:@"%@ minutes",reminderTime];
    }
    
    [self logRemindersInFlurry:@""];
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Reminders before a concert starts"
                                          message:[NSString stringWithFormat:@"Currently set to '%@'",minutesString]
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController.view setTintColor:[UIColor grayColor]];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action){
                                   }
                                   ];
    UIAlertAction *fiveMinutes = [UIAlertAction
                                  actionWithTitle:@"5 minutes"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action)
                                  {
                                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                      [defaults setObject:@"5" forKey:@"reminderBeforeConcert"];
                                      [defaults synchronize];
                                      [self updateAllConcertReminders];
                                      [self logRemindersInFlurry:@"5"];
                                  }
                                  ];
    UIAlertAction *tenMinutes = [UIAlertAction
                                 actionWithTitle:@"10 minutes"
                                 style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action)
                                 {
                                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                     [defaults setObject:@"10" forKey:@"reminderBeforeConcert"];
                                     [defaults synchronize];
                                     [self updateAllConcertReminders];
                                     [self logRemindersInFlurry:@"10"];
                                 }
                                 ];
    UIAlertAction *fifteenMinutes = [UIAlertAction
                                     actionWithTitle:@"15 minutes"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action)
                                     {
                                         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                         [defaults setObject:@"15" forKey:@"reminderBeforeConcert"];
                                         [defaults synchronize];
                                         [self updateAllConcertReminders];
                                         [self logRemindersInFlurry:@"15"];
                                     }
                                     ];
    UIAlertAction *noReminders = [UIAlertAction
                                  actionWithTitle:@"None"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action)
                                  {
                                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                      [defaults setObject:@"None" forKey:@"reminderBeforeConcert"];
                                      [defaults synchronize];
                                      [self updateAllConcertReminders];
                                      [self logRemindersInFlurry:@"None"];
                                  }
                                  ];
    [alertController addAction:cancelAction];
    [alertController addAction:fiveMinutes];
    [alertController addAction:tenMinutes];
    [alertController addAction:fifteenMinutes];
    [alertController addAction:noReminders];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(void) updateAllConcertReminders
{
    
    //[[[UIApplication sharedApplication] scheduledLocalNotifications] enumerateObjectsUsingBlock:^(UILocalNotification *notification, NSUInteger idx, BOOL *stop) { NSLog(@"Notification %lu: %@ %@",(unsigned long)idx, notification.fireDate, notification.alertBody); }];
    
    // clear all notifications because the schdedule has changed
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // get the notification time from NSUSerDefaults
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *reminderTime = [defaults objectForKey:@"reminderBeforeConcert"];
    if(!reminderTime){
        reminderTime = @"None"; // Minutes before concert
        [defaults setObject:reminderTime forKey:@"reminderBeforeConcert"];
        [defaults synchronize];
    }
    
    // Add one notification per concert in the schedule
    if(![reminderTime isEqualToString:@"None"]){
        NSArray* bandsToAttend = [self.schedule bandsToAttendSortedByTimeBetween:self.festival.start
                                                                             and:self.festival.end
                                                                     withOptions:@"recommendedBands"
                                  ];
        for(NSString* bandName in bandsToAttend){
            Band* band = [self.festival.bands objectForKey:bandName];
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertBody = [NSString stringWithFormat:@"%@ will start playing at %@ stage in %@ minutes",band.uppercaseName,band.stage,reminderTime];
            notification.fireDate = [band.startTime dateByAddingTimeInterval:-60*([reminderTime integerValue])]; // notificationTime minutes before the concert starts
            //NSLog(@"notification.fireDate: %@",notification.fireDate);
            //NSLog(@"[NSDate date]: %@",[NSDate date]);
            //NSLog(@"condition: %d",[notification.fireDate compare:[NSDate date]] != NSOrderedAscending);
            if([notification.fireDate compare:[NSDate date]] != NSOrderedAscending){
                // only add the notification if it is set in the future
                [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            }
        }
    }
    
    //[[[UIApplication sharedApplication] scheduledLocalNotifications] enumerateObjectsUsingBlock:^(UILocalNotification *notification, NSUInteger idx, BOOL *stop) { NSLog(@"Notification %lu: %@ %@",(unsigned long)idx, notification.fireDate, notification.alertBody); }];

}

-(void) showAlgorithmActionSheet
{
    //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    NSString *algorithmMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"scheduleAlgorithmMode"];
    NSString *currentModeString = @"";
    if([algorithmMode isEqualToString:@"FullConcertWithFreeTime"]){
        currentModeString = @"Your current mode is 'Relaxed'";
    }
    else if([algorithmMode isEqualToString:@"FullConcert"]){
        currentModeString = @"Your current mode is 'Moderate'";
    }
    else if([algorithmMode isEqualToString:@"LastHalfHour"]){
        currentModeString = @"Your current mode is 'Complete'";
    }
    
    [self logScheduleAlgorithmInFlurry:@""];
    
    NSString* message = [NSString stringWithFormat:@"RELAXED:\nWith free time between concerts.\n\n"
                                                    "MODERATE:\nAs many concerts as possible,\n but without overlapping.\n\n"
                                                    "COMPLETE:\nSmart overlapping optimized for enjoying as many concert endings as possible.\n"
                                                    "\n%@",currentModeString];
    
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Select your type of festival experience"
                                          message:message
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController.view setTintColor:[UIColor grayColor]];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action){}
                                   ];
    UIAlertAction *freeTime     = [UIAlertAction actionWithTitle:@"Relaxed" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
                                   {
                                       //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
                                       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                       [defaults setObject:@"FullConcertWithFreeTime" forKey:@"scheduleAlgorithmMode"];
                                       [defaults synchronize];
                                       if(![algorithmMode isEqualToString:@"FullConcertWithFreeTime"]){
                                           self.festival.recomputeSchedule = YES;
                                           self.festival.updateReminders = YES;
                                           [self updateSchedule];
                                           [self reloadScheduleTableDataWithAnimation: 0];
                                           [self logScheduleAlgorithmInFlurry:@"Relaxed"];
                                       }
                                   }
                                   ];
    UIAlertAction *fullConcert  = [UIAlertAction actionWithTitle:@"Moderate" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action)
                                   {
                                       //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
                                       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                       [defaults setObject:@"FullConcert" forKey:@"scheduleAlgorithmMode"];
                                       [defaults synchronize];
                                       if(![algorithmMode isEqualToString:@"FullConcert"]){
                                           self.festival.recomputeSchedule = YES;
                                           self.festival.updateReminders = YES;
                                           [self updateSchedule];
                                           [self reloadScheduleTableDataWithAnimation: 0];
                                           [self logScheduleAlgorithmInFlurry:@"Moderate"];
                                       }
                                   }
                                   ];
    UIAlertAction *last30min    = [UIAlertAction actionWithTitle:@"Complete" style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       //NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
                                       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                       [defaults setObject:@"LastHalfHour" forKey:@"scheduleAlgorithmMode"];
                                       [defaults synchronize];
                                       if(![algorithmMode isEqualToString:@"LastHalfHour"]){
                                           self.festival.recomputeSchedule = YES;
                                           self.festival.updateReminders = YES;
                                           [self updateSchedule];
                                           [self reloadScheduleTableDataWithAnimation: 0];
                                           [self logScheduleAlgorithmInFlurry:@"Complete"];
                                       }
                                   }
                                   ];
    [alertController addAction:cancelAction];
    [alertController addAction:freeTime];
    [alertController addAction:fullConcert];
    [alertController addAction:last30min];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Sharing
- (void) showNowPlaying
{
    [self performSegueWithIdentifier:@"ShowNowPlaying" sender:self];
}

- (IBAction)sharingPressed:(UIBarButtonItem *)sender
{
    [self shareSchedule];
}

- (void) shareSchedule
{
    [self logScheduleSharingInFlurry];

    NSString *textToShare = [NSString stringWithFormat:@"My schedule for #%@. Get yours with @festook!",self.festival.hashtagOfficial];
    
    UIImage *imageToShare = [self generateScheduleImage];

    /*
     UIImageView *imageView = [[UIImageView alloc] initWithImage:imageToShare];
    imageView.frame = CGRectMake(10, 110, 300, 450);
    [self.view addSubview:imageView];
    */
    
    NSArray *objectsToShare = @[textToShare, imageToShare];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    [activityVC.view setTintColor:[UIColor grayColor]];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePostToWeibo,
                                         UIActivityTypePrint,
                                         UIActivityTypeAssignToContact,
                                         UIActivityTypeAddToReadingList,
                                         UIActivityTypePostToFlickr,
                                         UIActivityTypePostToVimeo,
                                         UIActivityTypePostToTencentWeibo,
                                         UIActivityTypeAirDrop]; //UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeMail, UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard, UIActivityTypeMessage
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

#define TopBarHeight    50.0
#define DayHeaderHeight 15.0
#define ConcertHeight   25.0
#define ConcertWidth    100.0
#define CommonMargin    2.0
#define BottomBarHeight 50.0
-(UIImage*) generateScheduleImage
{
    // text attributes
    NSMutableParagraphStyle *centeredStyle = [[NSMutableParagraphStyle alloc] init];
    centeredStyle.alignment = NSTextAlignmentCenter;
    NSMutableParagraphStyle *rightStyle = [[NSMutableParagraphStyle alloc] init];
    rightStyle.alignment = NSTextAlignmentRight;
    NSMutableParagraphStyle *leftStyle = [[NSMutableParagraphStyle alloc] init];
    leftStyle.alignment = NSTextAlignmentLeft;
    NSDictionary* textAttributesTopBar =    @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:15],
                                              NSForegroundColorAttributeName : [UIColor whiteColor],
                                              NSParagraphStyleAttributeName : centeredStyle};
    NSDictionary* textAttributesDayHeader = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:9],
                                              NSForegroundColorAttributeName : [UIColor whiteColor],
                                              NSParagraphStyleAttributeName : centeredStyle};
    NSDictionary* textAttributesConcerts =  @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:8],
                                              NSForegroundColorAttributeName : [UIColor darkGrayColor],
                                              NSParagraphStyleAttributeName : centeredStyle};
    NSDictionary* textAttributesSocial  =   @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:7],
                                              NSForegroundColorAttributeName : [UIColor darkGrayColor],
                                              NSParagraphStyleAttributeName : rightStyle};
    NSDictionary* textAttributesLogoName =  @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Thin" size:13],
                                              NSForegroundColorAttributeName : [UIColor darkGrayColor],
                                              NSParagraphStyleAttributeName : leftStyle};



    // look for longest day
    NSUInteger maxConcertsPerDay = 0;
    for(NSDictionary* day in self.daysToAttend){
        NSUInteger concertsInDay = [[self.schedule bandsToAttendSortedByTimeBetween:[day objectForKey:@"start"] and:[day objectForKey:@"end"] withOptions:@"recommendedBands"] count];
        if(maxConcertsPerDay<concertsInDay){
            maxConcertsPerDay = concertsInDay;
        }
    }
    
    // set total image widht&height
    CGFloat imageWidth  = CommonMargin + ((CGFloat)[self.daysToAttend count])*(ConcertWidth+CommonMargin);
    CGFloat imageHeight = TopBarHeight + CommonMargin + DayHeaderHeight + CommonMargin + ((CGFloat)maxConcertsPerDay)*(ConcertHeight+CommonMargin) + BottomBarHeight;
    
    // begin context to draw the views
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageWidth,imageHeight), NO, 0.0);

    // background gradient
    EbcEnhancedView* backgoundView = [[EbcEnhancedView alloc] init];
    backgoundView.roundedRects = NO;
    [backgoundView setBackgroundGradientFromColor:self.festival.colorA toColor:self.festival.colorB];
    backgoundView.bounds = CGRectMake(0.0, 0.0, imageWidth, imageHeight);
    [backgoundView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    // draw top bar
    EbcEnhancedView* topBarView = [[EbcEnhancedView alloc] init];
    topBarView.bounds = CGRectMake(TopBarHeight*0.15, TopBarHeight*0.15, imageWidth-TopBarHeight*0.3, TopBarHeight-TopBarHeight*0.3);
    topBarView.roundedRects = YES;
    topBarView.cornerRadius = @(6.0);
    [topBarView setBackgroundColor:[UIColor clearColor]];
    [topBarView setBackgroundPlain:[UIColor clearColor] withAlpha:@(1.0)];
    [topBarView setBorderWithColor:self.festival.colorB andWidth:1.0f];
    topBarView.centeredText = [[NSAttributedString alloc] initWithString:self.festival.uppercaseName attributes:textAttributesTopBar];
    [topBarView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    // draw concerts for each day
    for(NSDictionary* day in self.daysToAttend){
        CGFloat horizontalOffset = CommonMargin+(ConcertWidth+CommonMargin)*(CGFloat)[self.daysToAttend indexOfObject:day];
        
        // draw day header
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat=@"EEEE dd";
        EbcEnhancedView* dayHeaderView = [[EbcEnhancedView alloc] init];
        dayHeaderView.bounds = CGRectMake(horizontalOffset, TopBarHeight+CommonMargin, ConcertWidth, DayHeaderHeight);
        [dayHeaderView setBackgroundColor:[UIColor clearColor]];
        [dayHeaderView setBackgroundPlain:[UIColor clearColor] withAlpha:@(1.0)];
        dayHeaderView.centeredText = [[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:[day objectForKey:@"start"]] attributes:textAttributesDayHeader];
        [dayHeaderView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        // draw concerts for 'day' in the right column
        NSArray* bandsToAttendInThisDay = [self.schedule bandsToAttendSortedByTimeBetween:[day objectForKey:@"start"] and:[day objectForKey:@"end"] withOptions:@"recommendedBands"];
        for(NSString* bandName in bandsToAttendInThisDay){
            CGFloat verticalOffset = TopBarHeight + CommonMargin + DayHeaderHeight + CommonMargin+((CGFloat)[bandsToAttendInThisDay indexOfObject:bandName])*(ConcertHeight+CommonMargin);
            
            EbcEnhancedView* bandConcertView = [[EbcEnhancedView alloc] init];
            bandConcertView.bounds = CGRectMake(horizontalOffset, verticalOffset, ConcertWidth, ConcertHeight);
            bandConcertView.roundedRects = YES;
            bandConcertView.cornerRadius = @(5.0);
            [bandConcertView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
            bandConcertView.centeredText = [[NSAttributedString alloc] initWithString:((Band*)[self.festival.bands objectForKey:bandName]).uppercaseName attributes:textAttributesConcerts];
            [bandConcertView.layer renderInContext:UIGraphicsGetCurrentContext()];
            
        }
    }
    
    // draw bottom bar social text
    EbcEnhancedView* bottomBarView = [[EbcEnhancedView alloc] init];
    bottomBarView.bounds = CGRectMake(BottomBarHeight*0.15,
                                      imageHeight-BottomBarHeight+BottomBarHeight*0.15,
                                      imageWidth-BottomBarHeight*0.3,
                                      BottomBarHeight-BottomBarHeight*0.3);
    bottomBarView.roundedRects = YES;
    bottomBarView.cornerRadius = @(6.0);
    [bottomBarView setBackgroundColor:[UIColor clearColor]];
    [bottomBarView setBackgroundPlain:[UIColor clearColor] withAlpha:@(1.0)];
    [bottomBarView setBorderWithColor:self.festival.colorA andWidth:1.0f];
    bottomBarView.rightJustifiedText = [[NSAttributedString alloc] initWithString:@"www.festook.com\ntwitter.com/festook\nfacebook.com/festook" attributes:textAttributesSocial];
    [bottomBarView.layer renderInContext:UIGraphicsGetCurrentContext()];

    // draw bottom festook logo
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"roundedLogo"]];
    logoView.bounds = CGRectMake(BottomBarHeight*0.20,
                                 imageHeight-BottomBarHeight+BottomBarHeight*0.20,
                                 BottomBarHeight-BottomBarHeight*0.4,
                                 BottomBarHeight-BottomBarHeight*0.4);
    [logoView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    // draw bottom festook name
    EbcEnhancedView* nameView = [[EbcEnhancedView alloc] init];
    nameView.bounds = CGRectMake(BottomBarHeight*0.20 + BottomBarHeight-BottomBarHeight*0.4,
                                 imageHeight-BottomBarHeight,
                                 200,
                                 BottomBarHeight);
    [nameView setBackgroundColor:[UIColor clearColor]];
    [nameView setBackgroundPlain:[UIColor clearColor] withAlpha:@(1.0)];
    nameView.leftJustifiedText = [[NSAttributedString alloc] initWithString:@"festook" attributes:textAttributesLogoName];
    [nameView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    // get final image
    UIImage *scheduleImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // end context
    UIGraphicsEndImageContext();

    return scheduleImage;
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
        self.settingsButton.userInteractionEnabled = YES;
        self.nowPlayingButton.userInteractionEnabled = YES;
        self.overlayView.hidden = YES;
        
    } else {
        self.scheduleTableView.userInteractionEnabled = NO;
        self.daysSegmentedControl.userInteractionEnabled = NO;
        self.settingsButton.userInteractionEnabled = NO;
        self.nowPlayingButton.userInteractionEnabled = NO;
        self.overlayView.hidden = NO;
    }
}

@end
