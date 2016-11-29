//
//  ViewController.m
//  FFempegDemo
//
//  Created by vsKing on 2016/11/29.
//  Copyright © 2016年 vsKing. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegDecode.h"



@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor orangeColor];
    
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 30, self.view.bounds.size.width, self.view.bounds.size.width*9/16)];
    [self.view addSubview:imageView];
    imageView.backgroundColor = [UIColor redColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView = imageView;
    
    
    
    UIButton * btn = [[UIButton alloc]initWithFrame:CGRectMake(0, self.view.bounds.size.width+40, 80, 45)];
    [self.view addSubview:btn];
    [btn setBackgroundColor:[UIColor whiteColor]];
    [btn addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];


}

- (void)clickBtn
{
    __block int count = 0;
    FFmpegDecode * ffmpegDecode = [[FFmpegDecode alloc]init];
    [ffmpegDecode initH264DecoderWithWidth:360 height:640];
    
    for (int i = 0; i<2000; i++) {
        NSString * path = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"Documents%d.txt",i] ofType:nil];
        if (!path) {
            NSLog(@"path 不存在");
            continue;
        }
        NSData * data = [NSData dataWithContentsOfFile:path];

        [ffmpegDecode H264decoderWithVideoData:data completion:^(AVPicture picture) {
            NSLog(@"有数据返回");
            count ++;
        }];
        
        usleep(1000*20);
    }
    NSLog(@"count = %d",count);
    [ffmpegDecode releaseH264Decoder];
    
    
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
