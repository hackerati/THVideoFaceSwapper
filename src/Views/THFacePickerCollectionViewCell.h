//
//  THFacePickerCollectionViewCell.h
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/21/15.
//
//

@interface THFacePickerCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) NSIndexPath *currentIndexPath;

- (void)startLoading;
- (void)stopLoading;
- (void)clearImage;
- (void)setFaceWithImage:(UIImage *)faceImage atIndexPath:(NSIndexPath *)indexPath;

@end
