//
//  BorderView.h
//  FaceSelection
//
//  Created by Steven Woo on 6/7/18.
//  Copyright © 2018 Curious Kiwi Co. All rights reserved.
//

#ifndef BorderView_h
#define BorderView_h
#import <UIKit/UIKit.h>
@interface BorderView : UIView
// these are all retained by controller
@property (nonatomic, weak) UIImage *image;
@property (nonatomic) CGFloat mScaleX;
@property (nonatomic) CGFloat mScaleY;
@property (nonatomic) CGFloat mImageScale;
@property (nonatomic, weak) NSString *selectedFaceId;
@property (nonatomic, weak) NSArray * mJSONArray;

@end


#endif /* TestView_h */
