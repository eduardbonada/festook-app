//
//  EbcEnhancedView.h
//  FestivalSchedule
//
//  Created by Eduard Bonada Cruells on 04/09/14.
//  Copyright (c) 2014 ebc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIImage+ImageEffects.h"

@interface EbcEnhancedView : UIView

@property (nonatomic) BOOL roundedRects;
@property (nonatomic) NSNumber* cornerRadius;

@property (nonatomic) NSAttributedString* centeredText;
@property (nonatomic) NSAttributedString* rightJustifiedText;
@property (nonatomic) NSAttributedString* leftJustifiedText;

-(void) setBackgroundPlain:(UIColor *)color withAlpha:(NSNumber*) alpha;
-(void) setBackgroundGradientFromColor:(UIColor *)colorA toColor:(UIColor *)colorB;
-(void) setBackgroundImage:(UIImage *)image withAlpha:(NSNumber*) alpha;

-(void) setBorderWithColor:(UIColor *)color andWidth:(CGFloat)width;

@end
