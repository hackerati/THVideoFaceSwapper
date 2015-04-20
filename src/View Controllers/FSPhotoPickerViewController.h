//
//  FSPhotoPickerViewController.h
//  videoApp
//
//  Created by Clayton Rieck on 4/8/15.
//
//
//#import "ofMain.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <stdio.h>
//#include "ofApp.h"

@interface FSPhotoPickerViewController : UIViewController

- (instancetype)initWithFaces:(NSArray *)faces;

- (void)presentVC:(BOOL)animated;

@end
