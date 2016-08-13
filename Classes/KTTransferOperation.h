//
//  KTTransferOperation.h
//  KTMovieImagesTransfer
//
//  Created by Kevin on 16/8/13.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KTTransferMethod)
{
    KTTransferMethodOwn = 0,        // 自带的api来解析
    KTTransferMethodFFmpeg,         // FFmpeg
    KTTransferMethodOpenCV          // open cv
};

typedef NS_ENUM(NSUInteger, KTTransferType)
{
    KTTransferTypeMovieToImages = 0,
    KTTransferTypeImagesToMovie
};

@class KTTransferOperation;

@protocol KTTransferOperationDelegate <NSObject>

@optional
- (void)operation:(KTTransferOperation *)operation didFinishedAtPath:(NSString *)path;
- (void)operation:(KTTransferOperation *)operation didFailedWithError:(NSError *)error;
- (void)operation:(KTTransferOperation *)operation didTransferedAtFrameIndex:(NSUInteger)frameIndex totalFrameCount:(NSUInteger)totalFrameCount;

@end

@interface KTTransferOperation : NSOperation

@property (nonatomic, assign) KTTransferMethod method;
@property (nonatomic, assign) KTTransferType type;
@property (nonatomic, copy) NSString *movieFile;
@property (nonatomic, copy) NSArray *imageFilesArray;
@property (nonatomic, copy) NSString *destMovieFile;
@property (nonatomic, copy) NSString *destImageFilesPath;
@property (nonatomic, copy) NSString *destImageFilesPrefixName;

@end
