//
//  TotalDecode.m
//  FFempegDemo
//
//  Created by vsKing on 2016/11/30.
//  Copyright © 2016年 vsKing. All rights reserved.
//

#import "TotalDecode.h"
#import "libswscale/swscale.h"
#include <libavformat/avformat.h>
#import <AVFoundation/AVFoundation.h>

#define INBUF_SIZE 4096
#define AUDIO_INBUF_SIZE 20480
#define AUDIO_REFILL_THRESH 4096


#import "AAPLEAGLLayer.h"




@implementation TotalDecode


-(void)initH264Decoder
{
    av_register_all();
    avcodec_register_all();
    
    AVCodec * codec;
    AVCodecContext * c = NULL;
    AVFrame * frame;
    AVPacket avpkt;
    
    av_init_packet(&avpkt);
    codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!codec) {
        NSLog(@"codec init failed");
        return;
    }
    
    c = avcodec_alloc_context3(codec);
    if (!c) {
        NSLog(@"c init failed");
        return;
    }
    
    if (avcodec_open2(c, codec, NULL) >= 0) {
        NSLog(@"avcodec_open2 success");
        frame = av_frame_alloc();// Allocate video frame
        if (frame) {
            NSLog(@"frame alloc success");
        }
    }
    

}




@end
