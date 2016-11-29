//
//  FFmpegDecode.m
//  FFempegDemo
//
//  Created by vsKing on 2016/11/29.
//  Copyright © 2016年 vsKing. All rights reserved.
//

#import "FFmpegDecode.h"

#import "libswscale/swscale.h"
#include <libavformat/avformat.h>
#import <AVFoundation/AVFoundation.h>


@interface FFmpegDecode ()

@property (assign, nonatomic) AVFrame *frame;
@property (assign, nonatomic) AVCodec *codec;
@property (assign, nonatomic) AVCodecContext *codecCtx;
@property (assign, nonatomic) AVPacket packet;
@property (assign, nonatomic) AVFormatContext *formatCtx;

@end



@implementation FFmpegDecode

/**
 *  初始化视频解码器
 *
 *  @param width  宽度
 *  @param height 高度
 *
 *  @return YES:解码成功
 */
- (BOOL)initH264DecoderWithWidth:(int)width height:(int)height {
    
    av_register_all();
    
    avformat_network_init();
    self.codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    av_init_packet(&_packet);
    if (self.codec != nil) {
        self.codecCtx = avcodec_alloc_context3(self.codec);
        
        // 每包一个视频帧
        self.codecCtx->frame_number = 1;
        self.codecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
        
        // 视频的宽度和高度
        self.codecCtx->width = width;
        self.codecCtx->height = height;
        
        // 打开codec
        if (avcodec_open2(self.codecCtx, self.codec, NULL) >= 0) {
            self.frame = av_frame_alloc();
            if (self.frame == NULL) {
                return NO;
            }
        }
    }
    
    return (BOOL)self.frame;
}

/**
 *  视频解码
 *
 *  @param data 被解码视频数据
 *
 *  @return 图片
 */
- (void)H264decoderWithVideoData:(NSData *)VideoData completion:(void (^)(AVPicture))completion {
    @autoreleasepool {
        _packet.data = (uint8_t *)VideoData.bytes;
        _packet.size = (int)VideoData.length;
        
        int getPicture;
        avcodec_send_packet(_codecCtx, &_packet);
        getPicture = avcodec_receive_frame(self.codecCtx, self.frame);
        av_packet_unref(&_packet);
        if (getPicture == 0) {
            AVPicture picture;
            avpicture_alloc(&picture, AV_PIX_FMT_RGB24, self.codecCtx->width, self.codecCtx->height);
            
            struct SwsContext *img_convert_ctx = sws_getContext(self.codecCtx->width,
                                                                self.codecCtx->height,
                                                                AV_PIX_FMT_YUV420P,
                                                                self.codecCtx->width,
                                                                self.codecCtx->height,
                                                                AV_PIX_FMT_RGB24,
                                                                SWS_FAST_BILINEAR,
                                                                NULL,
                                                                NULL,
                                                                NULL);
            // 图像处理
            sws_scale(img_convert_ctx, (const uint8_t* const*)self.frame->data, self.frame->linesize, 0, self.codecCtx->height, picture.data, picture.linesize);
            
            sws_freeContext(img_convert_ctx);
            img_convert_ctx = NULL;
            
            if (completion) {
                completion(picture);
            }
            
            avpicture_free(&picture);
        }
    }
}

/**
 *  释放视频解码器
 */
- (void)releaseH264Decoder {
    if(self.codecCtx) {
        avcodec_close(self.codecCtx);
        avcodec_free_context(&_codecCtx);
        self.codecCtx = NULL;
    }
    
    if(self.frame) {
        av_frame_free(&_frame);
        self.frame = NULL;
    }
    av_packet_unref(&_packet);
}

@end
