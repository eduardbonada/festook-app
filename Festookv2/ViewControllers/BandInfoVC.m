//
//  BandInfoVC.m
//  FestivalSchedule
//
//  Created by Eduard Bonada Cruells on 11/09/14.
//  Copyright (c) 2014 ebc. All rights reserved.
//

#import "BandInfoVC.h"

#import "Flurry.h"

#import "EbcEnhancedView.h"

@interface BandInfoVC ()

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundView;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundGreyBoxArtistView;
@property (weak, nonatomic) IBOutlet UILabel *bandName;
@property (weak, nonatomic) IBOutlet UILabel *labelAskingToGo;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mustDiscardedSegmentedControl;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundGreyBoxTimeView;
@property (weak, nonatomic) IBOutlet UILabel *time;


@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundGreyBoxStageView;
@property (weak, nonatomic) IBOutlet UILabel *stage;

@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundGreyBoxStyleView;
@property (weak, nonatomic) IBOutlet UILabel *style;

@property (weak, nonatomic) IBOutlet UIView *infoTextContainer;
@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundGreyBoxInfoTextView;
@property (weak, nonatomic) IBOutlet UITextView *infoText;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoTextBottomConstraint;

@property (weak, nonatomic) IBOutlet UIView *similarContainer;
@property (weak, nonatomic) IBOutlet EbcEnhancedView *backgroundGreyBoxSimilarView;
@property (weak, nonatomic) IBOutlet UILabel *similarText;

@end

@implementation BandInfoVC


#pragma mark Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
    
    [self logPresenceEventInFlurry];
}

-(void) setup
{
    if(self.band){
        
        // configure back button
        [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
         setTitleTextAttributes:
         @{NSForegroundColorAttributeName:[UIColor darkGrayColor],
           NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0]
           }
         forState:UIControlStateNormal];
        
        // set background color
        self.backgroundView.roundedRects = NO;
        [self.backgroundView setBackgroundGradientFromColor:self.band.festival.colorA
                                                    toColor:self.band.festival.colorB];
        
        // text labels text color
        UIColor *textColor = [UIColor darkGrayColor]; //self.band.festival.color;
        self.bandName.textColor         = textColor;
        self.labelAskingToGo.textColor  = textColor;
        self.time.textColor             = textColor;
        self.stage.textColor            = textColor;
        self.style.textColor            = textColor;
        //self.infoText.textColor         = textColor;
        self.similarText.textColor      = textColor;

        // set labels font
        self.bandName.font          = [UIFont fontWithName:@"HelveticaNeue-Light" size:21.0];
        self.labelAskingToGo.font   = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
        self.time.font              = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.stage.font             = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.style.font             = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        //self.infoText.font          = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.5];
        self.similarText.font       = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];

        [self configureArtistContainer];

        [self configureTimeContainer];
        
        [self configureStageContainer];

        [self configureStyleContainer];

        [self configureTextInfoContainer];

        [self configureSimilarContainer];

    }
    
}


#pragma mark - Interaction with backend

-(void)logPresenceEventInFlurry
{
    [Flurry logEvent:@"Band_Info_Shown" withParameters:@{@"userID":self.userID,@"festival":self.band.festival.lowercaseName,@"band":self.band.lowercaseName}]; 
}

-(void)logMustDiscardedBandsInFlurry
{
    NSString* allMustBands = @"";
    for(NSString* band in self.band.festival.mustBands.allKeys){
        allMustBands = [allMustBands stringByAppendingString:[NSString stringWithFormat:@"%@,",band]];
    }
    NSString* allDiscardedBands = @"";
    for(NSString* band in self.band.festival.discardedBands.allKeys){
        allDiscardedBands = [allDiscardedBands stringByAppendingString:[NSString stringWithFormat:@"%@,",band]];
    }
    
    [Flurry logEvent:@"Must_Discarded_Bands" withParameters:@{@"userID":self.userID,@"festival":self.band.festival.lowercaseName,@"mustBands":allMustBands,@"discardedBands":allDiscardedBands}];
}


#pragma mark Container Configurations

-(void) configureArtistContainer
{
    // configure artist container
    self.backgroundGreyBoxArtistView.roundedRects = YES;
    self.backgroundGreyBoxArtistView.cornerRadius = @(10.0);
    [self.backgroundGreyBoxArtistView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    self.bandName.text = self.band.uppercaseName;
    
    // configure segmented control
    [self.mustDiscardedSegmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0]}
                                                      forState:UIControlStateNormal];
    [self.mustDiscardedSegmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14.0],
                                                                 NSForegroundColorAttributeName:[UIColor lightTextColor]}
                                                      forState:UIControlStateSelected];
    [self.mustDiscardedSegmentedControl setBackgroundColor:[UIColor clearColor]];
    
    // configure highlight of segmented control
    if([self.band.festival.mustBands objectForKey:self.band.lowercaseName]){
        // it is a mustband
        [self highlightMustDiscardedControlAtSegment:0];
    }
    else if([self.band.festival.discardedBands objectForKey:self.band.lowercaseName]){
        // it is discarded band
        [self highlightMustDiscardedControlAtSegment:2];
    }
    else{
        // it is nothing
        [self highlightMustDiscardedControlAtSegment:1];
    }
}

-(void) configureTimeContainer
{
    // date formatter for the concert hours
    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    hourFormatter.dateFormat=@"HH:mm";
    NSDateFormatter *dayFormatter = [[NSDateFormatter alloc] init];
    dayFormatter.dateFormat=@"dd";

    self.backgroundGreyBoxTimeView.roundedRects = YES;
    self.backgroundGreyBoxTimeView.cornerRadius = @(10.0);
    [self.backgroundGreyBoxTimeView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    self.time.text = [[NSString alloc] initWithFormat:@"%@ %@\n%@",
                      [self.band weekdayOfConcert],
                      [dayFormatter stringFromDate:[self.band dayOfConcert]],
                      [hourFormatter stringFromDate:self.band.startTime]
                      ];
    /*self.time.text = [[NSString alloc] initWithFormat:@"%@ %@, %@-%@\n",
     [self.band weekdayOfConcert],
     [dayFormatter stringFromDate:[self.band dayOfConcert]],
     [hourFormatter stringFromDate:self.band.startTime],
     [hourFormatter stringFromDate:self.band.endTime]
     ];*/
    
}

-(void) configureStageContainer
{
    self.backgroundGreyBoxStageView.roundedRects = YES;
    self.backgroundGreyBoxStageView.cornerRadius = @(10.0);
    [self.backgroundGreyBoxStageView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    self.stage.text = self.band.stage;
}

-(void) configureStyleContainer
{
    self.backgroundGreyBoxStyleView.roundedRects = YES;
    self.backgroundGreyBoxStyleView.cornerRadius = @(10.0);
    [self.backgroundGreyBoxStyleView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    self.style.text = self.band.style;
}

-(void) configureTextInfoContainer
{

    self.backgroundGreyBoxInfoTextView.roundedRects = YES;
    self.backgroundGreyBoxInfoTextView.cornerRadius = @(10.0);
    [self.backgroundGreyBoxInfoTextView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];

    // configure text
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentJustified;
    if(self.band.infoText){
        self.infoText.attributedText = [[NSAttributedString alloc] initWithString:self.band.infoText
                                                                       attributes:@{NSParagraphStyleAttributeName:paragraphStyle,
                                                                                    NSForegroundColorAttributeName:[UIColor darkGrayColor],
                                                                                    NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.5]}
                                        ];
    }
    else{
        self.infoText.text = @"";
    }
    [self.infoText scrollRangeToVisible:NSMakeRange(0, 0)];
    
}

-(void) configureSimilarContainer
{

    // background
    self.backgroundGreyBoxSimilarView.roundedRects = YES;
    self.backgroundGreyBoxSimilarView.cornerRadius = @(10.0);
    [self.backgroundGreyBoxSimilarView setBackgroundPlain:[UIColor groupTableViewBackgroundColor] withAlpha:@(1.0)];
    
    // configure text
    NSString* sentence = [self sentenceOfBandSimilarity];
    self.similarText.text = sentence;
    
    // hide/unhide depending on sentence of band similarity
    if([sentence isEqualToString:@""]){
        self.similarContainer.hidden = YES;
        self.infoTextBottomConstraint.constant = 8.0;
    }
    else{
        self.similarContainer.hidden = NO;
        self.infoTextBottomConstraint.constant = 66.0;
    }
    
}

#pragma mark Management of Must/Discarded segmented control

- (IBAction)mustDiscardSegmentedControlPressed:(UISegmentedControl *)sender
{
    if(self.mustDiscardedSegmentedControl.selectedSegmentIndex == 0){
        // mark as mustBand
        [self.band.festival.mustBands setObject:self.band forKey:self.band.lowercaseName];
        [self.band.festival.discardedBands removeObjectForKey:self.band.lowercaseName];
    }
    else if(self.mustDiscardedSegmentedControl.selectedSegmentIndex == 1){
        // mark as 'nothing' band
        if([self.band.festival.mustBands objectForKey:self.band.lowercaseName]){
            [self.band.festival.mustBands removeObjectForKey:self.band.lowercaseName];
        }
        if([self.band.festival.discardedBands objectForKey:self.band.lowercaseName]){
            [self.band.festival.discardedBands removeObjectForKey:self.band.lowercaseName];
        }
    }
    else if(self.mustDiscardedSegmentedControl.selectedSegmentIndex == 2){
        // mark as discardBand
        [self.band.festival.mustBands removeObjectForKey:self.band.lowercaseName];
        [self.band.festival.discardedBands setObject:self.band forKey:self.band.lowercaseName];
    }
    else{
    }

    // update appearance of segmented control
    [self highlightMustDiscardedControlAtSegment:self.mustDiscardedSegmentedControl.selectedSegmentIndex];

    // update persisted mustBands and discardedBands
    [self.band.festival storeMustBandsInNSUserDefaults];
    [self.band.festival storeDiscardedBandsInNSUserDefaults];
    
    // log
    [self logMustDiscardedBandsInFlurry];
    
    // back to last VC
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:TRUE];
    });

}

-(void) highlightMustDiscardedControlAtSegment:(NSUInteger) segment
{
    if(segment == 0){
        // show it is as mustBand
        self.mustDiscardedSegmentedControl.tintColor = [UIColor colorWithRed:147.0/255 green:197.0/255 blue:14.0/255 alpha:0.7];
    }
    else if(segment == 1){
        // show it is a 'nothing' band
        self.mustDiscardedSegmentedControl.tintColor = [UIColor grayColor];
    }
    else if(segment == 2){
        // show it is as discardBand
        self.mustDiscardedSegmentedControl.tintColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    }
    else{
    }
    
    self.mustDiscardedSegmentedControl.selectedSegmentIndex = segment;
}

#pragma mark Creation of Similar Sentence
-(NSString*) sentenceOfBandSimilarity
{
    NSString* sentence = @"";
    Festival* festival = self.band.festival;
    
    // look for closest must band
    NSString* closestMustBand = @"";
    NSNumber* closestDistance = @(1000);
    for(NSString* mustBand in [self.band.festival.mustBands allKeys]){
        NSNumber* distance = [festival distanceBetweenBands:self.band.lowercaseName and:mustBand];
        if([distance doubleValue] < [closestDistance doubleValue]){
            closestDistance = distance;
            closestMustBand = [mustBand copy];
        }
    }
    
    // if current band is a must band, no sentence is shown
    if([closestMustBand isEqualToString:self.band.lowercaseName]){
        sentence = @"";
    }
    else if([closestDistance doubleValue] <= 1.0){
        sentence = [NSString stringWithFormat:@"Very similar to %@",((Band*)[self.band.festival.bands objectForKey:closestMustBand]).uppercaseName];
    }
    else if([closestDistance doubleValue] <= 2.0){
        sentence = [NSString stringWithFormat:@"Quite similar to %@",((Band*)[self.band.festival.bands objectForKey:closestMustBand]).uppercaseName];
    }
    else if([closestDistance doubleValue] <= 4.0){
        sentence = [NSString stringWithFormat:@"Slightly similar to %@",((Band*)[self.band.festival.bands objectForKey:closestMustBand]).uppercaseName];
    }
    else{
        sentence = @"";
    }
    
    return sentence;
}


@end
