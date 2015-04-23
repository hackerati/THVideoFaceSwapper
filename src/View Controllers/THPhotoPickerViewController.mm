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
#import "THFacesCollectionReusableView.h"
#import "MBProgressHUD.h"

#import "UIImage+Decode.h"

static NSString *kTHCellReuseIdentifier = @"cell";
static NSString *kTHSupplementaryHeaderViewReuseIdentifier = @"supplementaryHeaderView";
static NSString *kTHDocumentsDirectoryPath = ofxStringToNSString(ofxiOSGetDocumentsDirectory());
static NSArray *kTHLoadingDetails = @[@"You're gonna look great!", @"Ooo how handsome", @"Your alias is on the way!", @"Better than Mrs. Doubtfire"];

static const CGSize kTHCellSize = (CGSize){100.0f, 100.0f};
static const CGFloat kTHItemSpacing = 2.0f;

@interface THPhotoPickerViewController ()
<UICollectionViewDataSource,
UICollectionViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate>
{
    ofApp *mainApp;
}

@property (nonatomic) UICollectionView *facesCollectionView;
@property (nonatomic) NSMutableArray *savedFaces;

@end

@implementation THPhotoPickerViewController

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        mainApp = (ofApp *)ofGetAppPtr();
        
        _savedFaces = (NSMutableArray *)[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:kTHDocumentsDirectoryPath error:nil] mutableCopy];

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
    const UIEdgeInsets collectionViewInsets = UIEdgeInsetsMake(0.0f, 8.0f, 8.0f, 8.0f);
    const CGSize headerViewSize = CGSizeMake(self.view.frame.size.width, 30.0f);
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.headerReferenceSize = headerViewSize;
    flowLayout.itemSize = kTHCellSize;
    flowLayout.minimumInteritemSpacing = kTHItemSpacing;
    flowLayout.minimumLineSpacing = kTHItemSpacing;
    
    UICollectionView *facesCollectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
    [facesCollectionView registerClass:[THFacePickerCollectionViewCell class] forCellWithReuseIdentifier:kTHCellReuseIdentifier];
    [facesCollectionView registerClass:[THFacesCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTHSupplementaryHeaderViewReuseIdentifier];
    facesCollectionView.backgroundColor = [UIColor whiteColor];
    facesCollectionView.contentInset = collectionViewInsets;
    facesCollectionView.delegate = self;
    facesCollectionView.dataSource = self;
    [self.view addSubview:facesCollectionView];
    _facesCollectionView = facesCollectionView;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPress.minimumPressDuration = 1.0f;
    longPress.numberOfTouchesRequired = 1;
    longPress.delaysTouchesBegan = YES; // prevent didHighlightItemAtIndexPath from being called first
    [_facesCollectionView addGestureRecognizer:longPress];
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

#pragma mark - Private

- (void)dismissVC
{
    mainApp->setupCam([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
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
        pickedImage.rotate90(1);
        
        NSInteger imageNumber;
        if ( self.savedFaces.count <= 0 ) {
            imageNumber = 0;
        }
        else {
            imageNumber = self.savedFaces.count;
        }
        NSString *savedFaceName = [NSString stringWithFormat:@"%zd", imageNumber];
        string cStringSavedFaceName = ofxNSStringToString(savedFaceName) + ".png";
        // Save image to documents directory
        pickedImage.saveImage(ofxiOSGetDocumentsDirectory() + cStringSavedFaceName);
        [self.savedFaces addObject:ofxStringToNSString(cStringSavedFaceName)];
        
        pickedImage.setImageType(OF_IMAGE_COLOR); // set the type AFTER we save image to documents
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            mainApp->loadOFImage(pickedImage);
            mainApp->setupCam(self.view.frame.size.width, self.view.frame.size.height);
            
            [self.facesCollectionView reloadSections:[[NSIndexSet alloc] initWithIndex:1]];
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

- (UIImage *)imageFromDocumentsDirectoryNamed:(NSString *)name
{
    NSString *imagePath = [kTHDocumentsDirectoryPath stringByAppendingPathComponent:name];
    return [UIImage imageWithContentsOfFile:imagePath];
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
            if ( indexPath.section == 0 ) {
                mainApp->loadFace(mainApp->faces.getPath(indexPath.row));
            }
            else {
                NSString *imageName = self.savedFaces[indexPath.row];
                ofImage savedImage;
                ofxiOSUIImageToOFImage([self imageFromDocumentsDirectoryNamed:imageName], savedImage);
                mainApp->loadOFImage(savedImage);
            }
            
            [self dismissVC];
        });
    });
}

#pragma mark - UICollectionView Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ( section == 0 ) {
        return mainApp->faces.size();
    }
    else {
        return self.savedFaces.count;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    THFacesCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kTHSupplementaryHeaderViewReuseIdentifier forIndexPath:indexPath];
    
    if ( indexPath.section == 0 ) {
        headerView.title = @"Pre-Installed Faces";
    }
    else {
        headerView.title = @"Saved Faces";
    }
    
    return headerView;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    THFacePickerCollectionViewCell *cell = (THFacePickerCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kTHCellReuseIdentifier forIndexPath:indexPath];

    cell.currentIndexPath = indexPath;
    [cell clearImage];
    [cell startLoading];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *faceImage;
        if ( indexPath.section == 0 ) {
            ofImage preInstalledImage;
            preInstalledImage.loadImage(mainApp->faces.getPath(indexPath.row));
            faceImage = uiimageFromOFImage(preInstalledImage);
        }
        else {
            NSString *currentImage = [NSString stringWithFormat:@"%zd", indexPath.row];
            faceImage = [[UIImage imageWithContentsOfFile:[kTHDocumentsDirectoryPath stringByAppendingPathComponent:currentImage]] decodedImage];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell setFaceWithImage:faceImage atIndexPath:indexPath];
            [cell stopLoading];
        });
    });
    
    return cell;
}

- (void)longPress:(UIGestureRecognizer *)gesture
{
    switch ( gesture.state ) {
        case UIGestureRecognizerStateBegan: {
            CGPoint gesturePoint = [gesture locationInView:self.facesCollectionView];
            NSIndexPath *pointIndexPath = [self.facesCollectionView indexPathForItemAtPoint:gesturePoint];
            
            if ( pointIndexPath ) {
                
                if ( pointIndexPath.section == 1 ) { // should only be able to delete saved images taken via camera
                    NSLog(@"Long Pressed!!");
                    
                    THFacePickerCollectionViewCell *selectedCell = (THFacePickerCollectionViewCell *)[self.facesCollectionView cellForItemAtIndexPath:pointIndexPath];
                    [selectedCell highlightSelected:!selectedCell.highlightSelected];
                    
                    if ( selectedCell.highlightSelected ) {
                        // TODO: Add to array of items to delete
                    }
                    else {
                        // TODO: Remove from array of items to delete
                    }
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateChanged:
        default:
            break;
    }
}

@end
