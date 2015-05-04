//
//  FestivalMenuTVC.m
//  SidebarDemo
//
//  Created by Simon on 29/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "FestivalMenuTVC.h"

#import "SWRevealViewController.h"

#import "FestivalRevealVC.h"
#import "FestivalLogoMenuTableViewCell.h"
#import "FestivalIconsMenuTableViewCell.h"

#import "Festival.h"
#import "Band.h"
#import "FestivalSchedule.h"

#import "Flurry.h"

@interface FestivalMenuTVC ()

@property (nonatomic, strong) NSArray *menuItems;
@end

@implementation FestivalMenuTVC

// SWRevealViewController: Declare the menuItems variable to store the cell identifier of the menu items
NSArray *menuItems;


#pragma mark - Initialization

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // SWRevealViewController: Configure the array of menu items
    menuItems = @[@"festival", @"lineup", @"schedule", @"ratings", @"information", @"allFestivals"];
    
    // remove separators in last cells
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addBackgroundView];
    
    self.clearsSelectionOnViewWillAppear = YES;

    [self.tableView reloadData];
    
    [self logPresenceEventInFlurry];

}


-(void) addBackgroundView
{
    Festival* festival = ((FestivalRevealVC*) self.revealViewController).festival;
    
    EbcEnhancedView *backgroundView = [[EbcEnhancedView alloc] initWithFrame: self.view.frame];
    
    backgroundView.roundedRects = NO;
    
    // set gradient colors
    //[backgroundView setBackgroundGradientFromColor:festival.colorA toColor:festival.colorB];
    
    // set lighther or darker gradient colors
    CGFloat colorDelta = 0.05; // +: lighter | -: darker
    CGFloat colorAred, colorAgreen, colorAblue, colorAalpha;
    CGFloat colorBred, colorBgreen, colorBblue, colorBalpha;
    [festival.colorA getRed:&colorAred green:&colorAgreen blue:&colorAblue alpha:&colorAalpha];
    [festival.colorB getRed:&colorBred green:&colorBgreen blue:&colorBblue alpha:&colorBalpha];
    [backgroundView setBackgroundGradientFromColor:[UIColor colorWithRed:colorAred+colorDelta green:colorAgreen+colorDelta blue:colorAblue+colorDelta alpha:1.0]
                                           toColor:[UIColor colorWithRed:colorBred+colorDelta green:colorBgreen+colorDelta blue:colorBblue+colorDelta alpha:1.0]];
    
    // add as subview
    [self.tableView addSubview: backgroundView];
    [self.tableView sendSubviewToBack:backgroundView];
    [self.tableView setNeedsDisplay];
    
    // avoid any top offset
    [self.tableView setContentInset:UIEdgeInsetsMake(0,0,0,0)];
    
}


#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Menu_Shown" withParameters:@{@"userID":((FestivalRevealVC*)self.revealViewController).userID,@"festival":[((FestivalRevealVC*)self.revealViewController).festival lowercaseName]}];
}


#pragma mark - gesture recognizers actions

- (IBAction)showAllFestivals:(UITapGestureRecognizer *)sender
{
    
    [self.navigationController popToRootViewControllerAnimated:YES]; // for push segue
    
    // [self dismissViewControllerAnimated:YES completion:nil]; // for modal segue
    
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // SWRevealViewController: the number of rows in the section is the number of items in the menu
    return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // SWRevealViewController: Get the right cell identifier
    NSString *cellIdentifier = [menuItems objectAtIndex:indexPath.row];
    
    // configure the first cell with the festival logo
    if([cellIdentifier isEqualToString:@"festival"]){
        FestivalLogoMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"festival"];
        
        // configure the view of the festival logo
        if([cell.festivalView isKindOfClass:[EbcEnhancedView class]]){
            
            Festival* festival = ((FestivalRevealVC*) self.revealViewController).festival;
            // set visual graphic configuration
            cell.festivalView.roundedRects = YES;
            cell.festivalView.cornerRadius = @(12.0);
            //[cell.festivalView setBackgroundPlain:[UIColor whiteColor] withAlpha:@(0.8)];
            //[cell.festivalView setBackgroundGradientFromColor:festival.colorA toColor:festival.colorB];
            [cell.festivalView setBorderWithColor:festival.colorB andWidth:1.5f];
            
            // set the NSAttributedString in the title
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            NSDictionary* attributes = @{NSFontAttributeName            : [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0],
                                         NSForegroundColorAttributeName : [UIColor whiteColor],
                                         NSParagraphStyleAttributeName  : paragraphStyle
                                         };
            NSString* festivalName = [[festival.uppercaseName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]] componentsJoinedByString:@"\n"];
            cell.festivalView.centeredText = [[NSAttributedString alloc] initWithString:festivalName
                                                                        attributes:attributes];
        }
        return cell;
    }
    else{
        FestivalIconsMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        if([cellIdentifier isEqualToString:@"ratings"]){
            NSInteger badgeNumber = [self numberOfBandsWithPendingRating];
            
            if(badgeNumber > 0){
                cell.badge.hidden = NO;

                // configure badge background
                cell.badge.roundedRects = YES;
                cell.badge.cornerRadius = @(cell.badge.frame.size.height/2);
                [cell.badge setBackgroundPlain:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.6] withAlpha:@(1.0)];
                
                //configure badge font
                UIFont* badgeFont;
                if(badgeNumber < 10){
                    badgeFont = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
                }
                else if(badgeNumber < 100){
                    badgeFont = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
                }
                else{
                    badgeFont = [UIFont fontWithName:@"HelveticaNeue" size:10.0];
                }
                
                // set the NSAttributedString in the title of the badge
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.alignment = NSTextAlignmentCenter;
                NSDictionary* attributes = @{NSFontAttributeName            : badgeFont,
                                             NSForegroundColorAttributeName : [UIColor whiteColor],
                                             NSParagraphStyleAttributeName  : paragraphStyle
                                             };
                cell.badge.centeredText = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat:@"%d",badgeNumber]
                                                                          attributes:attributes];
            }
            else{
                cell.badge.hidden = YES;
            }
        }
        
        return cell;
    }
    
}

-(NSInteger) numberOfBandsWithPendingRating
{
    Festival *festival = ((FestivalRevealVC*)self.revealViewController).festival;
    
    // temporary dat formatter
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat=@"dd/MM/yyyy HH:mm";

    // get which bands have already played
    [festival.schedule computeSchedule];
    NSArray *allRecommendedBands = [festival.schedule bandsToAttendSortedByTimeBetween:festival.start and:festival.end withOptions:@"recommendedBands"];
    NSMutableArray *bandsPendingToRate = [[NSMutableArray alloc] init];
    for(NSString* bandName in allRecommendedBands){
        /*
         
         REVIEW FOR PRODUCTION
         
         */
        NSDate *currentTime = [NSDate date]; //[dateFormatter dateFromString:@"29/05/2014 23:59"];
        
        NSDate *bandEndingTime = ((Band*)[festival.bands objectForKey:bandName]).endTime;
        NSString* bandRating = [[[NSUserDefaults standardUserDefaults] objectForKey:@"concertRatings"] objectForKey:bandName];
        if(([currentTime compare:bandEndingTime] == NSOrderedDescending) && !bandRating){
            [bandsPendingToRate addObject:bandName];
        }
    }
    
    return [bandsPendingToRate count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [menuItems objectAtIndex:indexPath.row];
    
    if([cellIdentifier isEqualToString:@"festival"]){
        return 136.0;
    }
    else{
        return 60.0;
    }
}




@end
