//
//  THFacePickerCollectionViewCell.h
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/21/15.
//
//

@interface THFacePickerCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (nonatomic, assign, readonly) BOOL highlightSelected;;

- (void)startLoading;
- (void)stopLoading;
- (void)clearImage;
- (void)highlightSelected:(BOOL)highlight;
- (void)setFaceWithImage:(UIImage *)faceImage atIndexPath:(NSIndexPath *)indexPath;

@end
