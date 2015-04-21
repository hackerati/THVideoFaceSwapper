//
//  THFacePickerCollectionViewCell.m
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/21/15.
//
//

#import "THFacePickerCollectionViewCell.h"

@interface THFacePickerCollectionViewCell ()

@property (nonatomic) UIImageView *faceImageView;
@property (nonatomic) UIActivityIndicatorView *loadingIndicatorView;

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
        
        self.clipsToBounds = YES;
    }
    
    return self;
}

#pragma mark - Public

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
