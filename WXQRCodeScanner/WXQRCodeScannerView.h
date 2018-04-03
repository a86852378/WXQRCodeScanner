//
//  WXQRCodeScannerView.h
//  WXQRCodeScanner
//
//  Created by vison on 2018/4/2.
//  Copyright © 2018年 vison. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WXQRCodeScannerViewDelegate <NSObject>

/**
 *
 * When the calculation of the effective area is complete, the delegate method will be executed.
 * @param  effectiveAreaRect  The frame of the effective scanning area.
 *
 */
- (void)loadView:(CGRect)effectiveAreaRect;

@end

@interface WXQRCodeScannerView : UIView

@property (nonatomic, weak) id <WXQRCodeScannerViewDelegate> delegate;

/**
 *
 * Execute the animation of scanning line moves from effective area top to effective area bottom.
 *
 */
- (void)startScanLineAnimate;

/**
 *
 * Stop the animation of the scanning line.
 *
 */
- (void)stopScanLineAnimate;

@end
