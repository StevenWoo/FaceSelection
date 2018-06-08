//
//  ViewController.m
//  FaceSelection
//
//  Created by Daniel Lau on 4/26/18.
//  Copyright © 2018 Curious Kiwi Co. All rights reserved.
//
#import <SDWebImage/SDWebImageManager.h>
#import <AFNetworking/AFNetworking.h>

#import "ViewController.h"
#import "BorderView.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet BorderView *borderView;

@end

@implementation ViewController
// Image URL: https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family.jpg
// JSON URL: https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family_faces.json
// JSON contents documentation: https://westus.dev.cognitive.microsoft.com/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236
const unsigned int STATE_IDLE = 0;
const unsigned int STATE_WAITING_FOR_IMAGE = 1;
const unsigned int STATE_WAITING_FOR_JSON = 2;
const unsigned int STATE_FAILED_JSON = 4;
const unsigned int STATE_FAILED_IMAGE = 8;

NSString *const imageUrl = @"https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family.jpg";
NSString *const jsonURL = @"https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family_faces.json";
unsigned int mState;
NSArray *mArrayFaceBorders = nil;
UIImage *mImage = nil;

// some helper functions to write data out to disk
-(NSString*)getDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}
-(void) writeJSONFile{
    if( mArrayFaceBorders == nil ){
        return;
    }
    //get the documents directory:
    NSString *documentsDirectory = [self getDocumentsDirectory];
    NSString *fileName = [NSString stringWithFormat:@"%@/face_metadata.json",
                          documentsDirectory];
    NSString *content = [mArrayFaceBorders componentsJoinedByString:@","];
    NSLog(@"writing json to %@", fileName);
    [content writeToFile:fileName
              atomically:NO
                encoding:NSUTF8StringEncoding
                   error:nil];
}
-(void)writeImageFile :(NSString*)filename :(UIImage*)image{
    //get the documents directory:
    NSString *documentsDirectory = [self getDocumentsDirectory];
    
    NSString *imageFile =[NSString stringWithFormat:@"%@/%@", documentsDirectory, filename];
    [UIImagePNGRepresentation(image) writeToFile:imageFile atomically:YES];
    NSLog(@"writing image to %@", imageFile);

}


- (void)updateLoadingState :(unsigned int)clearBit  {
    @synchronized(self){
        mState &= ~(clearBit);
        if( mState == STATE_IDLE ){
            [self.loadingIndicator stopAnimating];
            self.loadingIndicator.hidden = YES;
        }
    }
}

- (void)setErrorState:(unsigned int) clearBit :(unsigned int) setBit {
    @synchronized(self){
        mState &= setBit;
        mState &= ~(clearBit);
    }
}

- (void)clearErrorState:(unsigned int) clearBit :(unsigned int) setBit {
    @synchronized(self){
        mState &= setBit;
        mState &= ~(clearBit);
    }
}



- (void)addFaceBorders{
    if( mState == STATE_IDLE){
        if( mArrayFaceBorders != nil ){
            if( self.borderView != nil ){
                self.borderView.mJSONArray = mArrayFaceBorders;
                [self.borderView setNeedsDisplay];
            }
        }
    }
    else{
        NSLog(@"not ready to add borders");
    }
}

- (void)downloadImage {
    SDWebImageManager *sdWebManager = [SDWebImageManager sharedManager];
    [sdWebManager loadImageWithURL:[NSURL URLWithString:imageUrl] options:kNilOptions progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        //
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if( image != nil && error == nil ){
            mImage = image;
// don't use name on server, use specified filename
//            NSString *filename = [imageURL lastPathComponent];
            [self writeImageFile:@"image.jpg" :image];
            [self updateLoadingState: STATE_WAITING_FOR_IMAGE];
            [self addFaceBorders];
            self.borderView.image = image;
            [self.borderView setNeedsDisplay];
        }
        
        if( error != nil ){
            NSLog(@"Error download image is %@", error);
            [self setErrorState:STATE_WAITING_FOR_IMAGE :STATE_FAILED_IMAGE];
        }
    }];

}
- (void)downloadJSON {
    AFHTTPSessionManager *afSessionManager = [AFHTTPSessionManager manager];
    [afSessionManager GET:jsonURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        mArrayFaceBorders = [NSArray arrayWithArray:(NSArray *)responseObject];
        [self writeJSONFile];
        [self updateLoadingState: STATE_WAITING_FOR_JSON];
        [self addFaceBorders];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error getting json: %@", error);
        [self setErrorState:STATE_WAITING_FOR_JSON :STATE_FAILED_JSON];
    }];
}

- (void)checkRetryQueue {
    // this gets called before the file downloads can fail in most ways
    // so nothing happens
    // nothing very sophisticated for test app
    // but would possibly have UI for letting user
    // retry more times or stop trying
    if( mState &= STATE_FAILED_JSON){
        [self clearErrorState:STATE_FAILED_JSON :STATE_WAITING_FOR_JSON];
        [self downloadJSON];
    }
    if( mState &= STATE_FAILED_IMAGE){
        [self clearErrorState:STATE_FAILED_IMAGE :STATE_WAITING_FOR_IMAGE];
        [self downloadImage];
    }
}

- (void) setState:(unsigned int) newState {
    @synchronized(self){
        mState = newState;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];
    self.borderView.image = nil;
    self.borderView.mJSONArray = nil;
    self.borderView.selectedFaceId = nil;
    self.textView.text = nil;
    [self setState:STATE_WAITING_FOR_JSON | STATE_WAITING_FOR_IMAGE];
    [self downloadImage];
    [self downloadJSON];
    [self checkRetryQueue];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [self.textView setContentOffset:CGPointZero animated:NO];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if( mArrayFaceBorders == nil ){
        return;
    }
    if( self.borderView.image != nil && mArrayFaceBorders != nil){
        NSString *oldSelectedFaceId = self.borderView.selectedFaceId;
        self.borderView.selectedFaceId = nil;
        for(UITouch * touch in touches){
            CGPoint location = [touch locationInView:touch.view];
            for( NSDictionary *dictJSON in mArrayFaceBorders){
                NSDictionary *faceRectangle = [dictJSON objectForKey:@"faceRectangle"];
                if( faceRectangle != nil ){
                    NSNumber *top = [faceRectangle objectForKey:@"top"];
                    NSNumber *width = [faceRectangle objectForKey:@"width"];
                    NSNumber *left = [faceRectangle objectForKey:@"left"];
                    NSNumber *height = [faceRectangle objectForKey:@"height"];
                    
                    long artop = [top longValue] * self.borderView.mScaleY;
                    long arwidth = [width longValue] * self.borderView.mScaleX;
                    long arleft = [left longValue] * self.borderView.mScaleX;
                    long arheight = [height longValue] * self.borderView.mScaleY;
                    if( location.y >= artop && location.y < artop + arheight &&
                       location.x >= arleft && location.x < arleft + arwidth){
                        NSString *newSelectedFaceId = [dictJSON objectForKey:@"faceId"];
                        // change of selection if inside
                        if( newSelectedFaceId != oldSelectedFaceId ){
                            self.borderView.selectedFaceId = newSelectedFaceId;
                            NSDictionary *dictAttributes = [dictJSON objectForKey:@"faceAttributes"];
                            NSDictionary *emotions = [dictAttributes objectForKey:@"emotion"];
                            long maxEmotion = -1;
                            NSString *printEmotion = @"none";
                            for(id key in  emotions){
                                NSNumber *value = [emotions objectForKey:key];
                                if( [value longValue] > maxEmotion ){
                                    printEmotion = key;
                                    maxEmotion = [value longValue];
                                }
                            }
                            float percent = 100.0f * [width floatValue] * [height floatValue] / (self.borderView.image.size.height * self.borderView.image.size.width);
                            NSString *outputString = [NSString stringWithFormat:
                                                      @"Gender: %@ \nAge: %@\nMost confident emotion: %@\nRatio of face to photo: %.01f",
                                                      [dictAttributes objectForKey:@"gender"], [dictAttributes objectForKey:@"age"], printEmotion, percent];
                            self.textView.text = outputString;
                        }
                        // clear selection if inside same box as prior
                        else{
                            self.borderView.selectedFaceId = nil;
                            self.textView.text = @"";
                        }
                    }
                    
                }
            }
        }
        // force redraw if change
        if( oldSelectedFaceId != self.borderView.selectedFaceId){
            [self.borderView setNeedsDisplay];
        }
    }
}

- (void)dealloc {
    mArrayFaceBorders = nil;
    mImage = nil;
}
@end
