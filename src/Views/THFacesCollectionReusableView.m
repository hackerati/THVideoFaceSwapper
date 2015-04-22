//
//  THFacesCollectionReusableView.m
//  THVideoFaceSwapper
//
//  Created by Clayton Rieck on 4/22/15.
//
//

#import "THFacesCollectionReusableView.h"

@interface THFacesCollectionReusableView ()

@property (nonatomic) UILabel *titleLabel;

@end

@implementation THFacesCollectionReusableView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self ) {
        _titleLabel = [[UILabel alloc] initWithFrame:frame];
        _titleLabel.font = [UIFont systemFontOfSize:20.0f];
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

@end
