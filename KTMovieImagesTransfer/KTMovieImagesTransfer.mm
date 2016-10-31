//
//  KTMovieImagesTransfer.m
//  OV3D
//
//  Created by whkevin on 2016/10/25.
//  Copyright © 2016年 ov. All rights reserved.
//

#import "KTMovieImagesTransfer.h"
#import <AVFoundation/AVFoundation.h>
#import <opencv2/opencv.hpp>
extern "C"
{
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libswscale/swscale.h>
}

NSString * const KTMovieImagesTransferErrorDomain = @"KTMovieImagesTransferErrorDomain";
// 默认帧率
static NSUInteger const kKTMovieImagesTransferFPS = 30;

static dispatch_queue_t KTMovieImagesTransferQueue () {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.kevinting.KTMovieImagesTransfer.queue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

@implementation KTMovieImagesTransfer

- (NSError *)errorWithErrorCode:(KTTransferErrorCode)errorCode object:(id)object
{
    NSString *errorString = nil;
    switch (errorCode) {
        case KTTransferFilePathNotExistError:
            errorString = [NSString stringWithFormat:@"文件不存在: %@", object];
            break;
            
        case KTTransferNoneImagesFilesError:
            errorString = @"图片序列文件数组不能为空";
            break;
            
        case KTTransferCancelledError:
            errorString = @"操作中途被取消";
            break;
            
        case KTTransferReadImageError:
            errorString = [NSString stringWithFormat:@"读取图片失败: %@", object];
            break;
            
        case KTTransferGetBufferError:
            errorString = @"获取buffer失败";
            break;
            
        case KTTransferFFmpegAllocError:
            errorString = @"ffmpeg初始化失败";
            break;
            
        case KTTransferOpenFileError:
            errorString = [NSString stringWithFormat:@"打开视频文件失败：%@", object];
            break;
            
        default:
            errorString = @"未知错误";
            break;
    }
    
    return [NSError errorWithDomain:KTMovieImagesTransferErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : errorString}];
}

- (void)sendToMainThreadError:(NSError *)error;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
            [self.delegate transfer:self didFinishedWithError:error];
        }
    });
}

- (void)transferMovie:(NSString *)movie toImagesAtPath:(NSString *)imagesPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist1 = [fileManager fileExistsAtPath:movie];
    BOOL exist2 = [fileManager fileExistsAtPath:imagesPath];
    NSError *error = nil;
    if (!exist1 || !exist2) {
        error = [self errorWithErrorCode:KTTransferFilePathNotExistError object:movie];
        if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
            [self.delegate transfer:self didFinishedWithError:error];
        }
        return;
    }
    switch (self.transferMethod) {
        case KTTransferMethodNative:
            error = [self nativeTransferMovie:movie toImagesAtPath:imagesPath];
            break;
            
        case KTTransferMethodOpenCV:
            error = [self opencvTransferMovie:movie toImagesAtPath:imagesPath];
            break;
            
        case KTTransferMethodFFmpeg:
            error = [self ffmpegTransferMovie:movie toImagesAtPath:imagesPath];
            break;
            
        default:
            break;
    }
}

- (void)transferImageFiles:(NSArray<NSString *> *)imageFiles toMovie:(NSString *)movie
{
    NSError *error = nil;
    if (imageFiles.count <= 0) {
        error = [self errorWithErrorCode:KTTransferNoneImagesFilesError object:nil];
        if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
            [self.delegate transfer:self didFinishedWithError:error];
        }
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = [movie stringByDeletingLastPathComponent];
    BOOL exist = [fileManager fileExistsAtPath:folder];
    if (!exist) {
        error = [self errorWithErrorCode:KTTransferFilePathNotExistError object:folder];
        if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
            [self.delegate transfer:self didFinishedWithError:error];
        }
        return;
    }
    switch (self.transferMethod) {
        case KTTransferMethodNative:
            error = [self nativeTransferImageFiles:imageFiles toMovie:movie];
            break;
            
        case KTTransferMethodOpenCV:
            error = [self opencvTransferImageFiles:imageFiles toMovie:movie];
            break;
            
        case KTTransferMethodFFmpeg:
            error = [self ffmpegTransferImageFiles:imageFiles toMovie:movie];
            break;
            
        default:
            break;
    }
}

#pragma mark -- 处理方法 --

- (NSError *)nativeTransferMovie:(NSString *)movie toImagesAtPath:(NSString *)imagesPath
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:movie] options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    CMTime time = asset.duration;
    NSUInteger totalFrameCount = CMTimeGetSeconds(time) * kKTMovieImagesTransferFPS;
    NSMutableArray *timesArray = [NSMutableArray arrayWithCapacity:totalFrameCount];
    for (NSUInteger ii = 0; ii < totalFrameCount; ++ii) {
        CMTime timeFrame = CMTimeMake(ii, kKTMovieImagesTransferFPS);
        NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
        [timesArray addObject:timeValue];
    }
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    __block NSError *returnError = nil;
    [generator generateCGImagesAsynchronouslyForTimes:timesArray completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        switch (result) {
                
            case AVAssetImageGeneratorFailed:
                returnError = error;
                [self sendToMainThreadError:returnError];
                break;
                
            case AVAssetImageGeneratorSucceeded:
            {
                NSString *imageFile = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld.jpg", requestedTime.value]];
                NSData *data = UIImageJPEGRepresentation([UIImage imageWithCGImage:image], 1.0);
                if ([data writeToFile:imageFile atomically:YES]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([self.delegate respondsToSelector:@selector(transfer:didTransferedAtIndex:totalFrameCount:)]) {
                            [self.delegate transfer:self didTransferedAtIndex:requestedTime.value totalFrameCount:totalFrameCount];
                        }
                    });
                    NSUInteger index = requestedTime.value;
                    if (index == totalFrameCount - 1) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
                                [self.delegate transfer:self didFinishedWithError:nil];
                            }
                        });
                    }
                } else {
                    returnError = [self errorWithErrorCode:KTTransferWriteError object:imageFile];
                    [self sendToMainThreadError:returnError];
                    [generator cancelAllCGImageGeneration];
                }
            }
                break;
                
            default:
                break;
        }
    }];
    
    return returnError;
}

- (NSError *)nativeTransferImageFiles:(NSArray<NSString *> *)imageFiles toMovie:(NSString *)movie
{
    __block NSError *returnError = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:movie] fileType:AVFileTypeQuickTimeMovie error:&returnError];
    if (returnError) {
        [self sendToMainThreadError:returnError];
        return returnError;
    }
    UIImage *firstImage = [UIImage imageWithContentsOfFile:[imageFiles firstObject]];
    if (!firstImage) {
        returnError = [self errorWithErrorCode:KTTransferReadImageError object:[imageFiles firstObject]];
        [self sendToMainThreadError:returnError];
        return returnError;
    }
    CGSize size = firstImage.size;
    // h264格式
    NSDictionary *videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: [NSNumber numberWithInt:size.width],
                                    AVVideoHeightKey: [NSNumber numberWithInt:size.height]};
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    dispatch_async(KTMovieImagesTransferQueue(), ^{
        [videoWriter addInput:writerInput];
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        UIImage *tmpImage = nil;
        NSUInteger index = 0;
        while (index < imageFiles.count) {
            if(writerInput.readyForMoreMediaData) {
                CMTime presentTime = CMTimeMake(index, kKTMovieImagesTransferFPS);
                tmpImage = [UIImage imageWithContentsOfFile:[imageFiles objectAtIndex:index]];
                if (!tmpImage) {
                    returnError = [self errorWithErrorCode:KTTransferReadImageError object:[imageFiles firstObject]];
                    [self sendToMainThreadError:returnError];
                    return;
                }
                CVPixelBufferRef buffer = [self pixelBufferFromCGImage:[tmpImage CGImage] size:size];
                if (buffer) {
                    [self appendToAdapter:adaptor pixelBuffer:buffer atTime:presentTime withInput:writerInput];
                    CFRelease(buffer);
                } else {
                    // Finish the session
                    [writerInput markAsFinished];
                    [videoWriter finishWritingWithCompletionHandler:^{
                    }];
                    returnError = [self errorWithErrorCode:KTTransferGetBufferError object:nil];
                    [self sendToMainThreadError:returnError];
                    return;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(transfer:didTransferedAtIndex:totalFrameCount:)]) {
                    [self.delegate transfer:self didTransferedAtIndex:index totalFrameCount:imageFiles.count];
                }
            });
            index++;
        }
        // Finish the session
        [writerInput markAsFinished];
        [videoWriter finishWritingWithCompletionHandler:^{
            if (videoWriter.status != AVAssetWriterStatusCompleted) {
                returnError = videoWriter.error;
                [self sendToMainThreadError:returnError];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
                        [self.delegate transfer:self didFinishedWithError:nil];
                    }
                });
            }
        }];
    });
    
    return returnError;
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
                                      size:(CGSize)imageSize
{
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey: @YES,
                              (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES};
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width,
                                          imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width,
                                                 imageSize.height, 8, 4*imageSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, imageSize.width, imageSize.height), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (BOOL)appendToAdapter:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
            pixelBuffer:(CVPixelBufferRef)buffer
                 atTime:(CMTime)presentTime
              withInput:(AVAssetWriterInput*)writerInput
{
    while (!writerInput.readyForMoreMediaData) {
        usleep(1);
    }
    
    return [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
}

- (NSError *)opencvTransferMovie:(NSString *)movie toImagesAtPath:(NSString *)imagesPath
{
    __block NSError *returnError = nil;
    dispatch_async(KTMovieImagesTransferQueue(), ^{
        CvCapture *pCapture = cvCaptureFromFile(movie.UTF8String);
        // 这个函数只是读取视频头文件信息来获取帧数，因此有可能有不对的情况
        // NSUInteger totalFrameCount = cvGetCaptureProperty(pCapture, CV_CAP_PROP_FRAME_COUNT);
        // 所以采取下面的遍历两遍的办法
        NSUInteger totalFrameCount = 0;
        while (cvQueryFrame(pCapture)) {
            totalFrameCount ++;
        }
        if (pCapture) {
            cvReleaseCapture(&pCapture);
        }
        pCapture = cvCaptureFromFile(movie.UTF8String);
        NSUInteger index = 0;
        IplImage *pGrabImg = NULL;
        while ((pGrabImg = cvQueryFrame(pCapture))) {
            NSString *imagePath = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.jpg", index]];
            cvSaveImage(imagePath.UTF8String, pGrabImg);
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(transfer:didTransferedAtIndex:totalFrameCount:)]) {
                    [self.delegate transfer:self didTransferedAtIndex:index totalFrameCount:totalFrameCount];
                }
            });
            index++;
        }
        if (pCapture) {
            cvReleaseCapture(&pCapture);
        }
        if (index == totalFrameCount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
                    [self.delegate transfer:self didFinishedWithError:nil];
                }
            });
        } else {
            returnError = [self errorWithErrorCode:KTTransferOpencvWrongFrameCountError object:nil];
            [self sendToMainThreadError:returnError];
        }
    });
    
    return returnError;
}

- (NSError *)opencvTransferImageFiles:(NSArray<NSString *> *)imageFiles toMovie:(NSString *)movie
{
    __block NSError *returnError = nil;
    UIImage *firstImage = [UIImage imageWithContentsOfFile:[imageFiles firstObject]];
    if (!firstImage) {
        returnError = [self errorWithErrorCode:KTTransferReadImageError object:[imageFiles firstObject]];
        [self sendToMainThreadError:returnError];
        return returnError;
    }
    CvSize size = cvSize(firstImage.size.width, firstImage.size.height);
    dispatch_async(KTMovieImagesTransferQueue(), ^{
        // OpenCV由于不原生支持H264（可以用其他办法做到），这里选用MP4格式
        CvVideoWriter *pWriter = cvCreateVideoWriter(movie.UTF8String, CV_FOURCC('D', 'I', 'V', 'X'), (double)kKTMovieImagesTransferFPS, size);
        for (NSUInteger ii = 0; ii < imageFiles.count; ++ii) {
            NSString *imageFile = [imageFiles objectAtIndex:ii];
            IplImage *pImage = cvLoadImage(imageFile.UTF8String);
            if (pImage) {
                // 这个函数会在模拟器调用的时候失败，不知道为啥
                cvWriteFrame(pWriter, pImage);
                cvReleaseImage(&pImage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(transfer:didTransferedAtIndex:totalFrameCount:)]) {
                        [self.delegate transfer:self didTransferedAtIndex:ii totalFrameCount:imageFiles.count];
                    }
                });
            } else {
                returnError = [self errorWithErrorCode:KTTransferReadImageError object:imageFile];
                [self sendToMainThreadError:returnError];
                return;
            }
        }
        cvReleaseVideoWriter(&pWriter);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(transfer:didFinishedWithError:)]) {
                [self.delegate transfer:self didFinishedWithError:nil];
            }
        });
    });
    
    return returnError;
}

- (NSError *)ffmpegTransferMovie:(NSString *)movie toImagesAtPath:(NSString *)imagesPath
{
    av_register_all();
    AVFormatContext *pFormatCtx = avformat_alloc_context();
    if (pFormatCtx == NULL) {
        return [self errorWithErrorCode:KTTransferFFmpegAllocError object:nil];
    }
    if (avformat_open_input(&pFormatCtx, movie.UTF8String, NULL, NULL) != 0) {
        avformat_free_context(pFormatCtx);
        return [self errorWithErrorCode:KTTransferOpenFileError object:movie];
    }
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        avformat_close_input(&pFormatCtx);
        avformat_free_context(pFormatCtx);
        return [self errorWithErrorCode:KTTransferFindStreamError object:nil];
    }
    int videoStreamIndex = -1;
    for (int ii = 0; ii < pFormatCtx->nb_streams; ++ii) {
        if (pFormatCtx->streams[ii]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamIndex = ii;
            break;
        }
    }
    if (videoStreamIndex == -1) {
        avformat_close_input(&pFormatCtx);
        avformat_free_context(pFormatCtx);
        return [self errorWithErrorCode:KTTransferFindStreamError object:nil];
    }
    AVCodecContext *pCodecCtx = pFormatCtx->streams[videoStreamIndex]->codec;
    AVCodec *pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if (pCodec == NULL) {
        avformat_close_input(&pFormatCtx);
        avformat_free_context(pFormatCtx);
        return [self errorWithErrorCode:KTTransferFindCodecError object:nil];
    }
    if (avcodec_open2(pCodecCtx, pCodec, NULL) != 0) {
        avformat_close_input(&pFormatCtx);
        avformat_free_context(pFormatCtx);
        return [self errorWithErrorCode:KTTransferOpenCodecError object:nil];
    }
    AVFrame *pFrame = av_frame_alloc();
    AVFrame *pRGBFrame = av_frame_alloc();
    if (pFrame == NULL || pRGBFrame == NULL) {
        avcodec_close(pCodecCtx);
        avformat_close_input(&pFormatCtx);
        avformat_free_context(pFormatCtx);
        return [self errorWithErrorCode:KTTransferFFmpegAllocError object:nil];
    }
    AVPacket packet;
    int width = pCodecCtx->width;
    int height = pCodecCtx->height;
    struct SwsContext *imgConvertCtx = sws_getContext(width, height, PIX_FMT_YUV420P, width, height, PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    int numOfBytes = avpicture_get_size(PIX_FMT_YUV420P, width, height);
    uint8_t *buffer = (uint8_t *)av_malloc(numOfBytes * sizeof(uint8_t));
    avpicture_fill((AVPicture *)pRGBFrame, buffer, PIX_FMT_YUV420P, width, height);
    // 循环解帧
    int index= 0;
    while (av_read_frame(pFormatCtx, &packet) == 0) {
        if (packet.stream_index == videoStreamIndex) {
            int frameFinished = 0;
            avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);
            if (frameFinished) {
            }
        }
        av_free_packet(&packet);
    }
    
    return nil;
}

- (NSError *)ffmpegTransferImageFiles:(NSArray<NSString *> *)imageFiles toMovie:(NSString *)movie
{
    return nil;
}

@end
