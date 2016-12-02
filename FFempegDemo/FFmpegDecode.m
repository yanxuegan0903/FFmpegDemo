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
    NSLock * _dstDataLock;
    
    
    
    
    
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
    
    int version = avcodec_version();
    NSLog(@"version = %d",version);
    return (BOOL)self.frame;
}

/**
 *  视频解码
 *
 *  VideoData 被解码视频数据
 *
 *
 */
static int count = 0;
- (void)H264decoderWithVideoData:(NSData *)VideoData{
    static int i;
    i++;
    count++;
        
    _packet.data = (uint8_t *)VideoData.bytes;
    _packet.size = (int)VideoData.length;

    
    int got_picture_ptr;
    int status = avcodec_decode_video2(self.codecCtx, self.frame, &got_picture_ptr, &(_packet));
    if (status >0)
    {
        [self dispatchAVFrame:self.frame];
    }else
    {
        avcodec_flush_buffers(self.codecCtx);
    }

    
    //    int sendDecodeStatu,receiveDecodeStatus;
//    if (i <= 1000000){
//        sendDecodeStatu = avcodec_send_packet(_codecCtx, &_packet);
//        if (sendDecodeStatu == 0)
//        {
//            NSLog(@"sendPacket success");
//            receiveDecodeStatus = avcodec_receive_frame(self.codecCtx, self.frame);
//            if (receiveDecodeStatus == 0)
//            {
//                NSLog(@"receive Packet success");
//                [self dispatchAVFrame:self.frame];
//                
//            }else if(receiveDecodeStatus == AVERROR_EOF){
//                avcodec_flush_buffers(_codecCtx);
//                NSLog(@"receiveDecodeStatus = AVERROR_EOF");
//            }else
//            {
//                avcodec_flush_buffers(_codecCtx);
//                NSLog(@"receiveDecodeStatus = %d",receiveDecodeStatus);
//            }
//         
//
//        }else
//        {
//            NSLog(@"sendDecodeStatu = %d",sendDecodeStatu);
//        }
//        av_packet_unref(&_packet);
////        av_frame_unref(_frame);
//        }
//    }
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
    avformat_network_deinit();
}


- (void)dispatchAVFrame:(AVFrame*) frame{
    
    if(!frame || !frame->data[0]){
        return;
    }
    [_dstDataLock lock];
    
    
    NSLog(@"errorCode = %d",frame -> decode_error_flags);
    
    
    CVReturn theError;

    CVPixelBufferRef pixelBuffer = nil;
    
    theError = CVPixelBufferCreate(NULL, frame->width, frame->height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuffer);
    if(theError != kCVReturnSuccess){
        NSLog(@"CVPixelBufferPoolCreatePixelBuffer Failed  theError = %d",theError);
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(base, frame->data[0], bytePerRowY * frame->height);
    base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    uint32_t size = frame->linesize[1] * frame->height;

    uint8_t * _dstData = malloc(size*2);
    if(_dstData == NULL){
        NSLog(@"dstData = NUll");
        [_dstDataLock unlock];
        CVPixelBufferRelease(pixelBuffer);
        return;
    }

    
    
    for (int i = 0; i < 2 * size; i++){
        if (i % 2 == 0){
            _dstData[i] = frame->data[1][i/2];
        }else{

            _dstData[i] = frame->data[2][i/2];
        }
    }
    //memset(frame->data[2], 0, size);
    memcpy(base, _dstData, bytesPerRowUV * frame->height/2);
//    int ret = CVPixelBufferCreateWithBytes(NULL, frame->width, frame->height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, buffer, frame->linesize[0], NULL, 0, NULL, &pixelBuffer)
    
    NSLog(@"_playerLayer.pixelBuffer = pixelBuffer;");
    _playerLayer.pixelBuffer = pixelBuffer;
    CVPixelBufferRelease(pixelBuffer);
    free(_dstData);
    [_dstDataLock unlock];
}



@end
