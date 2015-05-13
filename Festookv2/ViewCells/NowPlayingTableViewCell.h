//
//  NowPlayingTableViewCell.h
//  Festookv2
//
//  Created by Eduard Bonada Cruells on 13/05/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EbcEnhancedView.h"

@interface NowPlayingTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet EbcEnhancedView *background;

@property (weak, nonatomic) IBOutlet UILabel *bandName;
@property (weak, nonatomic) IBOutlet UILabel *stage;
@property (weak, nonatomic) IBOutlet UILabel *startEndTime;

@end
