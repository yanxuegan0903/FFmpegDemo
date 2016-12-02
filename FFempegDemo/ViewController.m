//
//  ViewController.m
//  FFempegDemo
//
//  Created by vsKing on 2016/11/29.
//  Copyright © 2016年 vsKing. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegDecode.h"
#import "TotalDecode.h"



@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) FFmpegDecode * ffmpegDecode;
@end

@implementation ViewController
{
    int _count;
    BOOL _isRuning;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 30, self.view.bounds.size.width, self.view.bounds.size.width*9/16)];
    [self.view addSubview:imageView];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView = imageView;
    
    
    
    UIButton * btn = [[UIButton alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.width+40, 80, 45)];
    [self.view addSubview:btn];
    [btn setBackgroundColor:[UIColor whiteColor]];
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
    _count = 1;

    FFmpegDecode * ffmpegDecode = [[FFmpegDecode alloc]init];
    [ffmpegDecode initH264DecoderWithWidth:1280 height:720 imageView:self.imageView];
    self.ffmpegDecode = ffmpegDecode;
    
    

}

//- (void)clickBtn
//{
//    
//    NSString * path = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"bb%04d.h264",_count] ofType:nil];
//    NSLog(@"path = %@",path);
//    if (!path) {
//        NSLog(@"path 不存在");
//        return;
//    }
//    NSData * data = [NSData dataWithContentsOfFile:path];
//    
//    [self.ffmpegDecode H264decoderWithVideoData:data];
//    
//    _count+=1;
//
////    [ffmpegDecode releaseH264Decoder];
//    
//}





- (void)clickBtn
{
//    dispatch_queue_t queue = dispatch_queue_create("FFmpeg", 0);
//    dispatch_async(queue, ^{
        
        for (int i = 1; i<1383; i++) {
            
            NSString * path = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"bb%04d.h264",i] ofType:nil];
            if (!path) {
                NSLog(@"path 不存在");
                i = 1;
                continue;
            }
            NSLog(@"path = %@",path);
            NSData * data = [NSData dataWithContentsOfFile:path];
            
            [self.ffmpegDecode H264decoderWithVideoData:data];
            usleep(1000*10);
            data = nil;
            path = nil;
            
  
        }

//    });

    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
