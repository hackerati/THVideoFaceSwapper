//
//  FSPhotoPickerViewController.m
//  videoApp
//
//  Created by Clayton Rieck on 4/8/15.
//
//

#import "THPhotoPickerViewController.h"
#include "ofApp.h"

#import "THFacePickerCollectionViewCell.h"
#import "MBProgressHUD.h"

static NSString *kTHCellReuseIdentifier = @"cell";
static NSArray *kTHLoadingDetails = @[@"You're gonna look great!", @"Ooo how handsome", @"Your alias is on the way!", @"Better than Mrs. Doubtfire"];

static const CGSize kTHCellSize = (CGSize){100.0f, 100.0f};
static const CGFloat kTHItemSpacing = 2.0f;
static const CGFloat kTHAnimationDuration = 0.3f;

@interface THPhotoPickerViewController ()
<UICollectionViewDataSource,
UICollectionViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate>
{
    ofApp *mainApp;
}

@property (strong, nonatomic) NSArray *facesArray;
@property (nonatomic) UICollectionView *facesCollectionView;

@end

@implementation THPhotoPickerViewController

- (instancetype)initWithFaces:(NSArray *)faces
{
    self = [super init];
    if ( self ) {
        mainApp = (ofApp *)ofGetAppPtr();
        _facesArray = faces;
        
        self.title = @"Face Selector";
    }
    return self;
}

- (void)setupMenuButtons
{
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"camera"] style:UIBarButtonItemStylePlain target:self action:@selector(presentCameraPicker)];
    self.navigationItem.rightBarButtonItem = cameraButton;
}

- (void)setupCollectionView
{
    const CGRect collectionViewFrame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    const UIEdgeInsets collectionViewInsets = UIEdgeInsetsMake(8.0f, 8.0f, 0.0f, 8.0f);
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = kTHCellSize;
    flowLayout.minimumInteritemSpacing = kTHItemSpacing;
    flowLayout.minimumLineSpacing = kTHItemSpacing;
    
    UICollectionView *facesCollectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
    [facesCollectionView registerClass:[THFacePickerCollectionViewCell class] forCellWithReuseIdentifier:kTHCellReuseIdentifier];
    facesCollectionView.backgroundColor = [UIColor whiteColor];
    facesCollectionView.contentInset = collectionViewInsets;
    facesCollectionView.delegate = self;
    facesCollectionView.dataSource = self;
    [self.view addSubview:facesCollectionView];
    _facesCollectionView = facesCollectionView;
}

- (void)dealloc
{
    _facesCollectionView = nil;
    [super dealloc];
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupMenuButtons];
    [self setupCollectionView];
}

#pragma mark - Public

- (void)presentVC:(BOOL)animated
{
    const CGFloat targetAlpha = 1.0f;
    CGFloat animationDuration;
    if ( animated ) {
        animationDuration = kTHAnimationDuration;
    }
    else {
        animationDuration = 0.0f;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.view.alpha = targetAlpha;
    }];
}

#pragma mark - Private

- (void)dismissVC
{
    [self dismissViewControllerAnimated:YES completion:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

- (void)presentCameraPicker
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (NSString *)randomLoadingDetail
{
    const NSInteger lowerBound = 0;
    const NSInteger upperBound = kTHLoadingDetails.count;
    const NSInteger randomPosition = lowerBound + arc4random() % (upperBound - lowerBound);
    return kTHLoadingDetails[randomPosition];
}

- (void)showLoadingHUD
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Loading Face";
    hud.detailsLabelText = [self randomLoadingDetail];
}

- (void)loadFace:(UIImage *)image withCompletion:(void (^)(void))completion
{
    [self showLoadingHUD];
    
    dispatch_async(dispatch_queue_create("imageLoadingQueue", NULL), ^{
        
        ofImage pickedImage;
        ofxiOSUIImageToOFImage(image, pickedImage);
        pickedImage.setImageType(OF_IMAGE_COLOR);
        pickedImage.rotate90(1);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            mainApp->loadOFImage(pickedImage);
            mainApp->setupCam(self.view.frame.size.width, self.view.frame.size.height);
            [self.facesCollectionView reloadData];
            if ( completion ) {
                completion();
            }
        });
    });
}

UIImage * uiimageFromOFImage(ofImage inputImage)
{
    int width = inputImage.width;
    int height = inputImage.height;
    float pixelForChannel = 3;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, inputImage.getPixels(), width*height*pixelForChannel, NULL);
    CGImageRef imageRef = CGImageCreate(width, height, 8, 24, pixelForChannel*width, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
    UIImage *pngImge = [UIImage imageWithCGImage:imageRef];
    NSData *imageData = UIImagePNGRepresentation(pngImge);
    UIImage *output = [UIImage imageWithData:imageData];
    return output;
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    mainApp->cam.close();
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [self loadFace:info[UIImagePickerControllerOriginalImage] withCompletion:^{
            [self dismissVC];
        }];

    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self showLoadingHUD];
    
    dispatch_async(dispatch_queue_create("imageLoadingQueue", NULL), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            mainApp->loadFace(mainApp->faces.getPath(indexPath.row));
            [self dismissVC];
        });
    });
}

#pragma mark - UICollectionView Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return mainApp->faces.size();
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    THFacePickerCollectionViewCell *cell = (THFacePickerCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kTHCellReuseIdentifier forIndexPath:indexPath];

    cell.currentIndexPath = indexPath;
    [cell clearImage];
    [cell startLoading];
    dispatch_async(dispatch_queue_create("cellImageQueue", NULL), ^{
        ofImage preInstalledImage;
        preInstalledImage.loadImage(mainApp->faces.getPath(indexPath.row));
        UIImage *faceImage = uiimageFromOFImage(preInstalledImage);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell setFaceWithImage:faceImage atIndexPath:indexPath];
            [cell stopLoading];
        });
    });
    
    return cell;
}

@end
