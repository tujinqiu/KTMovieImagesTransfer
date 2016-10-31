//
//  KTImagesMovieTransfer.h
//  TransferDemo
//
//  Created by Kevin on 2016/10/25.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, KTTransferMethod) {
    KTTransferMethodNative = 0,
    KTTransferMethodOpenCV,
    KTTransferMethodFFmpeg
};

typedef NS_ENUM(NSInteger, KTTransferErrorCode) {
    KTTransferFilePathNotExistError = -2000,
    KTTransferNoneImagesFilesError,
    KTTransferCancelledError,
    KTTransferWriteError,
    KTTransferReadImageError,
    KTTransferGetBufferError,
    KTTransferOpencvWrongFrameCountError,
    KTTransferFFmpegAllocError,
    KTTransferOpenFileError,
    KTTransferFindStreamError,
    KTTransferFindCodecError,
    KTTransferOpenCodecError
};

extern NSString * const KTImagesMovieTransferErrorDomain;

@class KTImagesMovieTransfer;

@protocol KTImagesMovieTransferDelegate <NSObject>

@optional

/**
 视频转图片时的解压进度，或者图片转视频时的压缩进度
 
 @param transfer        transfer
 @param index           index表示解压或者压缩到了第几帧
 @param totalFrameCount totalFrameCount表示总帧数
 */
- (void)transfer:(KTImagesMovieTransfer *)transfer didTransferedAtIndex:(NSUInteger)index totalFrameCount:(NSUInteger)totalFrameCount;

/**
 解压或者压缩完成/失败时候的回调
 
 @param transfer transfer
 @param error    如果成功，error为nil，否则为空
 */
- (void)transfer:(KTImagesMovieTransfer *)transfer didFinishedWithError:(NSError *)error;

@end

@interface KTImagesMovieTransfer : NSObject

@property (nonatomic, weak) id<KTImagesMovieTransferDelegate> delegate;
@property (nonatomic, assign) KTTransferMethod transferMethod;

/**
 将视频解压为图片序列帧，解压后的序列帧以0.jpg, 1.jpg, 2.jpg...格式存储
 
 @param movie      视频文件全路径，确保文件存在
 @param imagesPath 解压文件夹全路径，确保文件夹存在
 */
- (void)transferMovie:(NSString *)movie toImagesAtPath:(NSString *)imagesPath;

/**
 将图片序列帧压缩为视频，确保序列帧以0.jpg, 1.jpg, 2.jpg...格式存储
 
 @param imageFiles 图片序列帧文件数组
 @param movie       压缩视频文件全路径，确保放置该文件的文件夹存在
 */
- (void)transferImageFiles:(NSArray<NSString *> *)imageFiles toMovie:(NSString *)movie;

@end
