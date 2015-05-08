//
//  FestivalLineupVC.m
//  Festook
//
//  Created by Eduard Bonada Cruells on 14/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "FestivalLineupVC.h"

#import "SWRevealViewController.h"
#import "FestivalRevealVC.h"

#import "Flurry.h"

#import "EbcEnhancedView.h"
#import "Band.h"
#import "FestivalSchedule.h"
#import "BandCollectionViewCell.h"
#import "BandsInSectionsCollectionHeaderView.h"
#import "BandSimilarityCalculator.h"
#import "BandInfoVC.h"

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

@interface FestivalLineupVC () <SWRevealViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *bandsCollectionView;
@property (strong, nonatomic) NSArray *bandsAsInCollectionView; // of @"lowercaseName"
@property (nonatomic) BOOL updateBandsCollectionDataOnScrollingEnded;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (weak, nonatomic) IBOutlet UISegmentedControl *sortCollectionControl;
@property (nonatomic, strong) NSNumber* sortSegmentedControlSelected;

@property (nonatomic, strong) NSMutableArray* itemsAtSection;

@property (strong, nonatomic) UIBarButtonItem* helpButtonNavigationBar;
@property (weak, nonatomic) IBOutlet UITextView *noMustBandsText;

@property (nonatomic, strong) Band* bandJustPressed;

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@end

@implementation FestivalLineupVC


#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set navigation bar title
    self.title = @"Line-up";
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
        
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    [self setup];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.sortSegmentedControlSelected = @(self.sortCollectionControl.selectedSegmentIndex);
}

-(void) setup
{
    if(self.festival){
        
        [self updateBandSimilarityModel];
        
        // set background image
        self.backgroundView.roundedRects = NO;
        [self.backgroundView setBackgroundGradientFromColor:self.festival.colorA toColor:self.festival.colorB];
        
        // configure day segmented control
        [self.sortCollectionControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:16.0]}
                                                  forState:UIControlStateNormal];
        
        // setting sorting to show
        if(!self.sortSegmentedControlSelected){
            if([self.festival.mustBands count] > 0){
                self.sortCollectionControl.selectedSegmentIndex = 1;
            }
            else{
                self.sortCollectionControl.selectedSegmentIndex = 0;
            }
        }
        else{
            self.sortCollectionControl.selectedSegmentIndex = [self.sortSegmentedControlSelected integerValue];
            self.sortSegmentedControlSelected = nil;
        }
        [self applyChangeInSortingOfCollectionWithScrollToTop:FALSE];
        
        // clear helper array itemsInSection
        self.itemsAtSection = [[NSMutableArray alloc] init];
        
    }
    
    // set self as revealVC delegate
    self.revealViewController.delegate = self;
    
    // compute size of collection view cells
    CGFloat cellsPerRow = 3.0;
    CGFloat leftRightMargin = 20.0;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.bandsCollectionView.collectionViewLayout;
    CGFloat availableWidthForCells = (self.view.frame.size.width-2*leftRightMargin) - flowLayout.sectionInset.left - flowLayout.sectionInset.right - flowLayout.minimumInteritemSpacing * (cellsPerRow - 1);
    CGFloat cellWidth = availableWidthForCells / cellsPerRow;
    /*NSLog(@"self.festivalsCollectionView.frame: %@", NSStringFromCGRect(self.bandsCollectionView.frame));
    NSLog(@"self.view.frame: %@", NSStringFromCGRect(self.view.frame));
    NSLog(@"flowLayout.sectionInset.left: %f",flowLayout.sectionInset.left);
    NSLog(@"flowLayout.sectionInset.right: %f",flowLayout.sectionInset.left);
    NSLog(@"flowLayout.minimumInteritemSpacing: %f",flowLayout.minimumInteritemSpacing);
    NSLog(@"availableWidthForCells: %f",availableWidthForCells);
    NSLog(@"cellWidth: %f",cellWidth);*/
    flowLayout.itemSize = CGSizeMake(cellWidth, cellWidth*0.80); //flowLayout.itemSize.height);
    
    // hide the overlay view
    if(self.revealViewController.frontViewPosition != FrontViewPositionLeft){
        self.overlayView.hidden = NO;
    }
    else{
        self.overlayView.hidden = YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

    if ([segue.identifier isEqualToString:@"ShowBandInfo"]) {
        if ([segue.destinationViewController isKindOfClass:[BandInfoVC class]]) {
            
            NSIndexPath *indexPath = [self.bandsCollectionView indexPathForItemAtPoint:[sender locationInView:self.bandsCollectionView]];
            
            // compute the itemIndex matching the sections
            NSUInteger itemIndex = 0;
            for(NSUInteger section = 0 ; section < indexPath.section ; section++){
                itemIndex += [self.itemsAtSection[section] integerValue];
            }
            itemIndex += indexPath.item;
            
            BandInfoVC *bivc = segue.destinationViewController;
            bivc.band = [self.festival.bands objectForKey:self.bandsAsInCollectionView[itemIndex]];
            
            //bivc.title = bivc.band.festival.uppercaseName;
            
            // set title of 'back' button
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Line-up" style:UIBarButtonItemStylePlain target:nil action:nil];
            [self.navigationItem.backBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0],NSForegroundColorAttributeName:[UIColor darkGrayColor]}
                                                                 forState:UIControlStateNormal
             ];
            
            bivc.userID = self.userID;
            
        }
    }

}


#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Lineup_Shown" withParameters:@{@"userID":self.userID,@"festival":[self.festival lowercaseName],@"sortingOption":@(self.sortCollectionControl.selectedSegmentIndex)}];
}


#pragma mark - Management of model data

-(void) updateBandSimilarityModel
{
    
    [self.festival updateBandSimilarityModel];
    
    // sort the bands in the collection view
    if(self.sortCollectionControl.selectedSegmentIndex == 0){
        // sort bands alphabetically
        self.bandsAsInCollectionView = [Band sortBandsIn:self.festival.bands by:@"alphabetically"];
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 1){
        //  sort the bands by increasing bandSimilarityToMustBands
        self.bandsAsInCollectionView = [Band sortBandsIn:self.festival.bands by:@"bandSimilarity"];
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 2){
        //  sort the bands by startTime
        self.bandsAsInCollectionView = [Band sortBandsIn:self.festival.bands by:@"startTime"];
    }
    
    // reload collection view data
    [self reloadBandCollectionViewData];
    
}


#pragma mark - Collection View Data Source and Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSInteger numberSections = 0;
    
    if(self.sortCollectionControl.selectedSegmentIndex == 0){
        // abc
        numberSections = [[self.festival.schedule initialLettersOFBands] count];
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 1){
        // recommended
        numberSections = 1;
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 2){
        // day
        numberSections = [[self.festival.schedule daysToAttendWithOptions:@"allBands"] count];
    }
    
    return numberSections;
}

- (NSInteger)collectionView:(UICollectionView *)cv
     numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItemsInSection = 0;
    
    if(self.sortCollectionControl.selectedSegmentIndex == 0){
        // abc
        NSArray* initials = [self.festival.schedule initialLettersOFBands];
        NSArray* bandsWithInitial = [self.festival.schedule bandsWithInitial:[initials objectAtIndex:section]];
        [self.itemsAtSection setObject:@([bandsWithInitial count]) atIndexedSubscript:section];
        numberOfItemsInSection = [bandsWithInitial count];
        
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 1){
        // recommended
        [self.itemsAtSection setObject:@(self.bandsAsInCollectionView.count) atIndexedSubscript:section];
        numberOfItemsInSection = [self.bandsAsInCollectionView count];
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 2){
        // day
        NSDictionary* day = [[self.festival.schedule daysToAttendWithOptions:@"allBands"] objectAtIndex:section];
        NSArray* bandsAtDay = [self.festival.schedule bandsToAttendSortedByTimeBetween:[day objectForKey:@"start"]
                                                                                   and:[day objectForKey:@"end"]
                                                                           withOptions:@"allBands"];
        
        [self.itemsAtSection setObject:@(bandsAtDay.count) atIndexedSubscript:section];
        
        numberOfItemsInSection = bandsAtDay.count;
    }
    
    return numberOfItemsInSection;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    if(self.sortCollectionControl.selectedSegmentIndex == 0){
        // abc
        return CGSizeMake(30.0,30.0);
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 1){
        // recommended
        return CGSizeMake(0.0,0.0);
    }
    else if(self.sortCollectionControl.selectedSegmentIndex == 2){
        // day
        return CGSizeMake(30.0,30.0);
    }
    else{
        return CGSizeMake(0.0,0.0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        
        if(self.sortCollectionControl.selectedSegmentIndex == 0){
            // abc
            
            BandsInSectionsCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                             withReuseIdentifier:@"BandsInSectionsHeader"
                                                                                                    forIndexPath:indexPath];
            NSArray* initials = [self.festival.schedule initialLettersOFBands];

            headerView.headerText.text = [[initials objectAtIndex:indexPath.section] uppercaseString];
            
            reusableview = headerView;
            
        }
        else if(self.sortCollectionControl.selectedSegmentIndex == 1){
            // recommended

            BandsInSectionsCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                             withReuseIdentifier:@"BandsInSectionsHeader"
                                                                                                    forIndexPath:indexPath];
            reusableview = headerView;

        }
        else if(self.sortCollectionControl.selectedSegmentIndex == 2){
            // day
            
            BandsInSectionsCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                             withReuseIdentifier:@"BandsInSectionsHeader"
                                                                                                    forIndexPath:indexPath];
            
            // date formatters
            NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
            dayFormatter.dateFormat=@"dd";
            
            // compute values
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            [gregorian setFirstWeekday:2];
            NSDictionary* day = [[self.festival.schedule daysToAttendWithOptions:@"allBands"] objectAtIndex:indexPath.section];
            NSUInteger weekdayNumber = [gregorian ordinalityOfUnit:NSCalendarUnitWeekday
                                                            inUnit:NSCalendarUnitWeekOfYear
                                                           forDate:[day objectForKey:@"start"]];
            NSArray *daysOfWeek = @[@"",@"Monday",@"Tuesday",@"Wednesday",@"Thursday",@"Friday",@"Saturday",@"Sunday"];
            
            // set header text
            headerView.headerText.text = [[NSString alloc] initWithFormat:@"%@ %@",
                                          [daysOfWeek objectAtIndex:weekdayNumber],
                                          [dayFormatter stringFromDate:[day objectForKey:@"start"]]
                                          ];
            
            reusableview = headerView;
            
        }
        
    }
    else if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"BandsInSectionsFooter" forIndexPath:indexPath];
        
        reusableview = footerview;
    }
    
    return reusableview;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    BandCollectionViewCell* cell = [cv dequeueReusableCellWithReuseIdentifier:@"BandCell" forIndexPath:indexPath];
    
    // compute the itemIndex matching the sections
    NSUInteger itemIndex = 0;
    for(NSUInteger section = 0 ; section < indexPath.section ; section++){
        itemIndex += [self.itemsAtSection[section] integerValue];
    }
    itemIndex += indexPath.item;
    Band* bandInCell = (Band*)([self.festival.bands objectForKey:self.bandsAsInCollectionView[itemIndex]]);
    
    // configure the bandView
    EbcEnhancedView* bandView = ((BandCollectionViewCell *) cell).bandView;
    if([bandView isKindOfClass:[EbcEnhancedView class]]){
        
        // set visual graphic configuration
        bandView.roundedRects = YES;
        bandView.cornerRadius = @(10);
        
        [bandView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(0.6)];
        
        // check for long words in the bandname
        NSNumber* longestWordLength = [[bandInCell.uppercaseName componentsSeparatedByString:@" "] valueForKeyPath:@"@max.length"];
        CGFloat fontSizeBandName;
        if(IS_IPHONE_6 || IS_IPHONE_6P){
            fontSizeBandName = [longestWordLength integerValue] > 12 ? 14 : 16;
        }
        else{
            fontSizeBandName = [longestWordLength integerValue] > 12 ? 11 : 13;
        }
        
        // set the {color, and font, and character for must bands} of the band text
        UIColor* colorDependingOnMustAndDiscard;
        UIFont* fontDependingOnMustAndDiscard;
        if([self.festival.mustBands objectForKey:bandInCell.lowercaseName]){
            // must band => greenish
            colorDependingOnMustAndDiscard = [UIColor colorWithRed:140.0/255 green:180.0/255 blue:15.0/255 alpha:1.0];
            fontDependingOnMustAndDiscard = [UIFont fontWithName:@"HelveticaNeue" size:fontSizeBandName];
        }
        else if([self.festival.discardedBands objectForKey:bandInCell.lowercaseName]){
            // discarded band => redish
            colorDependingOnMustAndDiscard = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.6];
            fontDependingOnMustAndDiscard = [UIFont fontWithName:@"HelveticaNeue" size:fontSizeBandName];
        }
        else{
            // default => grey
            colorDependingOnMustAndDiscard = [UIColor darkGrayColor];
            fontDependingOnMustAndDiscard = [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSizeBandName];
        }
        
        // set the NSAttributedString in the title
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSDictionary* attributesBandName = @{NSFontAttributeName : fontDependingOnMustAndDiscard,
                                             NSForegroundColorAttributeName : colorDependingOnMustAndDiscard,
                                             NSParagraphStyleAttributeName : paragraphStyle};
        //NSString* textForCell = [[NSString alloc]initWithFormat:@"%@\n%0.3f",bandInCell.uppercaseName,[bandInCell.bandSimilarityToMustBands doubleValue]];
        NSString* textForCell = [[NSString alloc]initWithFormat:@"%@",bandInCell.uppercaseName];
        bandView.centeredText = [[NSAttributedString alloc] initWithString:textForCell
                                                                attributes:attributesBandName];
        
    }
    
    return cell;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(20.0,20.0);
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
        self.bandsCollectionView.userInteractionEnabled = YES;
        self.sortCollectionControl.userInteractionEnabled = YES;
        self.overlayView.hidden = YES;
        
    } else {
        self.bandsCollectionView.userInteractionEnabled = NO;
        self.sortCollectionControl.userInteractionEnabled = NO;
        self.overlayView.hidden = NO;
    }
}

#pragma mark - Methods to solve the crash of mutating the collection while enumerating
// From http://stackoverflow.com/questions/19032869/uicollectionview-crash-on-unhighlightallitems

- (void)reloadBandCollectionViewData
{
    //if (self.bandsCollectionView.isTracking || self.bandsCollectionView.isDragging || self.bandsCollectionView.isDecelerating) {
    //    self.updateBandsCollectionDataOnScrollingEnded = YES;
    //} else {
    [self.bandsCollectionView reloadData];
    //}
}


#pragma mark - User Interface actions

- (IBAction)BandCellTapped:(UITapGestureRecognizer *)sender
{
    if(sender.state == UIGestureRecognizerStateEnded ){
        
        if(sender.view == self.bandsCollectionView){
            
            NSIndexPath *indexPath = [self.bandsCollectionView indexPathForItemAtPoint:[sender locationInView:self.bandsCollectionView]];
            
            if (indexPath == nil){
                // Long press in bandsCollectionView outside any cell
            }
            else{
                //Band *band = [self.festival.bands objectForKey:self.bandsAsInCollectionView[indexPath.item]];
                //if(band.infoText && ![band.infoText isEqualToString:@""]){
                [self performSegueWithIdentifier:@"ShowBandInfo" sender:sender];
                //}
            }
        }
        
    }
}

-(void) applyChangeInSortingOfCollectionWithScrollToTop:(BOOL)scrollToTop
{
    switch (self.sortCollectionControl.selectedSegmentIndex)
    {
        case 0:
            // by name
            self.bandsCollectionView.hidden = FALSE;
            self.noMustBandsText.hidden = TRUE;
            self.bandsAsInCollectionView = [Band sortBandsIn:self.festival.bands by:@"alphabetically"];
            [self reloadBandCollectionViewData];
            break;
        case 1:
            // by band similarity
            if([self.festival.mustBands count] > 0){
                self.bandsCollectionView.hidden = FALSE;
                self.noMustBandsText.hidden = TRUE;
                self.bandsAsInCollectionView = [Band sortBandsIn:self.festival.bands by:@"bandSimilarity"];
                [self reloadBandCollectionViewData];
            }
            else{
                self.bandsCollectionView.hidden = TRUE;
                self.noMustBandsText.hidden = FALSE;
            }
            break;
        case 2:
            // by band start time
            self.bandsCollectionView.hidden = FALSE;
            self.noMustBandsText.hidden = TRUE;
            self.bandsAsInCollectionView = [Band sortBandsIn:self.festival.bands by:@"startTime"];
            [self reloadBandCollectionViewData];
            break;
        default:
            break;
    }
    
    if(scrollToTop){
        [self.bandsCollectionView setContentOffset:CGPointZero animated:YES]; // scroll to the top
    }
    
    // log change of sorting only if shown as front view
    if(self.revealViewController.frontViewPosition == FrontViewPositionLeft){
        [self logPresenceEventInFlurry];
    }
    
}

- (IBAction)sortingOfCollectionChanged:(UISegmentedControl *)sender
{
    [self applyChangeInSortingOfCollectionWithScrollToTop:TRUE];
}

@end
