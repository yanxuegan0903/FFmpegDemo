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

#define INBUF_SIZE 4096
#define AUDIO_INBUF_SIZE 20480
#define AUDIO_REFILL_THRESH 4096


#import "AAPLEAGLLayer.h"



@interface FFmpegDecode ()
{
    AAPLEAGLLayer * _playerLayer;
}


@property (assign, nonatomic) AVFrame *frame;
@property (assign, nonatomic) AVCodec *codec;
@property (assign, nonatomic) AVCodecContext *codecCtx;
@property (assign, nonatomic) AVPacket packet;
@property (assign, nonatomic) AVFormatContext *formatCtx;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) CVPixelBufferPoolRef pixelBufferPool;


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
- (BOOL)initH264DecoderWithWidth:(int)width height:(int)height imageView:(UIImageView *)imageView {
    
    self.imageView = imageView;
    _playerLayer = [[AAPLEAGLLayer alloc]initWithFrame:imageView.bounds];
    [self.imageView.layer addSublayer:_playerLayer];
    
    av_register_all();
    avcodec_register_all();
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
 *  @param VideoData 被解码视频数据
 *
 *
 */
- (void)H264decoderWithVideoData:(NSData *)VideoData{
    @autoreleasepool {

        
        _packet.data = (uint8_t *)VideoData.bytes;
        _packet.size = (int)VideoData.length;
        
        int decodeStatu;
        decodeStatu = avcodec_send_packet(_codecCtx, &_packet);
        
        if (decodeStatu == 0)
        {
            NSLog(@"sendPacket success");
            decodeStatu = avcodec_receive_frame(self.codecCtx, self.frame);
            av_packet_unref(&_packet);
            if (decodeStatu == 0)
            {
                NSLog(@"receive Packet success");
                //            AVPicture picture;
                //            avpicture_alloc(&picture, AV_PIX_FMT_RGB24, self.codecCtx->width, self.codecCtx->height);
                //            struct SwsContext *img_convert_ctx = sws_getContext(self.codecCtx->width,
                //                                                                self.codecCtx->height,
                //                                                                AV_PIX_FMT_YUV420P,
                //                                                                self.codecCtx->width,
                //                                                                self.codecCtx->height,
                //                                                                AV_PIX_FMT_RGB24,
                //                                                                SWS_FAST_BILINEAR,
                //                                                                NULL,
                //                                                                NULL,
                //                                                                NULL);
                //            // 图像处理
                //            sws_scale(img_convert_ctx, (const uint8_t* const*)self.frame->data, self.frame->linesize, 0, self.codecCtx->height, picture.data, picture.linesize);
                //
                //            sws_freeContext(img_convert_ctx);
                //            img_convert_ctx = NULL;
                //            
                //            if (completion) {
                //                completion(picture);
                //            }
                //            
                //            avpicture_free(&picture);
                
                [self dispatchAVFrame:self.frame];
                
                
            }else
            {
                NSLog(@"decodeStatu = %d",decodeStatu);
            }
        

        }else
        {
            NSLog(@"decodeStatu = %d",decodeStatu);
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


- (void)dispatchAVFrame:(AVFrame*) frame{
    if(!frame || !frame->data[0]){
        return;
    }
    
    CVReturn theError;
    if (!self.pixelBufferPool){
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithInt:frame->width] forKey: (NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithInt:frame->height] forKey: (NSString*)kCVPixelBufferHeightKey];
        [attributes setObject:@(frame->linesize[0]) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
        [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
        theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &_pixelBufferPool);
        if (theError != kCVReturnSuccess){
            NSLog(@"CVPixelBufferPoolCreate Failed");
        }
    }
    
    CVPixelBufferRef pixelBuffer = nil;
    theError = CVPixelBufferPoolCreatePixelBuffer(NULL, self.pixelBufferPool, &pixelBuffer);
    if(theError != kCVReturnSuccess){
        NSLog(@"CVPixelBufferPoolCreatePixelBuffer Failed");
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(base, frame->data[0], bytePerRowY * frame->height);
    base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(base, frame->data[1], bytesPerRowUV * frame->height/2);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    NSLog(@"_playerLayer.pixelBuffer = pixelBuffer;");
    _playerLayer.pixelBuffer = pixelBuffer;
    CVPixelBufferRelease(pixelBuffer);
}



- (BOOL)initFFmpegDecoderimageView:(UIImageView *)imageView {
    
    self.imageView = imageView;
    _playerLayer = [[AAPLEAGLLayer alloc]initWithFrame:imageView.bounds];
    [self.imageView.layer addSublayer:_playerLayer];


    /*注册所有的编码器，解析器，码流过滤器，只需要初始化一次*/
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        avcodec_register_all();
    });
    /*查找指定格式的解析器，这里我们使用H264*/
    
    
    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (pCodec == NULL) {
        NSLog(@"codec not found");
        return NO;
    }
    /*初始化解析器容器*/
    if (_codecCtx == NULL) {
        _codecCtx = avcodec_alloc_context3(pCodec);
        if (_codecCtx == NULL) {
            NSLog(@"Allocate codec context failed");
            return NO;
        }
        av_opt_set(_codecCtx->priv_data, "tune", "zerolatency", 0);
    }
    /*打开指定的解析器*/
    int ret = avcodec_open2(_codecCtx, pCodec, NULL);
    if (ret != 0) {
        NSLog(@"open codec error :%d", ret);
        return NO;
    }
    /*AVFrame用来描述原始的解码音频和视频数据*/
    if (_frame == NULL) {
        _frame = av_frame_alloc();
        if (_frame == NULL) {
            NSLog(@"av_frame_alloc failed");
            return NO;
        }
    }
    
//    avpicture_free(&avPicture);
//    avpicture_alloc(&avPicture, AV_PIX_FMT_RGB24, _outputSize.width, _outputSize.height);
    return YES;
}



@end
