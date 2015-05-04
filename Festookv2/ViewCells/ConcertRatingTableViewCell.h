//
//  ConcertRatingTableViewCell.h
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 04/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EbcEnhancedView.h"

@interface ConcertRatingTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet EbcEnhancedView *background;
@property (weak, nonatomic) IBOutlet UILabel *bandName;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bandRating;

@end
