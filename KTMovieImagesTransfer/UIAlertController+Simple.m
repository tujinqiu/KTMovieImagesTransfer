//
//  UIAlertController+Simple.m
//  KTQRCode
//
//  Created by whkevin on 2016/10/10.
//  Copyright © 2016年 ovwhkevin0461. All rights reserved.
//

#import "UIAlertController+Simple.h"

@implementation UIAlertController (Simple)

+ (instancetype)simpleAlertControllerWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    if (cancel)
    {
        UIAlertAction *action = [UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:action];
    }
    return alert;
}

+ (instancetype)simpleAlertControllerWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel button:(NSString *)button handler:(void (^)(UIAlertAction *))handler
{
    UIAlertController *alert = [UIAlertController simpleAlertControllerWithTitle:title message:message cancel:cancel];
    UIAlertAction *action = [UIAlertAction actionWithTitle:button style:UIAlertActionStyleDefault handler:handler];
    [alert addAction:action];
    return alert;
}

+ (instancetype)simpleAlertControllerWithTitle:(NSString *)title message:(NSString *)message cancel:(NSString *)cancel button1:(NSString *)button1 handler1:(void (^)(UIAlertAction *))handler1 button2:(NSString *)button2 handler2:(void (^)(UIAlertAction *))handler2
{
    UIAlertController *alert = [UIAlertController simpleAlertControllerWithTitle:title message:message cancel:cancel];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:button1 style:UIAlertActionStyleDefault handler:handler1];
    [alert addAction:action1];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:button2 style:UIAlertActionStyleDefault handler:handler2];
    [alert addAction:action2];
    return alert;
}

@end
