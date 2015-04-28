//
//  EbcEnhancedView.m
//  FestivalSchedule
//
//  Created by Eduard Bonada Cruells on 04/09/14.
//  Copyright (c) 2014 ebc. All rights reserved.
//

#import "EbcEnhancedView.h"

@interface EbcEnhancedView ()

@property (nonatomic, strong) UILabel* centeredTextLabel;
@property (nonatomic, strong) UILabel* rightJustifiedTextLabel;
@property (nonatomic, strong) UILabel* leftJustifiedTextLabel;

@property (nonatomic, strong) UIImageView* backgroundImageView;
@property (nonatomic) UIImage* backgroundImage;
@property (nonatomic) NSNumber* backgroundImageAlpha;

@property (nonatomic, strong) UIView* backgroundPlainView;
@property (nonatomic) UIColor* backgroundPlainColor;
@property (nonatomic) NSNumber* backgroundPlainAlpha;

@property (nonatomic, strong) UIView* backgroundGradientView;
@property (nonatomic) UIColor* backgroundGradientColorA;
@property (nonatomic) UIColor* backgroundGradientColorB;
@property (nonatomic) NSNumber* backgroundGradientAlpha;

@end


@implementation EbcEnhancedView


#pragma mark Lazy Instantiation of public properties

-(void)setRoundedRects:(BOOL)roundedRects
{
    _roundedRects = roundedRects;
    [self setNeedsDisplay];
}
-(void)setCenteredText:(NSAttributedString *)centeredText
{
    _centeredText = centeredText;
    [self setNeedsDisplay];
}
-(void)setRightJustifiedText:(NSAttributedString *)rightJustifiedText
{
    _rightJustifiedText = rightJustifiedText;
    [self setNeedsDisplay];
}
-(void)setLeftJustifiedText:(NSAttributedString *)leftJustifiedText
{
    _leftJustifiedText = leftJustifiedText;
    [self setNeedsDisplay];
}


#pragma mark Setting of backgrounds
-(void) setBackgroundImage:(UIImage *)image withAlpha:(NSNumber *)alpha
{
    self.backgroundImage = image;
    self.backgroundImageAlpha = alpha;
    [self setNeedsDisplay];
}
-(void) setBackgroundPlain:(UIColor *)color withAlpha:(NSNumber *)alpha
{
    self.backgroundPlainColor = color;
    self.backgroundPlainAlpha = alpha;
    [self setNeedsDisplay];
}
-(void) setBackgroundGradientFromColor:(UIColor *)colorA toColor:(UIColor *)colorB
{
    self.backgroundGradientColorA = colorA;
    self.backgroundGradientColorB = colorB;
    [self setNeedsDisplay];
}


#pragma mark Border

-(void) setBorderWithColor:(UIColor *)color andWidth:(CGFloat)width
{
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = width;
}

#pragma mark Initialization

-(void) setup
{
    
    // create subviews
    self.backgroundPlainView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.backgroundPlainView];
    self.backgroundGradientView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.backgroundGradientView];
    self.backgroundImageView = [[UIImageView alloc] init];
    [self addSubview:self.backgroundImageView];
    self.centeredTextLabel = [[UILabel alloc] init];
    [self addSubview:self.centeredTextLabel];
    self.rightJustifiedTextLabel = [[UILabel alloc] init];
    [self addSubview:self.rightJustifiedTextLabel];
    self.leftJustifiedTextLabel = [[UILabel alloc] init];
    [self addSubview:self.leftJustifiedTextLabel];
    
    //self.backgroundColor = [UIColor whiteColor];
    
}

- (void)awakeFromNib
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    // re-frame subviews when self.view changes
    
    self.backgroundImageView.frame = self.bounds;
    self.backgroundPlainView.frame = self.bounds;
}


#pragma mark Drawing

- (void)drawRect:(CGRect)rect
{

    // set rounded rect layer
    if(self.roundedRects){
        [self.layer setMasksToBounds:YES];
        if(self.cornerRadius){
            [self.layer setCornerRadius:[self.cornerRadius doubleValue]];
        }
        else{
            [self.layer setCornerRadius:self.frame.size.width*0.17]; // default value: 17% (as in iOS7 icons)
        }
    }

    [self drawBackgroundPlain];

    [self drawBackgroundGradient];

    [self drawTexts];
    
    [self drawBackgroundImage];
    
}

- (void) drawBackgroundPlain
{
    if(self.backgroundPlainColor){
        self.backgroundPlainView.backgroundColor = self.backgroundPlainColor;
        self.backgroundPlainView.alpha = (self.backgroundPlainAlpha==nil) ? 1.0 : [self.backgroundPlainAlpha doubleValue];
    }
}

-(void) drawBackgroundGradient
{
    if(self.backgroundGradientColorA){
        [self drawLinearGradientInContext:UIGraphicsGetCurrentContext()
                                   inRect:self.bounds
                                fromColor:self.backgroundGradientColorA.CGColor
                                  toColor:self.backgroundGradientColorB.CGColor];
    }

}

-(void) drawLinearGradientInContext:(CGContextRef) context inRect:(CGRect)rect fromColor:(CGColorRef)startColor toColor:(CGColorRef) endColor
{
    // from: http://www.raywenderlich.com/32283/core-graphics-tutorial-lines-rectangles-and-gradients

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = @[(__bridge id) startColor, (__bridge id) endColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}


-(void) drawBackgroundImage
{
    
    // set frame
    self.backgroundImageView.frame = self.bounds;
    
    // set and configure image
    UIImage* blurredImage = [self.backgroundImage applyBlurWithRadius:8
                                                            tintColor:[UIColor clearColor]
                                                saturationDeltaFactor:1.0
                                                            maskImage:nil];
    [self.backgroundImageView setImage:blurredImage];
    self.backgroundImageView.alpha = (self.backgroundImageAlpha==nil) ? 1.0 : [self.backgroundImageAlpha doubleValue];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    
}

- (void) drawTexts
{
    // set frame
    CGRect textFrame = CGRectMake(self.bounds.origin.x + self.bounds.size.width*0.05,
                                  self.bounds.origin.y, // + self.bounds.size.height*0.1,
                                  self.bounds.size.width - self.bounds.size.width*0.1,
                                  self.bounds.size.height); // - self.bounds.size.height*0.2);
    self.centeredTextLabel.frame = textFrame;
    self.rightJustifiedTextLabel.frame = textFrame;
    self.leftJustifiedTextLabel.frame = textFrame;
    
    // set text into labels
    if(self.centeredText){
        self.centeredTextLabel.attributedText = self.centeredText;
        self.centeredTextLabel.numberOfLines = 4;
    }
    if(self.rightJustifiedText){
        self.rightJustifiedTextLabel.attributedText = self.rightJustifiedText;
        self.rightJustifiedTextLabel.numberOfLines = 4;
    }
    if(self.leftJustifiedText){
        self.leftJustifiedTextLabel.attributedText = self.leftJustifiedText;
        self.leftJustifiedTextLabel.numberOfLines = 4;
    }
    
}


@end
