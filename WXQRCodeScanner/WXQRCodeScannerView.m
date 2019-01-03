//
//  WXQRCodeScannerView.m
//  WXQRCodeScanner
//
//  Created by vison on 2018/4/2.
//  Copyright © 2018年 vison. All rights reserved.
//

#import "WXQRCodeScannerView.h"

static CGFloat const kMinSpaceToBorder = 65.f;
static CGFloat const kCorImageViewWidthAndHeight = 15.f;
static CGFloat const kScanLineHeight = 12.f;

@interface WXQRCodeScannerView ()

@property (nonatomic, assign) CGRect scanWindowRect;

@property (nonatomic, strong) UIImageView *scanLine;

/// setup the top, left, bottom, right border light gray line.
- (void)setupScanWindowBorderLayer:(CGRect)rect;

/// setup the dark area around the scanning window.
- (void)setupAreaLayerAroundScanWindow:(CGRect)rect;

/// setup the 4 corner image and scanning line.
- (void)setupImageSubview:(CGRect)rect;

@end

@implementation WXQRCodeScannerView

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame delegate:(id)delegate {
    if (self = [super initWithFrame:frame]) {
        self.delegate = delegate;

        // calculate the rect of the effective area
        CGRect scanWindowRect = CGRectInset(frame, kMinSpaceToBorder, kMinSpaceToBorder);
        CGFloat minSideLength = MIN(scanWindowRect.size.width, scanWindowRect.size.height);
        if (minSideLength == scanWindowRect.size.width) {
            scanWindowRect.origin.y += (scanWindowRect.size.height - minSideLength) / 2 - 30;
            scanWindowRect.size.height = minSideLength;
        } else if (minSideLength == frame.size.height) {
            scanWindowRect.origin.x += (scanWindowRect.size.width - minSideLength) / 2 - 30;
            scanWindowRect.size.width = minSideLength;
        }
        self.scanWindowRect = scanWindowRect;

        if ([self.delegate respondsToSelector:@selector(loadView:)]) {
            [self.delegate loadView:scanWindowRect];
        }

        [self setupScanWindowBorderLayer:scanWindowRect];
        [self setupAreaLayerAroundScanWindow:scanWindowRect];
        [self setupImageSubview:scanWindowRect];
    }
    return self;
}


#pragma mark - Private Method -
- (void)setupScanWindowBorderLayer:(CGRect)rect {
    CAShapeLayer *borderLine = [[CAShapeLayer alloc] init];
    borderLine.fillColor = [UIColor clearColor].CGColor;
    borderLine.strokeColor = [UIColor lightGrayColor].CGColor;
    borderLine.opacity = 0.5;
    borderLine.lineWidth = 1;
    borderLine.path = [UIBezierPath bezierPathWithRect:rect].CGPath;
    [self.layer addSublayer:borderLine];
}

- (void)setupAreaLayerAroundScanWindow:(CGRect)rect {
    CAShapeLayer *topLayer = [[CAShapeLayer alloc] init];
    topLayer.fillColor = [UIColor blackColor].CGColor;
    topLayer.opacity = 0.5;
    topLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, rect.origin.y)].CGPath;
    [self.layer addSublayer:topLayer];

    CAShapeLayer *leftLayer = [[CAShapeLayer alloc] init];
    leftLayer.fillColor = [UIColor blackColor].CGColor;
    leftLayer.opacity = 0.5;
    leftLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, rect.origin.y, rect.origin.x, rect.size.height)].CGPath;
    [self.layer addSublayer:leftLayer];

    CAShapeLayer *bottomLayer = [[CAShapeLayer alloc] init];
    bottomLayer.fillColor = [UIColor blackColor].CGColor;
    bottomLayer.opacity = 0.5;
    bottomLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(0, rect.origin.y + rect.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - rect.origin.y - rect.size.height)].CGPath;
    [self.layer addSublayer:bottomLayer];

    CAShapeLayer *rightLayer = [[CAShapeLayer alloc] init];
    rightLayer.fillColor = [UIColor blackColor].CGColor;
    rightLayer.opacity = 0.5;
    rightLayer.path = [UIBezierPath bezierPathWithRect:CGRectMake(rect.origin.x + rect.size.width, rect.origin.y, [UIScreen mainScreen].bounds.size.width - rect.origin.x - rect.size.width, rect.size.height)].CGPath;
    [self.layer addSublayer:rightLayer];
}

- (void)setupImageSubview:(CGRect)rect {
    CGFloat scanWindowX = rect.origin.x;
    CGFloat scanWindowY = rect.origin.y;
    CGFloat scanWindowWidth = rect.size.width;
    CGFloat scanWindowHeight = rect.size.height;

    UIImageView *corImgView1 = [[UIImageView alloc] initWithFrame:CGRectMake(scanWindowX, scanWindowY, kCorImageViewWidthAndHeight, kCorImageViewWidthAndHeight)];
    UIImage *corImg1 = [UIImage imageNamed:@"cor1.png"];
    // ignore the color of the image itself, make the color of the image follows the tintColor
    corImg1 = [corImg1 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    corImgView1.image = corImg1;
    corImgView1.tintColor = [UIColor whiteColor];
    [self addSubview:corImgView1];

    UIImageView *corImgView2 = [[UIImageView alloc] initWithFrame:CGRectMake(scanWindowX + scanWindowWidth - kCorImageViewWidthAndHeight, scanWindowY, kCorImageViewWidthAndHeight, kCorImageViewWidthAndHeight)];
    UIImage *corImg2 = [UIImage imageNamed:@"cor2.png"];
    corImg2 = [corImg2 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    corImgView2.image = corImg2;
    corImgView2.tintColor = [UIColor whiteColor];
    [self addSubview:corImgView2];

    UIImageView *corImgView3 = [[UIImageView alloc] initWithFrame:CGRectMake(scanWindowX, scanWindowY + scanWindowHeight - kCorImageViewWidthAndHeight, kCorImageViewWidthAndHeight, kCorImageViewWidthAndHeight)];
    UIImage *corImg3 = [UIImage imageNamed:@"cor3.png"];
    corImg3 = [corImg3 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    corImgView3.image = corImg3;
    corImgView3.tintColor = [UIColor whiteColor];
    [self addSubview:corImgView3];

    UIImageView *corImgView4 = [[UIImageView alloc] initWithFrame:CGRectMake(scanWindowX + scanWindowWidth - kCorImageViewWidthAndHeight, scanWindowY + scanWindowHeight - kCorImageViewWidthAndHeight, kCorImageViewWidthAndHeight, kCorImageViewWidthAndHeight)];
    UIImage *corImg4 = [UIImage imageNamed:@"cor4.png"];
    corImg4 = [corImg4 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    corImgView4.image = corImg4;
    corImgView4.tintColor = [UIColor whiteColor];
    [self addSubview:corImgView4];

    UILabel *reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(scanWindowX, scanWindowY + scanWindowHeight + 20, scanWindowWidth, 30)];
    reminderLabel.textColor = [UIColor whiteColor];
    reminderLabel.font = [UIFont systemFontOfSize:14];
    reminderLabel.textAlignment = NSTextAlignmentCenter;
    reminderLabel.text = @"将码放入框内，即可自动扫描";
    [self addSubview:reminderLabel];

    [self addSubview:self.scanLine];
}

#pragma mark - Public Method -
- (void)startScanLineAnimate {
    CGFloat scanWindowY = self.scanWindowRect.origin.y;
    CGFloat scanWindowHeight = self.scanWindowRect.size.height;
    CGFloat screenWidth = self.frame.size.width;
    self.scanLine.hidden = NO;
    [self.scanLine setFrame:CGRectMake(0, scanWindowY, screenWidth, kScanLineHeight)];
    [UIView animateWithDuration:2.5 animations:^{
        [self.scanLine setFrame:CGRectMake(0, scanWindowY + scanWindowHeight - kScanLineHeight, screenWidth, kScanLineHeight)];
    }];
}

- (void)stopScanLineAnimate {
    self.scanLine.hidden = YES;
    [self.scanLine.layer removeAllAnimations];
}

#pragma mark - Getter -
- (UIImageView *)scanLine {
    if (!_scanLine) {
        _scanLine = [[UIImageView alloc] init];
        [_scanLine setImage:[UIImage imageNamed:@"QRCodeScanLine.png"]];
    }
    return _scanLine;
}

@end
