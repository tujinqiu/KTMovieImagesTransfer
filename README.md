# KTMovieImagesTransfer
视频文件与图片序列的互相转换，使用原生API，FFmpeg，Open CV分别实现

1、使用方法：

视频转图片

```
transfer.transferMethod = KTTransferMethodOpenCV;
NSString *movie = [[NSBundle mainBundle] pathForResource:@"movie" ofType:@"mp4"];
[transfer transferMovie:movie toImagesAtPath:imagesPath];
```
图片转视频

```
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
```

2、使用代理查看转换过程，错误和完成

```
- (void)transfer:(KTMovieImagesTransfer *)transfer didTransferedAtIndex:(NSUInteger)index totalFrameCount:(NSUInteger)totalFrameCount
{
    self.frameCount = totalFrameCount;
    float progress = (float)(index + 1) / (float)totalFrameCount;
    self.progressView.progress = progress;
}

- (void)transfer:(KTMovieImagesTransfer *)transfer didFinishedWithError:(NSError *)error
{
    NSString *str = error ? error.localizedDescription : @"转换成功";
}
```

[可以看看看我的博客文档](http://www.jianshu.com/p/05f12f2b03ee)


