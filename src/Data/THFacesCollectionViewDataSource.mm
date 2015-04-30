//
//  THFacesCollectionViewDataSource.m
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/27/15.
//
//

#include "ofApp.h"

#import "THFacesCollectionViewDataSource.h"
#import "THFacePickerCollectionViewCell.h"
#import "THFacesCollectionReusableView.h"

#import "UIImage+Decode.h"

static NSString *kTHCellReuseIdentifier = @"cell";
static NSString *kTHSupplementaryHeaderViewReuseIdentifier = @"supplementaryHeaderView";

static NSString * const kTHDocumentsDirectoryPath = ofxStringToNSString(ofxiOSGetDocumentsDirectory());
static NSString * const kTHAlphanumericCharacters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
static NSString * const kTHPreInstalledFacesHeaderTitle = @"Pre-Installed Faces";
static NSString * const kTHSavedFacesHeaderTitle = @"Saved Faces";

static const string kTHSavedImagesExtension = ".png";

@interface THFacesCollectionViewDataSource ()
{
    ofApp *mainApp;
}

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic, retain) NSMutableArray *savedFaces;
@property (nonatomic, retain) NSMutableArray *savedVideos;
@property (nonatomic, retain) NSMutableSet *indexPathsToDelete;

@end

@implementation THFacesCollectionViewDataSource

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if ( self ) {
        mainApp = (ofApp *)ofGetAppPtr();
        _collectionView = collectionView;
        [_collectionView registerClass:[THFacePickerCollectionViewCell class] forCellWithReuseIdentifier:kTHCellReuseIdentifier];
        [_collectionView registerClass:[THFacesCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTHSupplementaryHeaderViewReuseIdentifier];
        
        _savedFaces = [[NSMutableArray alloc] init];
        _savedVideos = [[NSMutableArray alloc] init];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kTHDocumentsDirectoryPath error:nil];
        for (NSString *filePath in files) {
            if ( [filePath containsString:@".mov"] ) {
                [_savedVideos addObject:filePath];
            }
            else {
                [_savedFaces addObject:filePath];
            }
        }
        
        _indexPathsToDelete = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    _collectionView = nil;
    _savedFaces = nil;
    _savedVideos = nil;
    _indexPathsToDelete = nil;
    mainApp = NULL;
    [super dealloc];
}

#pragma mark - Public

- (NSInteger)numberOfItemsToDelete
{
    return self.indexPathsToDelete.count;
}

- (void)addIndexPathToDelete:(NSIndexPath *)indexPath
{
    if ( ![self.indexPathsToDelete containsObject:indexPath] ) {
        [self.indexPathsToDelete addObject:indexPath];
    }
}

- (void)removeIndexPathToDelete:(NSIndexPath *)indexPath
{
    if ( [self.indexPathsToDelete containsObject:indexPath] ) {
        [self.indexPathsToDelete removeObject:indexPath];
    }
}

- (void)deleteSelectedItems:(void (^)(void))completion
{
    [self.collectionView performBatchUpdates:^{
        
        NSMutableArray *fileNamesToRemove = [NSMutableArray array];
        NSError *err;
        for (NSIndexPath *path in self.indexPathsToDelete) {
            
            THFacePickerCollectionViewCell *cell = (THFacePickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:path];
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
        [self.collectionView deleteItemsAtIndexPaths:[self.indexPathsToDelete allObjects]];
        
    } completion:^(BOOL finished){
        [self.indexPathsToDelete removeAllObjects];
        if ( completion ) {
            completion();
        }
    }];
}

- (void)addSavedVideoNamed:(NSString *)name
{
    [self.savedVideos addObject:name];
    [self.collectionView reloadSections:[[NSIndexSet alloc] initWithIndex:2]];
}

- (NSString *)movieFromDocumentDirectoryAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = [self.savedVideos objectAtIndex:indexPath.row];
    return [kTHDocumentsDirectoryPath stringByAppendingPathComponent:name];
}

- (NSString *)savedImageNameAtIndexPath:(NSIndexPath *)indexPath
{
    return self.savedFaces[indexPath.row];
}

- (UIImage *)imageFromDocumentsDirectoryNamed:(NSString *)name
{
    NSString *imagePath = [kTHDocumentsDirectoryPath stringByAppendingPathComponent:name];
    return [UIImage imageWithContentsOfFile:imagePath];
}

- (void)loadFace:(UIImage *)image saveImage:(BOOL)save withCompletion:(void (^)(void))completion
{
    dispatch_async(dispatch_queue_create("imageLoadingQueue", NULL), ^{
        
        ofImage pickedImage;
        ofxiOSUIImageToOFImage(image, pickedImage);
        pickedImage.rotate90(1);
        
        if ( save ) {
            NSString *newFileName = [self randomString];
            while ( [self.savedFaces containsObject:newFileName] ) { // ensures that we'll never over write a previous image (highly unlikely anyways)
                newFileName = [self randomString];
            }
            string cStringSavedFaceName = ofxNSStringToString(newFileName) + kTHSavedImagesExtension;
            // Save image to documents directory
            pickedImage.saveImage(ofxiOSGetDocumentsDirectory() + cStringSavedFaceName);
            [self.savedFaces addObject:ofxStringToNSString(cStringSavedFaceName)];
        }
        
        pickedImage.setImageType(OF_IMAGE_COLOR); // set the type AFTER we save image to documents
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            mainApp->loadOFImage(pickedImage);
            mainApp->setupCam([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
            
            [self.collectionView reloadSections:[[NSIndexSet alloc] initWithIndex:1]];
            
            if ( completion ) {
                completion();
            }
        });
    });
}

- (void)resetCellStates
{
    for (NSIndexPath *path in self.indexPathsToDelete) {
        THFacePickerCollectionViewCell *cell = (THFacePickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:path];
        [cell highlightSelected:NO];
    }
    
    [self.indexPathsToDelete removeAllObjects];
}

#pragma mark - Private

- (NSString *)randomString {
    const NSInteger alphanumericLettersCount = [kTHAlphanumericCharacters length];
    
    NSMutableString *randomString = [[NSMutableString alloc] init];
    for (int i = 0; i < 10; i++) {
        [randomString appendFormat: @"%C", [kTHAlphanumericCharacters characterAtIndex: arc4random_uniform(alphanumericLettersCount)]];
    }
    
    return randomString;
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

#pragma mark - UICollectionView Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ( section == 0 ) {
        return mainApp->faces.size();
    }
    else if ( section == 1 ) {
        return self.savedFaces.count;
    }
    else {
        return self.savedVideos.count;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    THFacesCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kTHSupplementaryHeaderViewReuseIdentifier forIndexPath:indexPath];
    
    if ( indexPath.section == 0 ) {
        headerView.title = kTHPreInstalledFacesHeaderTitle;
    }
    else if ( indexPath.section == 1 ) {
        headerView.title = kTHSavedFacesHeaderTitle;
    }
    else {
        headerView.title = @"Saved Videos";
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
        else if ( indexPath.section == 1 ) {
            
            faceImage = [[UIImage imageWithContentsOfFile:[kTHDocumentsDirectoryPath stringByAppendingPathComponent:[self.savedFaces objectAtIndex:indexPath.row]]] decodedImage];
        }
        else {
            // TODO: Get first frame of video or something
            faceImage = [UIImage imageNamed:@"record"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell setFaceWithImage:faceImage atIndexPath:indexPath];
            [cell stopLoading];
        });
    });
    
    return cell;
}

@end
