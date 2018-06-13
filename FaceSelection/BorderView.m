//
//  BorderView.m
//  FaceSelection
//
//  Created by Steven Woo on 6/7/18.
//  Copyright © 2018 Curious Kiwi Co. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "BorderView.h"

@interface BorderView()
@end

@implementation BorderView


- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
- (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height {
    CGFloat oldWidth = image.size.width;
    CGFloat oldHeight = image.size.height;
    
    //
    _mImageScaleV1 = (oldWidth < oldHeight) ? width / oldWidth : height / oldHeight;
    NSLog(@"mImageScale set to %f", _mImageScale);
    CGFloat newHeight = oldHeight * _mImageScale;
    CGFloat newWidth = oldWidth * _mImageScale;
    CGSize newSize = CGSizeMake(newWidth, newHeight);
    
    return [self imageWithImage:image scaledToSize:newSize];
}


-(void)drawRect:(CGRect)rect{

    if( !self.image ){
        return;
    }

    CGSize cgSize;
    cgSize.height = self.image.size.height;
    cgSize.width = self.image.size.width;
    rect.size.height = rect.size.height/2;
    
    CGFloat aspectRatioView = rect.size.height/rect.size.width;
    CGFloat aspectRatioSource = cgSize.height/cgSize.width;
    // view is taller than source
    // so we can draw the full width of image into view
    // and scale the height of image and leave some of the view empty along y axis
    CGSize testSize;
    if( aspectRatioView > aspectRatioSource ){
        _mImageScale = rect.size.width/cgSize.width;
        testSize.width = rect.size.width;
        testSize.height = _mImageScale * cgSize.height;
    }
    else {
        _mImageScale = rect.size.height/cgSize.height;
        testSize.width = _mImageScale * cgSize.width;
        testSize.height = rect.size.height;
    }
    UIImage *scaledImage = [self imageWithImage:self.image scaledToSize:testSize];
//    UIImage *scaledImage =[self imageWithImage:self.image scaledToMaxWidth:rect.size.width maxHeight:rect.size.height];
    CGRect imageRect = CGRectMake(0, 0, scaledImage.size.width, scaledImage.size.height);
    [scaledImage drawInRect:imageRect];
    

    if( _mJSONArray != nil ){
        CGContextRef context = UIGraphicsGetCurrentContext ();
        for( NSDictionary *dictJSON in _mJSONArray){
            
            NSDictionary *faceAttributes = [dictJSON objectForKey:@"faceAttributes"];
            NSDictionary *faceRectangle = [dictJSON objectForKey:@"faceRectangle"];
            
            if( faceAttributes != nil && faceRectangle != nil ){
                
                NSString *gender =  [faceAttributes objectForKey:@"gender"];
                if( [gender isEqualToString:@"male"]){
                    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
                }
                else{
                    UIColor *colorPink = [UIColor colorWithRed:1.0f green:0.82f blue:0.92f alpha:1.0f];
                    CGContextSetStrokeColorWithColor(context, colorPink.CGColor);
                }
    
                NSNumber *top = [faceRectangle objectForKey:@"top"];
                NSNumber *width = [faceRectangle objectForKey:@"width"];
                NSNumber *left = [faceRectangle objectForKey:@"left"];
                NSNumber *height = [faceRectangle objectForKey:@"height"];

                CGFloat lineWidth = 2.0f;
                NSString *faceId = [dictJSON objectForKey:@"faceId"];
                BOOL drawLandmarks = FALSE;
                if( self.selectedFaceId != nil && [self.selectedFaceId isEqualToString:faceId]){
                    lineWidth = 5.0f;
                    drawLandmarks = TRUE;
                }
                CGContextSetLineWidth(context, lineWidth);
                
                long artop = _mImageScale * [top longValue];
                long arwidth = _mImageScale * [width longValue];
                long arleft = _mImageScale * [left longValue] ;
                long arheight = _mImageScale * [height longValue];
    
                CGContextMoveToPoint(context, arleft, artop); //start at this point
                
                CGContextAddLineToPoint(context,  arwidth+arleft + lineWidth/2, artop); //draw to this point

                CGContextMoveToPoint(context, arwidth+arleft, artop); //start at this point
                
                CGContextAddLineToPoint(context, arwidth+arleft ,artop+arheight + lineWidth/2); //draw to this point

                CGContextMoveToPoint(context, arwidth+arleft, artop+arheight); //start at this point
                
                CGContextAddLineToPoint(context, arleft - lineWidth/2, artop+arheight); //draw to this point

                CGContextMoveToPoint(context, arleft, artop+arheight); //start at this point
                
                CGContextAddLineToPoint(context, arleft, artop -lineWidth/2); //draw to this point

                CGContextStrokePath(context);
                
                if( drawLandmarks == TRUE ){
                    NSDictionary *faceLandmarks = [dictJSON objectForKey:@"faceLandmarks"];
                    if( faceLandmarks != nil ){
                        
                        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
                        CGContextSetFillColorWithColor(context, [UIColor greenColor].CGColor);
                        for( id key in faceLandmarks){
                            
                            NSDictionary *coordinate = [faceLandmarks objectForKey:key];
                            NSNumber *faceLandmarkX = [coordinate objectForKey:@"x"];
                            NSNumber *faceLandmarkY = [coordinate objectForKey:@"y"];
                            
                            CGContextFillEllipseInRect(context,
                                                       CGRectMake([faceLandmarkX floatValue] * self.mImageScale,
                                                                    [faceLandmarkY floatValue] * self.mImageScale,
                                                                    2.0f,2.0f));
                        }
                    }
                }
            }
        }
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

@end

