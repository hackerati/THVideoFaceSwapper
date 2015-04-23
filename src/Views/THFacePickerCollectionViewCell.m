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
@property (nonatomic) UIView *selectedView;

@property (nonatomic, assign, readwrite) BOOL highlightSelected;

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
        
        _selectedView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height)];
        _selectedView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.8f];
        _selectedView.layer.borderColor = [UIColor whiteColor].CGColor;
        _selectedView.layer.borderWidth = 3.0f;
        _selectedView.alpha = 0.0f;
        [self.contentView addSubview:_selectedView];
        
        _highlightSelected = NO;
        
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

- (void)highlightSelected:(BOOL)highlight
{
    self.highlightSelected = highlight;
    
    CGFloat targetAlhpa;
    if ( highlight ) {
        targetAlhpa = 1.0f;
    }
    else {
        targetAlhpa = 0.0f;
    }
    
    [UIView animateWithDuration:0.1f animations:^{
        self.selectedView.alpha = targetAlhpa;
    }];
}

@end
