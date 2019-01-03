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

typedef NS_ENUM(NSInteger, ScannerSourceDeviceType) {
    ScannerSourceDeviceCamera,
    ScannerSourceDevicePhotoLibrary
};

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


- (void)configSubviews;

- (void)requestAuthorizationWithType:(ScannerSourceDeviceType)type completion:(void(^)(BOOL granted))completion;

- (void)configMediaComponents;

- (void)startScanning;

- (void)stopScanning;


@end

@implementation WXQRCodeScannerViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    self.handleResult = NO;
    [self configSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self requestAuthorizationWithType:ScannerSourceDeviceCamera completion:^(BOOL granted) {
        if (granted) {
            [self configMediaComponents];
            [self startScanning];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopScanning];
}

#pragma mark - Override Method
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private Method
- (void)configSubviews {
    self.scannerView = [[WXQRCodeScannerView alloc] initWithFrame:[UIScreen mainScreen].bounds delegate:self];
    [self.view addSubview:self.scannerView];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.localPhotoButton];
    [self.view addSubview:self.lightButton];
}

- (void)requestAuthorizationWithType:(ScannerSourceDeviceType)type completion:(void (^)(BOOL))completion {
    switch (type) {
        case ScannerSourceDeviceCamera: {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            switch (status) {
                case AVAuthorizationStatusNotDetermined: {
                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                        if (granted) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                completion(YES);
                            });
                        }
                    }];
                    break;
                }
                case AVAuthorizationStatusAuthorized: {
                    completion(YES);
                    break;
                }
                case AVAuthorizationStatusDenied:
                case AVAuthorizationStatusRestricted:
                    completion(NO);
                    break;
            }
        }
            break;
        case ScannerSourceDevicePhotoLibrary: {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            switch (status) {
                case PHAuthorizationStatusNotDetermined:{
                    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                        if (status == PHAuthorizationStatusAuthorized) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                completion(YES);
                            });
                        } else{
                        }
                    }];
                    break;
                }
                case PHAuthorizationStatusAuthorized: {
                    completion(YES);
                }
                    break;
                case PHAuthorizationStatusDenied:
                case PHAuthorizationStatusRestricted:
                    completion(NO);
                    break;
            }
        }
            break;
        default:
            break;
    }

}

- (void)configMediaComponents {
    if (_cameraDevice &&
        _cameraDeviceInput &&
        _metadataOutput &&
        _session &&
        _previewLayer) {
        return;
    }

    _cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!_cameraDevice) {
        return;
    }

    _cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:nil];
    if (!_cameraDeviceInput) {
        return;
    }

    _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];

    if ([_session canAddInput:_cameraDeviceInput]) {
        [_session addInput:_cameraDeviceInput];
    }
    if ([_session canAddOutput:_metadataOutput]) {
        [_session addOutput:_metadataOutput];
    }

    // Choose types what you need
    [self.metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode
//                                                  AVMetadataObjectTypeUPCECode,
//                                                  AVMetadataObjectTypeCode39Code,
//                                                  AVMetadataObjectTypeCode39Mod43Code,
//                                                  AVMetadataObjectTypeEAN13Code,
//                                                  AVMetadataObjectTypeEAN8Code,
//                                                  AVMetadataObjectTypeCode93Code,
//                                                  AVMetadataObjectTypeCode128Code,
//                                                  AVMetadataObjectTypePDF417Code,
//                                                  AVMetadataObjectTypeAztecCode,
//                                                  AVMetadataObjectTypeInterleaved2of5Code,
//                                                    AVMetadataObjectTypeITF14Code,
//                                                    AVMetadataObjectTypeDataMatrixCode
                                                  ]];
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    // the method startRunning and stopRunning need to be executed in the child thread, or they will block the main thread
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_previewLayer setFrame:self.scannerView.frame];
    [self.scannerView.layer insertSublayer:_previewLayer atIndex:0];

    // judge if the the device support auto focus, if yes, open the auto focus so that it is easier to extract QR code
    if (_cameraDevice.isFocusPointOfInterestSupported &&[_cameraDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        [_cameraDeviceInput.device lockForConfiguration:nil];
        [_cameraDeviceInput.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [_cameraDeviceInput.device unlockForConfiguration];
    }

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    _beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
}

- (void)startScanning {
    if(_cameraDeviceInput && ! _session.isRunning) {
        [_session startRunning];
        [self.scannerView.layer insertSublayer:self.previewLayer atIndex:0];
    }

    // there will be a short delay when setup the timer to circulate the scanning line animation, so we need to execute the animation method once
    [self.scannerView startScanLineAnimate];

    if(_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    _scanTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self.scannerView selector:@selector(startScanLineAnimate) userInfo:nil repeats:YES];
}

- (void)stopScanning {
    if(_cameraDeviceInput && _session.isRunning) {
        [_session stopRunning];
    }

    [self.scannerView stopScanLineAnimate];
    if(_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
}

#pragma mark - Button Action
- (void)clickbackButton:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clicklocalPhotoButton:(UIButton *)sender {
    [self requestAuthorizationWithType:ScannerSourceDevicePhotoLibrary completion:^(BOOL granted) {
        if (granted) {
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
        }
    }];
}

- (void)clicklightButton:(UIButton *)sender {
    if (!_cameraDevice) {
        return;
    }
    sender.selected = !sender.selected;
    if ([_cameraDevice hasTorch]) {
        [_cameraDevice lockForConfiguration:nil];
        if (sender.selected) {
            [_cameraDevice setTorchMode:AVCaptureTorchModeOn];
        }else {
            [_cameraDevice setTorchMode:AVCaptureTorchModeOff];
        }
        [_cameraDevice unlockForConfiguration];
    }
}

#pragma mark - QRCodeScannerViewDelegate
- (void)loadView:(CGRect)innerViewRect {
    CGFloat innerViewX = innerViewRect.origin.x;
    CGFloat innerViewY = innerViewRect.origin.y;
    CGFloat innerViewWidth = innerViewRect.size.width;
    CGFloat innerViewHeight = innerViewRect.size.height;

    // set the range of area which could be recognized, the origin is on the right-bottom corner, and the rect must be scale
    [self.metadataOutput setRectOfInterest:CGRectMake(innerViewY / [UIScreen mainScreen].bounds.size.height, innerViewX / [UIScreen mainScreen].bounds.size.width, innerViewHeight / [UIScreen mainScreen].bounds.size.height, innerViewWidth / [UIScreen mainScreen].bounds.size.width)];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
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

#pragma mark - UIImagePickerControllerDelegate
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
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alerController addAction:alertAction];
        [self.navigationController presentViewController:alerController animated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Getter
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
