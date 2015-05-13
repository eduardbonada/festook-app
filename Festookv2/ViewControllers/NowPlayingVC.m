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
    self.nowPlayingBands = [self.festival bandsPlayingAtDate:[dateFormatter dateFromString:@"29/05/2015 22:05"]]; //@[@"belleandsebastian",@"derpanther",@"damienrice",@"altj"];
    
    if([self.nowPlayingBands count] > 0){
        // there are bands playing right now
        self.emptyListTextView.hidden = YES;
    }
    else{
        // there are no bands playing right now
        self.emptyListTextView.hidden = NO;
    }
    
    [self.nowPlayingTableView setContentInset:UIEdgeInsetsMake(5,0,0,0)];
    
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
    
    // set labels
    cell.bandName.text = bandToShow.uppercaseName;
    cell.stage.text = bandToShow.stage;
    cell.startEndTime.text = [NSString stringWithFormat:@"%@-%@",[hourFormatter stringFromDate:bandToShow.startTime],[hourFormatter stringFromDate:bandToShow.endTime]];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

@end
