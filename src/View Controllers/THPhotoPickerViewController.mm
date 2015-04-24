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

static NSString * const kTHAlphanumericCharacters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

static NSString *kTHCellReuseIdentifier = @"cell";
static NSString *kTHSupplementaryHeaderViewReuseIdentifier = @"supplementaryHeaderView";
static NSString *kTHDocumentsDirectoryPath = ofxStringToNSString(ofxiOSGetDocumentsDirectory());
static NSArray *kTHLoadingDetails = @[@"You're gonna look great!", @"Ooo how handsome", @"Your alias is on the way!", @"Better than Mrs. Doubtfire"];

static const CGSize kTHCellSize = (CGSize){100.0f, 100.0f};
static const CGFloat kTHItemSpacing = 2.0f;

@interface THPhotoPickerViewController ()
<UIAlertViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate>
{
    ofApp *mainApp;
}

@property (nonatomic) UICollectionView *facesCollectionView;
@property (nonatomic) NSMutableArray *savedFaces;
@property (nonatomic) NSMutableSet *indexPathsToDelete;
@property (nonatomic) UIButton *deleteButton;
@property (nonatomic) UIImage *takenPhoto;

@end

@implementation THPhotoPickerViewController

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        mainApp = (ofApp *)ofGetAppPtr();
        
        _savedFaces = (NSMutableArray *)[[[NSFileManager defaultManager] contentsOfDirectoryAtPath:kTHDocumentsDirectoryPath error:nil] mutableCopy];
        _indexPathsToDelete = [[NSMutableSet alloc] init];
        
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

- (void)setupDeleteButton
{
    const CGFloat viewWidth = self.view.frame.size.width;
    const CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    _deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, viewWidth, navBarHeight)];
    [_deleteButton addTarget:self action:@selector(deleteSelectedItems) forControlEvents:UIControlEventTouchUpInside];
    _deleteButton.backgroundColor = [UIColor colorWithRed:0.9f green:0.3f blue:0.26f alpha:1.0f];
    [_deleteButton setTitle:@"Delete Item" forState:UIControlStateNormal];
    _deleteButton.transform = CGAffineTransformMakeTranslation(0.0f, -navBarHeight);
    _deleteButton.hidden = YES;
    [self.navigationController.navigationBar addSubview:_deleteButton];
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
    longPress.minimumPressDuration = 0.5f;
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupDeleteButton];
}

#pragma mark - Private

- (void)dismissVC
{
    [self resetCellStates];
    
    mainApp->setupCam([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

- (void)presentCameraPicker
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self.navigationController presentViewController:imagePicker animated:YES completion:nil];
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

- (void)loadFace:(UIImage *)image saveImage:(BOOL)save withCompletion:(void (^)(void))completion
{
    [self showLoadingHUD];
    
    dispatch_async(dispatch_queue_create("imageLoadingQueue", NULL), ^{
        
        ofImage pickedImage;
        ofxiOSUIImageToOFImage(image, pickedImage);
        pickedImage.rotate90(1);
        
        if ( save ) {
            NSString *newFileName = [self randomString];
            while ( [self.savedFaces containsObject:newFileName] ) { // ensures that we'll never over write a previous image (highly unlikely anyways)
                newFileName = [self randomString];
            }
            string cStringSavedFaceName = ofxNSStringToString(newFileName) + ".png";
            // Save image to documents directory
            pickedImage.saveImage(ofxiOSGetDocumentsDirectory() + cStringSavedFaceName);
            [self.savedFaces addObject:ofxStringToNSString(cStringSavedFaceName)];
        }
        
        pickedImage.setImageType(OF_IMAGE_COLOR); // set the type AFTER we save image to documents
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            mainApp->loadOFImage(pickedImage);
            mainApp->setupCam(self.view.frame.size.width, self.view.frame.size.height);
            
            [self.facesCollectionView reloadSections:[[NSIndexSet alloc] initWithIndex:1]];
            self.takenPhoto = nil; // manual release
            
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

- (void)showDeleteButton:(BOOL)show
{
    CGAffineTransform targetTransform;
    if ( show ) {
        [self.deleteButton setHidden:!show];
        targetTransform = CGAffineTransformMakeTranslation(0.0f, 0.0f);
    }
    else {
        targetTransform = CGAffineTransformMakeTranslation(0.0f, -self.navigationController.navigationBar.frame.size.height);
    }
    
    [UIView animateWithDuration:0.1f
                     animations:^{
                         self.deleteButton.transform = targetTransform;
                     }
                     completion:^(BOOL finished){
                         [self.deleteButton setHidden:!show];
                     }];
}

- (NSString *)randomString {
    const NSInteger alphanumericLettersCount = [kTHAlphanumericCharacters length];
    
    NSMutableString *randomString = [[NSMutableString alloc] init];
    for (int i = 0; i < 10; i++) {
        [randomString appendFormat: @"%C", [kTHAlphanumericCharacters characterAtIndex: arc4random_uniform(alphanumericLettersCount)]];
    }
    
    return randomString;
}

- (void)resetCellStates
{
    for (NSIndexPath *path in self.indexPathsToDelete) {
        THFacePickerCollectionViewCell *cell = (THFacePickerCollectionViewCell *)[self.facesCollectionView cellForItemAtIndexPath:path];
        [cell highlightSelected:NO];
    }
    
    [self.indexPathsToDelete removeAllObjects];
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.takenPhoto = (UIImage *)[info[UIImagePickerControllerOriginalImage] copy]; // need to copy or else you'll try to load the reference to the image which will be deallocated outside of this scope
    
    mainApp->cam.close();
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Save Photo For Later?"
                                                        message:@"Saving will allow you to use this face later on"
                                                       delegate:self
                                              cancelButtonTitle:@"No Thanks"
                                              otherButtonTitles:@"Right On!", nil];
    [alertView show];
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
            
            faceImage = [[UIImage imageWithContentsOfFile:[kTHDocumentsDirectoryPath stringByAppendingPathComponent:[self.savedFaces objectAtIndex:indexPath.row]]] decodedImage];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell setFaceWithImage:faceImage atIndexPath:indexPath];
            [cell stopLoading];
        });
    });
    
    return cell;
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    BOOL save = NO;
    if ( buttonIndex == 1 ) {
        save = YES;
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [self loadFace:self.takenPhoto saveImage:save withCompletion:^{
            [self dismissVC];
        }];
    }];
}

#pragma mark - UIGestureRecognizer Selectors

- (void)longPress:(UIGestureRecognizer *)gesture
{
    switch ( gesture.state ) {
        case UIGestureRecognizerStateBegan: {
            CGPoint gesturePoint = [gesture locationInView:self.facesCollectionView];
            NSIndexPath *pointIndexPath = [self.facesCollectionView indexPathForItemAtPoint:gesturePoint];
            
            if ( pointIndexPath ) {
                
                if ( pointIndexPath.section == 1 ) { // should only be able to delete saved images taken via camera
                    
                    THFacePickerCollectionViewCell *selectedCell = (THFacePickerCollectionViewCell *)[self.facesCollectionView cellForItemAtIndexPath:pointIndexPath];
                    [selectedCell highlightSelected:!selectedCell.highlightSelected];
                    
                    if ( selectedCell.highlightSelected ) {
                        [self.indexPathsToDelete addObject:pointIndexPath];
                    }
                    else {
                        if ( [self.indexPathsToDelete containsObject:pointIndexPath] ) {
                            [self.indexPathsToDelete removeObject:pointIndexPath];
                        }
                    }
                    
                    if ( self.indexPathsToDelete.count > 0 ) {
                        
                        if ( self.indexPathsToDelete.count > 1 ) {
                            [self.deleteButton setTitle:@"Delete Items" forState:UIControlStateNormal];
                        }
                        else {
                            [self.deleteButton setTitle:@"Delete Item" forState:UIControlStateNormal];
                        }
                        
                        if ( self.deleteButton.isHidden ) {
                            [self showDeleteButton:YES];
                        }
                    }
                    else {
                        if ( !self.deleteButton.isHidden ) {
                            [self showDeleteButton:NO];
                        }
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

#pragma mark - UIButton Selectors

- (void)deleteSelectedItems
{
    [self.facesCollectionView performBatchUpdates:^{
        
        NSMutableArray *fileNamesToRemove = [NSMutableArray array];
        NSError *err;
        for (NSIndexPath *path in self.indexPathsToDelete) {
            
            THFacePickerCollectionViewCell *cell = (THFacePickerCollectionViewCell *)[self.facesCollectionView cellForItemAtIndexPath:path];
            [cell highlightSelected:NO];
            
            [fileNamesToRemove addObject:[self.savedFaces objectAtIndex:path.row]];
            NSString *fileToDelete = [kTHDocumentsDirectoryPath stringByAppendingPathComponent:[self.savedFaces objectAtIndex:path.row]];
            
            if ( ![[NSFileManager defaultManager] removeItemAtPath:fileToDelete error:&err] ) {
                
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"File Save Error"
                                                                     message:err.localizedDescription
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil, nil];
                [errorAlert show];
            }
        }
        
        [self.savedFaces removeObjectsInArray:fileNamesToRemove];
        [self.facesCollectionView deleteItemsAtIndexPaths:[self.indexPathsToDelete allObjects]];
        
    } completion:^(BOOL finished){
        [self.indexPathsToDelete removeAllObjects];
        [self showDeleteButton:NO];
    }];
}

@end
