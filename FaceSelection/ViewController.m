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

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation ViewController
// Image URL: https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family.jpg
// JSON URL: https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family_faces.json
// JSON contents documentation: https://westus.dev.cognitive.microsoft.com/docs/services/563879b61984550e40cbbe8d/operations/563879b61984550f30395236
const unsigned int STATE_IDLE = 0;
const unsigned int STATE_WAITING_FOR_IMAGE = 1;
const unsigned int STATE_WAITING_FOR_JSON = 2;

NSString *const imageUrl = @"https://s3-us-west-2.amazonaws.com/precious-interview/ios-face-selection/family.jpg";
NSString *const placeholder = @"placeholder.png";
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
    NSString *fileName = [NSString stringWithFormat:@"%@/jsonfile.txt",
                          documentsDirectory];
    NSString *content = [mArrayFaceBorders componentsJoinedByString:@","];
    NSLog(@"writing to %@", fileName);
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

- (void)addFaceBorders{
    if( mState == STATE_IDLE){
        NSLog(@"should do something here");
        if( mArrayFaceBorders != nil ){
        }
    }
    else{
        NSLog(@"not ready to add borders");
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];
    self.imageView.image = nil;
    self.textView.text = nil;
    mState = STATE_WAITING_FOR_JSON | STATE_WAITING_FOR_IMAGE;
    SDWebImageManager *sdWebManager = [SDWebImageManager sharedManager];
    [sdWebManager loadImageWithURL:[NSURL URLWithString:imageUrl] options:kNilOptions progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        //
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        if( image != nil && error == nil ){
            mImage = image;
            NSString *filename = [imageURL lastPathComponent];
            [self writeImageFile:filename :image];
            [self updateLoadingState: STATE_WAITING_FOR_IMAGE];
            [self addFaceBorders];
        }
        
        if( error != nil ){
            NSLog(@"Error is %@", error);
        }
        
        
    }];

    AFHTTPSessionManager *afSessionManager = [AFHTTPSessionManager manager];
    [afSessionManager GET:jsonURL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        mArrayFaceBorders = [NSArray arrayWithArray:(NSArray *)responseObject];
        [self writeJSONFile];
        [self updateLoadingState: STATE_WAITING_FOR_JSON];
        [self addFaceBorders];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
