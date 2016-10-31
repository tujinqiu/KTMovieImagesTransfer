//
//  RootViewController.m
//  TransferDemo
//
//  Created by Kevin on 2016/10/26.
//  Copyright © 2016年 Kevin. All rights reserved.
//

#import "RootViewController.h"
#import "UIAlertController+Simple.h"
#import "KTMovieImagesTransfer.h"

@interface RootViewController ()<KTMovieImagesTransferDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *methodSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegment;
@property (weak, nonatomic) IBOutlet UIButton *transferButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (nonatomic, assign) NSUInteger frameCount;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.frameCount = 200;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeType:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 1) {
        NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *imagesPath = [doc stringByAppendingPathComponent:@"images"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imagesPath]) {
            UIAlertController *alert = [UIAlertController simpleAlertControllerWithTitle:@"Documents下没有图片序列" message:nil cancel:@"好的"];
            [self presentViewController:alert animated:YES completion:nil];
            sender.selectedSegmentIndex = 0;
        }
    }
}

- (IBAction)tapTranserButton:(UIButton *)sender {
    KTMovieImagesTransfer *transfer = [[KTMovieImagesTransfer alloc] init];
    transfer.transferMethod = self.methodSegment.selectedSegmentIndex;
    transfer.delegate = self;
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *imagesPath = [doc stringByAppendingPathComponent:@"images"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:imagesPath]) {
        [manager createDirectoryAtPath:imagesPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    self.transferButton.enabled = NO;
    if (self.typeSegment.selectedSegmentIndex == 0) {
        NSString *movie = [[NSBundle mainBundle] pathForResource:@"movie" ofType:@"mp4"];
        [transfer transferMovie:movie toImagesAtPath:imagesPath];
    } else {
        NSString *movie = [doc stringByAppendingPathComponent:@"movie.mp4"];
        if ([manager fileExistsAtPath:movie]) {
            [manager removeItemAtPath:movie error:nil];
        }
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.frameCount];
        for (NSUInteger ii = 0; ii < self.frameCount; ++ii) {
            NSString *imageFile = [imagesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu.jpg", (unsigned long)ii]];
            [array addObject:imageFile];
        }
        [transfer transferImageFiles:array toMovie:movie];
    }
}

- (void)transfer:(KTMovieImagesTransfer *)transfer didTransferedAtIndex:(NSUInteger)index totalFrameCount:(NSUInteger)totalFrameCount
{
    self.frameCount = totalFrameCount;
    float progress = (float)(index + 1) / (float)totalFrameCount;
    self.progressView.progress = progress;
    self.progressLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100.0)];
}

- (void)transfer:(KTMovieImagesTransfer *)transfer didFinishedWithError:(NSError *)error
{
    NSString *str = error ? error.localizedDescription : @"转换成功";
    UIAlertController *alert = [UIAlertController simpleAlertControllerWithTitle:str message:nil cancel:@"好的"];
    [self presentViewController:alert animated:YES completion:nil];
    self.transferButton.enabled = YES;
}

@end
