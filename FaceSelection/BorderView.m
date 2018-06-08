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



- (UIImage *)imageScaledToFitToSize:(CGSize)size {
    CGRect scaledRect = AVMakeRectWithAspectRatioInsideRect(self.image.size, CGRectMake(0, 0, size.width, size.height));
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [self.image drawInRect:scaledRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

-(void)drawRect:(CGRect)rect{

    if( !self.image ){
        return;
    }

    CGSize cgSize;
    cgSize.height = self.image.size.height;
    cgSize.width = self.image.size.width;
    rect.size.height = rect.size.height/2;
    UIImage *scaledImage =[self imageScaledToFitToSize:cgSize];
    [scaledImage drawInRect:rect];
    
    self.mScaleX = rect.size.width/self.image.size.width;
    self.mScaleY = (rect.size.height)/self.image.size.height;

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
                
                long artop = [top longValue] * self.mScaleY;
                long arwidth = [width longValue] * self.mScaleX;
                long arleft = [left longValue] * self.mScaleX;
                long arheight = [height longValue] * self.mScaleY;
    
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
                                                       CGRectMake([faceLandmarkX floatValue] * self.mScaleX,
                                                                    [faceLandmarkY floatValue] * self.mScaleY,
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

