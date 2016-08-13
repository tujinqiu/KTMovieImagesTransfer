//
//  KTMovieImagesTransfer.m
//  KTMovieImagesTransfer
//
//  Created by Kevin on 16/8/13.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import "KTMovieImagesTransfer.h"

@interface KTMovieImagesTransfer ()

@property (nonatomic, strong) NSOperationQueue *transferQueue;

@end

@implementation KTMovieImagesTransfer

+ (instancetype)sharedTransfer
{
    static KTMovieImagesTransfer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KTMovieImagesTransfer alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _transferQueue = [[NSOperationQueue alloc] init];
        _transferQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (KTTransferOperation *)transferMovie:(NSString *)movieFile toImagesAtPath:(NSString *)imagesPath name:(NSString *)name method:(KTTransferMethod)method
{
    NSParameterAssert(movieFile);
    NSParameterAssert(imagesPath);
    
    KTTransferOperation *op = [[KTTransferOperation alloc] init];
    op.movieFile = movieFile;
    op.destImageFilesPath = imagesPath;
    op.destImageFilesPrefixName = name ? name : @"image";
    op.method = method;
    op.type = KTTransferTypeMovieToImages;
    [self.transferQueue addOperation:op];
    
    return op;
}

- (KTTransferOperation *)transferImages:(NSArray *)imageFilesArray toMovie:(NSString *)movieFile method:(KTTransferMethod)method
{
    NSParameterAssert(imageFilesArray);
    NSParameterAssert(movieFile);
    
    KTTransferOperation *op = [[KTTransferOperation alloc] init];
    op.imageFilesArray = imageFilesArray;
    op.destMovieFile = movieFile;
    op.method = method;
    op.type = KTTransferTypeImagesToMovie;
    [self.transferQueue addOperation:op];
    
    return op;
}

@end
