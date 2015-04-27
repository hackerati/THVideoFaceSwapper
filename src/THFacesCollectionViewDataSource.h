//
//  THFacesCollectionViewDataSource.h
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/27/15.
//
//

#include <stdio.h>

@interface THFacesCollectionViewDataSource : NSObject <UICollectionViewDataSource>

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView;

- (NSInteger)numberOfItemsToDelete;
- (void)addIndexPathToDelete:(NSIndexPath *)indexPath;
- (void)removeIndexPathToDelete:(NSIndexPath *)indexPath;
- (void)deleteSelectedItems:(void (^)(void))completion;

- (NSString *)savedImageNameAtIndexPath:(NSIndexPath *)indexPath;
- (UIImage *)imageFromDocumentsDirectoryNamed:(NSString *)name;

- (void)loadFace:(UIImage *)image saveImage:(BOOL)save withCompletion:(void (^)(void))completion;

- (void)resetCellStates;

@end
