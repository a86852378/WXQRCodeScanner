//
//  WXQRCodeScannerViewController.m
//  WXQRCodeScanner
//
//  Created by vison on 2018/4/2.
//  Copyright © 2018年 vison. All rights reserved.
//

#import "WXQRCodeScannerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>
#import "WXQRCodeScannerView.h"

static CGFloat const kButtonWidthAndHeight = 35.f;

@interface WXQRCodeScannerViewController () <WXQRCodeScannerViewDelegate, AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *localPhotoButton;
@property (nonatomic, strong) UIButton *lightButton;
@property (nonatomic, strong) NSTimer *scanTimer;
@property (nonatomic, strong) WXQRCodeScannerView *scannerView;

/// the voice player when succeed scanning QR code
@property (nonatomic, strong) AVAudioPlayer *beepPlayer;

@property (nonatomic, strong) AVCaptureDevice *cameraDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *cameraDeviceInput;

@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;

/// the Session is used to link the input and output.
@property (nonatomic, strong) AVCaptureSession *session;

/// the role of the previewLayer is showing the image of the camera catched
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

/// intelligent recognizer, it is used to recognize the QR code on the photo which user select from photo album
@property (nonatomic, strong) CIDetector *detector;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

/// the property is used to judge if it is processing the scanning result
@property (nonatomic, assign, getter=isHandleResult) BOOL handleResult;

/// the property is used to judge if the media components is completed
@property (nonatomic, assign, getter=isCompleteSetupMedia) BOOL completeSetupMedia;


- (void)setupSubviews;

- (void)setupMediaComponents;

- (void)startScanning;

- (void)stopScanning;


@end

@implementation WXQRCodeScannerViewController

#pragma mark - Life Cycle -
- (void)viewDidLoad {
    [super viewDidLoad];

    self.handleResult = NO;
    self.completeSetupMedia = NO;
    [self setupSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self startScanning];
    if (!self.isCompleteSetupMedia) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (status) {
            case AVAuthorizationStatusNotDetermined:{
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [self setupMediaComponents];
                        });
                    }
                }];
                break;
            }
            case AVAuthorizationStatusAuthorized:{
                [self setupMediaComponents];
                break;
            }
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                break;
        }
        self.completeSetupMedia = YES;
    }
}

#pragma mark - Override Method -
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private Method -
- (void)setupSubviews {
    self.scannerView = [[WXQRCodeScannerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.scannerView.delegate = self;
    [self.view addSubview:self.scannerView];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.localPhotoButton];
    [self.view addSubview:self.lightButton];
}

- (void)setupMediaComponents {
    self.cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:nil];
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.session = [[AVCaptureSession alloc] init];
    if (self.cameraDeviceInput) {
        [self.session addInput:self.cameraDeviceInput];
    }
    if (self.metadataOutput) {
        [self.session addOutput:self.metadataOutput];
    }
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
    } else {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    [self.metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    // the method startRunning and stopRunning need to be executed in the child thread, or they will block the main thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session startRunning];
    });
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.previewLayer setFrame:self.scannerView.bounds];
    [self.scannerView.layer insertSublayer:self.previewLayer atIndex:0];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    self.beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
}

- (void)startScanning {
    // there will be a short delay when setup the timer to circulate the scanning line animation, so we need to execute the animation method once
    [self.scannerView startScanLineAnimate];

    if(_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    _scanTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self.scannerView selector:@selector(startScanLineAnimate) userInfo:nil repeats:YES];
}

- (void)stopScanning {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
    });

    [self.scannerView stopScanLineAnimate];
    if(_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
}

#pragma mark - Event Response -
- (void)clickbackButton:(UIButton *)sender {
    [self stopScanning];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clicklocalPhotoButton:(UIButton *)sender {

    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusNotDetermined:{
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self presentViewController:self.imagePickerController animated:YES completion:nil];
                        [self stopScanning];
                    });
                } else{
                }
            }];
            break;
        }
        case PHAuthorizationStatusAuthorized: {
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
            [self stopScanning];
        }
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            break;
    }
}

- (void)clicklightButton:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.cameraDevice hasTorch]) {
        [self.cameraDevice lockForConfiguration:nil];
        if (sender.selected) {
            [self.cameraDevice setTorchMode:AVCaptureTorchModeOn];
        }else{
            [self.cameraDevice setTorchMode:AVCaptureTorchModeOff];
        }
        [self.cameraDevice unlockForConfiguration];
    }
}

#pragma mark - QRCodeScannerViewDelegate -
- (void)loadView:(CGRect)innerViewRect {
    CGFloat innerViewX = innerViewRect.origin.x;
    CGFloat innerViewY = innerViewRect.origin.y;
    CGFloat innerViewWidth = innerViewRect.size.width;
    CGFloat innerViewHeight = innerViewRect.size.height;

    // set the range of area which could be recognized, the origin is on the right-bottom corner, and the rect must be scale
    [self.metadataOutput setRectOfInterest:CGRectMake(innerViewY / [UIScreen mainScreen].bounds.size.height, innerViewX / [UIScreen mainScreen].bounds.size.width, innerViewHeight / [UIScreen mainScreen].bounds.size.height, innerViewWidth / [UIScreen mainScreen].bounds.size.width)];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate -
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (self.isHandleResult) {
        return;
    }
    for(AVMetadataObject *current in metadataObjects) {
        if ([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]
            && [current.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *scanResultStr = [(AVMetadataMachineReadableCodeObject *)current stringValue];
            if (!scanResultStr) {
                return;
            }
            self.handleResult = YES;
            [self.beepPlayer play];

            // you can process the result here or return to last controller to process it through delegate method
            UIAlertController *alerController = [UIAlertController alertControllerWithTitle:@"扫描结果" message:scanResultStr preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                self.handleResult = NO;
            }];
            [alerController addAction:alertAction];
            [self.navigationController presentViewController:alerController animated:YES completion:nil];
            if ([self.delegate respondsToSelector:@selector(scannerViewController:handleResultString:)]) {
                [self.delegate scannerViewController:self handleResultString:scanResultStr];
            }
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSArray *features = [self.detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    if (features.count >= 1) {
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        NSString *scanResultStr = feature.messageString;
        if (!scanResultStr) {
            return;
        }
        self.handleResult = YES;
        [self.beepPlayer play];

        UIAlertController *alerController = [UIAlertController alertControllerWithTitle:@"扫描结果" message:scanResultStr preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.session startRunning];
            });
            self.handleResult = NO;
        }];
        [alerController addAction:alertAction];
        [self.navigationController presentViewController:alerController animated:YES completion:nil];

        if ([self.delegate respondsToSelector:@selector(scannerViewController:handleResultString:)]) {
            [self.delegate scannerViewController:self handleResultString:scanResultStr];
        }
    } else {
        // there is not QR code on the photo
        UIAlertController *alerController = [UIAlertController alertControllerWithTitle:nil message:@"识别不到二维码" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.session startRunning];
            });
        }];
        [alerController addAction:alertAction];
        [self.navigationController presentViewController:alerController animated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.session startRunning];
    });
}


#pragma mark - Getter -
- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setFrame:CGRectMake(20, 40, kButtonWidthAndHeight, kButtonWidthAndHeight)];
        [_backButton setBackgroundColor:[UIColor clearColor]];
        [_backButton setImage:[UIImage imageNamed:@"icon_scanner_back"] forState:UIControlStateNormal];
        _backButton.clipsToBounds = YES;
        [_backButton addTarget:self action:@selector(clickbackButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)localPhotoButton {
    if (!_localPhotoButton) {
        _localPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_localPhotoButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - (50 + kButtonWidthAndHeight * 2), 40, kButtonWidthAndHeight, kButtonWidthAndHeight)];
        [_localPhotoButton setBackgroundColor:[UIColor clearColor]];
        [_localPhotoButton setImage:[UIImage imageNamed:@"icon_xiangce"] forState:UIControlStateNormal];
        _localPhotoButton.clipsToBounds = YES;
        [_localPhotoButton addTarget:self action:@selector(clicklocalPhotoButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _localPhotoButton;
}

- (UIButton *)lightButton {
    if (!_lightButton) {
        _lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lightButton setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - (20 + kButtonWidthAndHeight), 40, kButtonWidthAndHeight, kButtonWidthAndHeight)];
        [_lightButton setBackgroundColor:[UIColor clearColor]];
        [_lightButton setImage:[UIImage imageNamed:@"icon_kaideng"] forState:UIControlStateNormal];
        [_lightButton setImage:[UIImage imageNamed:@"icon_guandeng"] forState:UIControlStateSelected];
        _lightButton.clipsToBounds = YES;
        [_lightButton addTarget:self action:@selector(clicklightButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lightButton;
}

- (CIDetector *)detector {
    if (!_detector) {
        _detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    }
    return _detector;
}

- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _imagePickerController.delegate = self;
        _imagePickerController.allowsEditing = NO;
    }
    return _imagePickerController;
}


@end
