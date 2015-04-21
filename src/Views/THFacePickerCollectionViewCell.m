//
//  THFacePickerCollectionViewCell.m
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/21/15.
//
//

#import "THFacePickerCollectionViewCell.h"

//#include "ofApp.h"

@interface THFacePickerCollectionViewCell ()

@property (nonatomic) UIImageView *faceImageView;
@property (nonatomic) UIActivityIndicatorView *loadingIndicatorView;
@property (nonatomic) NSOperationQueue *imageOperationQueue;

@end

@implementation THFacePickerCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self ) {
        _faceImageView = [[UIImageView alloc] initWithFrame:frame];
        _faceImageView.contentMode = UIViewContentModeScaleAspectFill;
        _faceImageView.center = self.contentView.center;
        [self.contentView addSubview:_faceImageView];
        
        _loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _loadingIndicatorView.center = self.contentView.center;
        [self.contentView addSubview:_loadingIndicatorView];
        
        _imageOperationQueue = [[NSOperationQueue alloc] init];
        _imageOperationQueue.maxConcurrentOperationCount = 1;
        
        self.clipsToBounds = YES;
    }
    
    return self;
}

- (void)startLoading
{
    [self.loadingIndicatorView startAnimating];
    self.loadingIndicatorView.hidden = NO;
}

- (void)stopLoading
{
    [self.loadingIndicatorView stopAnimating];
    self.loadingIndicatorView.hidden = YES;
}

- (void)clearImage
{
    self.faceImageView.image = nil;
}

- (void)setFaceWithImage:(UIImage *)faceImage atIndexPath:(NSIndexPath *)indexPath
{
    if ( [indexPath isEqual:self.currentIndexPath] ) {
        self.faceImageView.image = faceImage;
    }
}

@end
