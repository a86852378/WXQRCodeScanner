//
//  ViewController.m
//  WXQRCodeScanner
//
//  Created by vison on 2018/4/2.
//  Copyright © 2018年 vison. All rights reserved.
//

#import "ViewController.h"
#import "WXQRCodeScannerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat buttonWidth = 80.f;
    CGFloat buttonHeight = 80.f;
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat screenHeight = self.view.frame.size.height;
    UIButton *scannerButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - buttonWidth) / 2, (screenHeight - buttonHeight) / 2 - 100, buttonWidth, buttonHeight)];
    [scannerButton setTitle:@"扫一扫" forState:UIControlStateNormal];
    [scannerButton setTitleEdgeInsets:UIEdgeInsetsMake(60, - 60, 0, 0)];
    [scannerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [scannerButton setImage:[UIImage imageNamed:@"icon_saoma"] forState:UIControlStateNormal];
    [scannerButton addTarget:self action:@selector(clickScannerButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scannerButton];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clickScannerButton:(UIButton *)sender {
    WXQRCodeScannerViewController *vc = [[WXQRCodeScannerViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


@end
