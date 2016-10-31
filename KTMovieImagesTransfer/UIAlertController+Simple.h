//
//  UIAlertController+Simple.h
//  KTQRCode
//
//  Created by whkevin on 2016/10/10.
//  Copyright © 2016年 ovwhkevin0461. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (Simple)

+ (instancetype)simpleAlertControllerWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel;
+ (instancetype)simpleAlertControllerWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel button:(NSString *)button handler:(void (^)(UIAlertAction *action))handler;
+ (instancetype)simpleAlertControllerWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel button1:(NSString *)button1 handler1:(void (^)(UIAlertAction *action))handler1 button2:(NSString *)button2 handler2:(void (^)(UIAlertAction *action))handler2;

@end
