//
//  KTMovieImagesTransfer.h
//  KTMovieImagesTransfer
//
//  Created by Kevin on 16/8/13.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTTransferOperation.h"

@interface KTMovieImagesTransfer : NSObject

+ (instancetype)sharedTransfer;

- (KTTransferOperation *)transferMovie:(NSString *)movieFile toImagesAtPath:(NSString *)imagesPath name:(NSString *)name method:(KTTransferMethod)method;
- (KTTransferOperation *)transferImages:(NSArray *)imageFilesArray toMovie:(NSString *)movieFile method:(KTTransferMethod)method;

@end
