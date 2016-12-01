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



#define INBUF_SIZE 4096
#define AUDIO_INBUF_SIZE 20480
#define AUDIO_REFILL_THRESH 4096

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) FFmpegDecode * ffmpegDecode;
@end

@implementation ViewController
{
    int _count;
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
//    [ffmpegDecode initFFmpegDecoderimageView:self.imageView];
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
    
    for (int i = 1; i<1383; i++) {
        
        NSString * path = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"bb%04d.h264",i] ofType:nil];
        if (!path) {
            NSLog(@"path 不存在");
            i = 1;
            continue;
        }
        NSLog(@"path = %@",path);
        NSData * data = [NSData dataWithContentsOfFile:path];

        
//        if (data.length == 0) {
//            NSLog(@"_packet.size == 0");
//            continue;
//        }
        
        [self.ffmpegDecode H264decoderWithVideoData:data];
//        [self.ffmpegDecode releaseH264Decoder];
        usleep(1000*20);
        data = nil;
        path = nil;
    }
    
    
}

- (UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height
{
    
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}


/*
 * Video decoding example
 */
/*
static void pgm_save(unsigned char *buf, int wrap, int xsize, int ysize,
                     char *filename)
{
    FILE *f;
    int i;
    f = fopen(filename,"w");
    fprintf(f, "P5\n%d %d\n%d\n", xsize, ysize, 255);
    for (i = 0; i < ysize; i++)
        fwrite(buf + i * wrap, 1, xsize, f);
    fclose(f);
}
static int decode_write_frame(const char *outfilename, AVCodecContext *avctx,
                              AVFrame *frame, int *frame_count, AVPacket *pkt, int last)
{
    int len, got_frame;
    char buf[1024];
    len = avcodec_decode_video2(avctx, frame, &got_frame, pkt);
    if (len < 0) {
        fprintf(stderr, "Error while decoding frame %d\n", *frame_count);
        return len;
    }
    if (got_frame) {
        printf("Saving %sframe %3d\n", last ? "last " : "", *frame_count);
        fflush(stdout);
        // the picture is allocated by the decoder, no need to free it
        snprintf(buf, sizeof(buf), outfilename, *frame_count);
        pgm_save(frame->data[0], frame->linesize[0],
                 frame->width, frame->height, buf);
        (*frame_count)++;
    }
    if (pkt->data) {
        pkt->size -= len;
        pkt->data += len;
    }
    return 0;
}
static void video_decode_example(const char *outfilename, const char *filename)
{
//    av_register_all();
    avcodec_register_all();
//    avformat_network_init();
    
    AVCodec *codec;
    AVCodecContext *c= NULL;
    int frame_count;
    FILE *f;
    AVFrame *frame;
    uint8_t inbuf[INBUF_SIZE + AV_INPUT_BUFFER_PADDING_SIZE];
    AVPacket avpkt;
    av_init_packet(&avpkt);
    // set end of buffer to 0 (this ensures that no overreading happens for damaged MPEG streams)
    memset(inbuf + INBUF_SIZE, 0, AV_INPUT_BUFFER_PADDING_SIZE);
    printf("Decode video file %s to %s\n", filename, outfilename);
    // find the MPEG-1 video decoder
    codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!codec) {
        fprintf(stderr, "Codec not found\n");
        exit(1);
    }
    c = avcodec_alloc_context3(codec);
    if (!c) {
        fprintf(stderr, "Could not allocate video codec context\n");
        exit(1);
    }
    if (codec->capabilities & AV_CODEC_CAP_TRUNCATED)
        c->flags |= AV_CODEC_FLAG_TRUNCATED;
//      we do not send complete frames
//      For some codecs, such as msmpeg4 and mpeg4, width and height
//      MUST be initialized there because this information is not
//      available in the bitstream.
//      open it
    if (avcodec_open2(c, codec, NULL) < 0) {
        fprintf(stderr, "Could not open codec\n");
        exit(1);
    }
    f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "Could not open %s\n", filename);
        exit(1);
    }
    frame = av_frame_alloc();
    if (!frame) {
        fprintf(stderr, "Could not allocate video frame\n");
        exit(1);
    }
    frame_count = 0;
    for (;;) {
        avpkt.size = fread(inbuf, 1, INBUF_SIZE, f);
        if (avpkt.size == 0)
            break;
 //        NOTE1: some codecs are stream based (mpegvideo, mpegaudio) and this is the only method to use the because you cannot know the compressed data size before analysing it. BUT some other codec (msmpeg4, mpeg4) are inherently frame based, so you must call them with all the data for one frame exactly. You must also initialize 'width' and 'height' before initializing them.
 //        NOTE2: some codecs allow the raw parameters (frame size, sample rate) to be changed at any frame. We handle this, so you should also take care of it here, we use a stream based decoder (mpeg1video), so we feed decoder and see if it could decode a frame
        avpkt.data = inbuf;
        while (avpkt.size > 0)
            if (decode_write_frame(outfilename, c, frame, &frame_count, &avpkt, 0) < 0)
                exit(1);
    }
    // Some codecs, such as MPEG, transmit the I- and P-frame with a latency of one frame. You must do the following to have a chance to get the last frame of the video.
    avpkt.data = NULL;
    avpkt.size = 0;
    decode_write_frame(outfilename, c, frame, &frame_count, &avpkt, 1);
    fclose(f);
    avcodec_close(c);
    av_free(c);
    av_frame_free(&frame);
    printf("\n");
}

*/
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
