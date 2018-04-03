//
//  WXQRCodeScannerViewController.h
//  WXQRCodeScanner
//
//  Created by vison on 2018/4/2.
//  Copyright © 2018年 vison. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WXQRCodeScannerViewController;

@protocol WXQRCodeScannerDelegate <NSObject>

/**
 *
 * When the QR code is recognized, the deleagte method will be executed.
 * @param  scanner       The viewController which is scanning the QR code
 * @param  resultString  The content string of the QR code
 *
 */
- (void)scannerViewController:(WXQRCodeScannerViewController *)scanner handleResultString:(NSString *)resultString;

@end

@interface WXQRCodeScannerViewController : UIViewController

@property (nonatomic, weak) id <WXQRCodeScannerDelegate> delegate;

@end
