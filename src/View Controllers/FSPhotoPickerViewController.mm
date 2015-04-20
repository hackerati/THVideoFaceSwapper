//
//  FSPhotoPickerViewController.m
//  videoApp
//
//  Created by Clayton Rieck on 4/8/15.
//
//

#import "FSPhotoPickerViewController.h"
#include "ofApp.h"

#import "MBProgressHUD.h"

static NSString *kFSCellReuseIdentifier = @"cell";
static NSArray *kFSLoadingDetails = @[@"You're gonna look great!", @"Ooo how handsome", @"Your alias is on the way!", @"Funnier than Mrs. Doubtfire"];

static const CGFloat kFSAnimationDuration = 0.3f;

@interface FSPhotoPickerViewController ()
<UICollectionViewDataSource,
UICollectionViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate>
{
    ofApp *mainApp;
}

@property (strong, nonatomic) NSArray *facesArray;
@property (strong, nonatomic) NSString *currentFacePath;
@property (strong, nonatomic) NSCache *faceCache;
@property (nonatomic) UICollectionView *facesCollectionView;

@end

@implementation FSPhotoPickerViewController

- (instancetype)initWithFaces:(NSArray *)faces
{
    self = [super init];
    if ( self ) {
        mainApp = (ofApp *)ofGetAppPtr();
        _faceCache = [[NSCache alloc] init];
        _currentFacePath = @"";
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
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    UICollectionView *facesCollectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
    [facesCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kFSCellReuseIdentifier];
    facesCollectionView.backgroundColor = [UIColor whiteColor];
    facesCollectionView.delegate = self;
    facesCollectionView.dataSource = self;
    [self.view addSubview:facesCollectionView];
    self.facesCollectionView = facesCollectionView;
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

- (void)presentVC:(BOOL)animated
{
    const CGFloat targetAlpha = 1.0f;
    CGFloat animationDuration;
    if ( animated ) {
        animationDuration = kFSAnimationDuration;
    }
    else {
        animationDuration = 0.0f;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.view.alpha = targetAlpha;
    }];
}

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

- (NSString *)currentFace
{
    return self.currentFacePath;
}

- (string)currentFaceCString
{
    return string([self.currentFacePath UTF8String]);
}

- (NSString *)randomLoadingDetail
{
    const NSInteger lowerBound = 0;
    const NSInteger upperBound = kFSLoadingDetails.count;
    const NSInteger randomPosition = lowerBound + arc4random() % (upperBound - lowerBound);
    return kFSLoadingDetails[randomPosition];
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
            if ( completion ) {
                completion();
            }
        });
    });
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
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFSCellReuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor yellowColor];
    return cell;
}

@end
