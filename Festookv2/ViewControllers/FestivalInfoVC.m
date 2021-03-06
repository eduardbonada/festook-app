//
//  FestivalInfoVC.m
//  Festook
//
//  Created by Eduard Bonada Cruells on 22/04/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "FestivalInfoVC.h"

#import "SWRevealViewController.h"
#import "FestivalRevealVC.h"

#import "Flurry.h"

#import "EbcEnhancedView.h"
#import "Festival.h"
#import "Band.h"
#import "FestivalSchedule.h"
#import "BandSimilarityCalculator.h"

@interface FestivalInfoVC () <SWRevealViewControllerDelegate>

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (weak, nonatomic) IBOutlet UIView *overlayView;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *nameContainerBackground;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *socialContainerBackground;
@property (weak, nonatomic) IBOutlet UIButton *webButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *youtubeButton;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *dataContainerBackground;
@property (weak, nonatomic) IBOutlet UILabel *numBandsLabel;
@property (weak, nonatomic) IBOutlet UILabel *numStagesLabel;
@property (weak, nonatomic) IBOutlet UILabel *numDaysLabel;
@property (weak, nonatomic) IBOutlet UILabel *numHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *similarBandsLabel;

@end


@implementation FestivalInfoVC


#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set navigation bar title
    self.title = @"Festival Information";
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

    [self setup];
    
    [self logPresenceEventInFlurry];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void) setup
{
    // set background
    self.backgroundView.roundedRects = NO;
    [self.backgroundView setBackgroundGradientFromColor:self.festival.colorA toColor:self.festival.colorB];
    
    // set self as revealVC delegate
    self.revealViewController.delegate = self;
    
    // hide the overlay view
    if(self.revealViewController.frontViewPosition != FrontViewPositionLeft){
        self.overlayView.hidden = NO;
    }
    else{
        self.overlayView.hidden = YES;
    }
    
    [self configureNameContainer];

    [self configureSocialContainer];
    
    [self configureDataContainer];
}

-(void) configureNameContainer
{
    self.nameContainerBackground.roundedRects = YES;
    self.nameContainerBackground.cornerRadius = @(10.0);
    [self.nameContainerBackground setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    
    self.nameLabel.text = self.festival.uppercaseName;
    self.dateLabel.text = self.festival.when;
    self.cityLabel.text = self.festival.where;
}

-(void) configureSocialContainer
{
    // background
    self.socialContainerBackground.roundedRects = YES;
    self.socialContainerBackground.cornerRadius = @(10.0);
    [self.socialContainerBackground setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    
    // social links - web
    if(self.festival.web && ![self.festival.web isEqualToString:@""]){
        self.webButton.alpha = 0.4;
        self.webButton.userInteractionEnabled = YES;
    }
    else{
        self.webButton.alpha = 0.1;
        self.webButton.userInteractionEnabled = NO;
    }

    // social links - twitter
    if(self.festival.twitter && ![self.festival.twitter isEqualToString:@""]){
        self.twitterButton.alpha = 0.4;
        self.twitterButton.userInteractionEnabled = YES;
    }
    else{
        self.twitterButton.alpha = 0.1;
        self.twitterButton.userInteractionEnabled = NO;
    }

    // social links - facebook
    if(self.festival.facebook && ![self.festival.facebook isEqualToString:@""]){
        self.facebookButton.alpha = 0.4;
        self.facebookButton.userInteractionEnabled = YES;
    }
    else{
        self.facebookButton.alpha = 0.1;
        self.facebookButton.userInteractionEnabled = NO;
    }

    // social links - youtube
    if(self.festival.youtube && ![self.festival.youtube isEqualToString:@""]){
        self.youtubeButton.alpha = 0.4;
        self.youtubeButton.userInteractionEnabled = YES;
    }
    else{
        self.youtubeButton.alpha = 0.1;
        self.youtubeButton.userInteractionEnabled = NO;
    }

}

-(void) configureDataContainer
{
    // background
    self.dataContainerBackground.roundedRects = YES;
    self.dataContainerBackground.cornerRadius = @(10.0);
    [self.dataContainerBackground setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    
    // labels with numerical data
    self.numBandsLabel.text     = [NSString stringWithFormat:@"%lu bands",(unsigned long)[self.festival.bands count]];
    self.numStagesLabel.text    = [NSString stringWithFormat:@"%lu stages",(unsigned long)[[self.festival stageNames] count]];
    self.numDaysLabel.text      = [NSString stringWithFormat:@"%lu days",(unsigned long)[[self.festival.schedule daysToAttendWithOptions:@"allBands"] count]];
    self.numHoursLabel.text     = [NSString stringWithFormat:@"%ld hours",(long)[[self.festival hoursOfMusic] integerValue]];
    
    // label of similar bands
    if(!self.festival.bandSimilarityCalculator){
        self.festival.bandSimilarityCalculator = [[BandSimilarityCalculator alloc] initWithFestival:self.festival];
    }
    NSDictionary* pairOfSimilarBands;
    BOOL sameBand = YES;
    do {
        pairOfSimilarBands = [self.festival.bandSimilarityCalculator pairOfSimilarBandNames];
        sameBand = [NSSet setWithArray:[pairOfSimilarBands allValues]].count == 2 ? YES : NO ;
    } while (sameBand);
    NSString* bandA = [((Band*)[self.festival.bands objectForKey:[pairOfSimilarBands objectForKey:@"bandA"]]) uppercaseName];
    NSString* bandB = [((Band*)[self.festival.bands objectForKey:[pairOfSimilarBands objectForKey:@"bandB"]]) uppercaseName];
    self.similarBandsLabel.text = [NSString stringWithFormat:@"%@ - %@", bandA, bandB];
    
}

#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Festival_Info_Shown" withParameters:@{@"userID":self.userID,@"festival":self.festival.lowercaseName}];
}
-(void)logSocialClickEventInFlurry:(NSString*) socialLink
{
    [Flurry logEvent:@"Festival_Info_Social_Click" withParameters:@{@"userID":self.userID,@"festival":self.festival.lowercaseName,@"socialLink":socialLink}];
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
        self.webButton.userInteractionEnabled = YES;
        self.twitterButton.userInteractionEnabled = YES;
        self.facebookButton.userInteractionEnabled = YES;
        self.youtubeButton.userInteractionEnabled = YES;
        self.overlayView.hidden = YES;
        
    } else {
        self.webButton.userInteractionEnabled = NO;
        self.twitterButton.userInteractionEnabled = NO;
        self.facebookButton.userInteractionEnabled = NO;
        self.youtubeButton.userInteractionEnabled = NO;
        self.overlayView.hidden = NO;
    }
}


#pragma mark - Social links actions

- (IBAction)webButtonPressed:(UIButton *)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.festival.web]];

    [self logSocialClickEventInFlurry:@"web"];
}
- (IBAction)twitterButtonPressed:(UIButton *)sender
{
    NSString* twitterUrl = @"";
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]){
        twitterUrl = [[NSString alloc] initWithFormat:@"twitter://user?screen_name=%@",self.festival.twitter];
    }
    else{
        twitterUrl = [[NSString alloc] initWithFormat:@"http://www.twitter.com/%@",self.festival.twitter];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterUrl]];

    [self logSocialClickEventInFlurry:@"twitter"];
}
- (IBAction)facebookButtonPressed:(UIButton *)sender
{
    NSString* facebookUrl = @"";
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]){
        facebookUrl = [[NSString alloc] initWithFormat:@"fb://profile/%@",self.festival.facebook];
    }
    else{
        facebookUrl = [[NSString alloc] initWithFormat:@"https://www.facebook.com/profile.php?id=%@",self.festival.facebook];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:facebookUrl]];
    
    [self logSocialClickEventInFlurry:@"facebook"];

}
- (IBAction)youtubeButtonPressed:(UIButton *)sender
{
    NSString* youtubeUrl = @"";
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"youtube://"]]){
        youtubeUrl = [[NSString alloc] initWithFormat:@"youtube://www.youtube.com/c/%@",self.festival.youtube];
    }
    else{
        youtubeUrl = [[NSString alloc] initWithFormat:@"http://www.youtube.com/%@",self.festival.youtube];
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:youtubeUrl]];
    
    [self logSocialClickEventInFlurry:@"youtube"];
}


@end
