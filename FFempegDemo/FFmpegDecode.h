//
//  FFmpegDecode.h
//  FFempegDemo
//
//  Created by vsKing on 2016/11/29.
//  Copyright © 2016年 vsKing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "libavcodec/avcodec.h"

@interface FFmpegDecode : NSObject

/* 初始化解码器 */
- (BOOL)initH264DecoderWithWidth:(int)width height:(int)height;

/* 解码视频数据并且返回图片 */
- (void)H264decoderWithVideoData:(NSData *)VideoData completion:(void (^)(AVPicture picture))completion;

/* 释放解码器 */
- (void)releaseH264Decoder;



@end
