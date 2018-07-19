//
//  FillImageView.m
//  iFill
//
//  Created by iRon_iMac on 2018/7/12.
//  Copyright © 2018年 iRon_. All rights reserved.
//

#import "FillImageView.h"
#import "LinkedListStack.h"

// 开启反锯齿
#define Using_Antialiasing NO
// 容差
#define Tolerance 10


@interface FillImageView ()

@property (nonatomic, strong) NSMutableArray *revokePointsArray;

@end

@implementation FillImageView

#pragma mark - Public Method

- (void)revokeOption
{
    CGPoint lastPoint = [self.revokePointsArray.lastObject CGPointValue];
    dispatch_async(dispatch_get_main_queue(), ^{
        /* 那个点染成白色 */
        UIImage *image = [self floodFillFromPoint:lastPoint withColor:[UIColor whiteColor]];
        if (image) {
            self.image = image;
        }
    });
}

#pragma mark - System Method

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _revokePointsArray = [NSMutableArray array];
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.newcolor =  [UIColor redColor];
        self.scaleNum = 1;
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
    NSArray *touchesArray = [[event allTouches] allObjects];
    if (touchesArray.count == 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [self floodFillFromPoint:point withColor:self.newcolor];
            if (image) {
                self.image = image;
            }
        });
    }
}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//}

#pragma mark - Function

/*
 *  泛洪填充算法
 *  泛洪算法常用的有四邻填充、八邻填充、基于扫描线填充法。这里用了基于扫描线填充
 */
- (UIImage *)floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor
{
    CGPoint savePoint = startPoint;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 获取当前的image指针
    CGImageRef imageRef = [self.image CGImage];
    
    NSUInteger imageWidth = CGImageGetWidth(imageRef);
    NSUInteger imageHeight = CGImageGetHeight(imageRef);
    // 实际大小跟屏幕的比例
//    CGFloat scaleNum = imageWidth / [UIScreen mainScreen].bounds.size.width;
    size_t w = startPoint.x * _scaleNum;
    size_t h = startPoint.y * _scaleNum;
    startPoint = CGPointMake(w, h);
    
    // 每个像素多少字节
    NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef) / 8;
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
    NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    
    // 创建保存图片数据的载体
    unsigned char *imageData = malloc(imageWidth * imageHeight * bytesPerPixel);
    // 存储空间所有位 都置0
    memset(imageData, 0, imageWidth * imageHeight * bytesPerPixel);
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    if (kCGImageAlphaLast == (uint32_t)bitmapInfo ||
        kCGImageAlphaFirst == (uint32_t)bitmapInfo)
    {
        bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedLast;
    }
    // 开启绘图的上下文
    CGContextRef context = CGBitmapContextCreate(imageData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
    // 关闭颜色空间
    CGColorSpaceRelease(colorSpace);
    // 绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), imageRef);
    
    /* 获取点击点的颜色 */
    NSUInteger byteIndex = (bytesPerRow * roundf(startPoint.y)) + bytesPerPixel * roundf(startPoint.x);
    NSUInteger oldColorCode = getColorCode(byteIndex, imageData);
    // 如果是点击了边框 直接返回
    NSUInteger blackColor = getColorCodeFromUIColor([UIColor blackColor], bitmapInfo&kCGBitmapByteOrderMask);
    if (compareColor(oldColorCode, blackColor, 10)) {
        return nil;
    }
    // 如果新的颜色与本来旧的颜色一样 直接返回
    if (compareColor(oldColorCode, getColorCodeFromUIColor(newColor, bitmapInfo&kCGBitmapByteOrderMask), 0)) {
        return nil;
    }
    
    NSInteger newRed, newGreen, newBlue, newAlpha;
    NSUInteger newColorCode = getColorCodeFromUIColor(newColor, bitmapInfo&kCGBitmapByteOrderMask);
    
    newRed = ((0xff000000 & newColorCode) >> 24);
    newGreen = ((0x00ff0000 & newColorCode) >> 16);
    newBlue = ((0x0000ff00 & newColorCode) >> 8);
    newAlpha = (0x000000ff & newColorCode);
    
    /* 所有点的栈 */
    LinkedListStack *points = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 multiplier:imageHeight];
    /* 反锯齿的栈 */
    LinkedListStack *antiAliasingPoints = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 multiplier:imageHeight];
    
    NSInteger x = roundf(startPoint.x);
    NSInteger y = roundf(startPoint.y);
    /* 开始点先存进栈 */
    [points pushFrontX:x andY:y];
    
    NSUInteger color;
    /*
     *  空左边，空右边
     *  泛洪算法·(基于扫描线填充)的优化
     *
     */
    BOOL spanLeft, spanRight;
    
    /* 栈里面每个node都要过一次循环 */
    while ([points popFront:&x andY:&y] != Invalid_Node_Content) {
        
        byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x);
        color = getColorCode(byteIndex, imageData);
        
        /* 找到当前列的相同颜色最高点 */
        while (y >= 0 && compareColor(oldColorCode, color, Tolerance)) {
            y--;
            
            if (y >= 0) {
                byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x);
                color = getColorCode(byteIndex, imageData);
            }
        }
        // 如果当前列的最高点有不同的颜色
        if (y >= 0 && !compareColor(oldColorCode, color, 0)) {
            // 加入反锯齿栈
            [antiAliasingPoints pushFrontX:x andY:y];
        }
        // 上面多做了一次y--，所以这里补回来
        y++;
        
        spanLeft = spanRight = NO;
        byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x);
        color = getColorCode(byteIndex, imageData);
        
        /* (上面求出了当前列的相同颜色的最高点) 从最高点往下走，走完这一列，直至找到不同颜色的点 */
        while (y < imageHeight && compareColor(oldColorCode, color, Tolerance) && newColorCode != color) {
            
            // 改变imageData里面的当前像素的颜色数值
            imageData[byteIndex + 0] = newRed;
            imageData[byteIndex + 1] = newGreen;
            imageData[byteIndex + 2] = newBlue;
            imageData[byteIndex + 3] = newAlpha;
            
            if (x > 0) {
                /* 当前点的左边点的颜色 */
                byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x-1);
                color = getColorCode(byteIndex, imageData);
                
                if (!spanLeft && x > 0 && compareColor(oldColorCode, color, Tolerance)) {
                    [points pushFrontX:(x - 1) andY:y];
                    /* 当前列的左边都不用检查了 */
                    spanLeft = YES;
                } else if (spanLeft && x > 0 && !compareColor(oldColorCode, color, Tolerance)) {
                    /* 当前列往下走时，遇到一个左边是不同颜色的点 */
                    spanLeft = NO;
                }
                
                // 如果当前点的左边点是不同的颜色
                if (!spanLeft && x > 0 && !compareColor(oldColorCode, color, Tolerance) && !compareColor(newColorCode, color, Tolerance)) {
                    // 加入反锯齿栈
                    [antiAliasingPoints pushFrontX:(x - 1) andY:y];
                }
            }
            
            if (x < imageWidth - 1) {
                /* 当前点的右边点的颜色 */
                byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x+1);
                color = getColorCode(byteIndex, imageData);
                
                if (!spanRight && compareColor(oldColorCode, color, Tolerance)) {
                    [points pushFrontX:(x + 1) andY:y];
                    /* 当前列的右边都不用检查了 */
                    spanRight = YES;
                } else if (spanRight && x > 0 && !compareColor(oldColorCode, color, Tolerance)) {
                    /* 当前列往下走时，遇到一个右边是不同颜色的点 */
                    spanRight = NO;
                }
                
                // 如果当前点的右边点是不同的颜色
                if (!spanRight && !compareColor(oldColorCode, color, Tolerance) && !compareColor(newColorCode, color, Tolerance)) {
                    // 加入反锯齿栈
                    [antiAliasingPoints pushFrontX:(x + 1) andY:y];
                }
            }
            
            // 往下走
            y++;
            
            if (y < imageHeight) {
                byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
                color = getColorCode(byteIndex, imageData);
            }
        }
        
        /* 当前列最低点不同的话 加入反锯齿 */
        if (y < imageHeight) {
            byteIndex = (bytesPerRow * roundf(y)) + roundf(x) * bytesPerPixel;
            color = getColorCode(byteIndex, imageData);
            if (!compareColor(oldColorCode, color, 0)) {
                [antiAliasingPoints pushFrontX:x andY:y];
            }
        }
        
    }/* 栈里面每个node都循环完了 */
    
    /*
     *  反锯齿部分
     *  遍历所有反锯齿栈里面的点
     */
    while ([antiAliasingPoints popFront:&x andY:&y] != Invalid_Node_Content) {
        
        byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x);
        color = getColorCode(byteIndex, imageData);
        
        if (!compareColor(newColorCode, color, 0)) {
            
            NSInteger originalRed = ((0xff000000 & color) >> 24);
            NSInteger originalGreen = ((0x00ff0000 & color) >> 16);
            NSInteger originalBlue = ((0x0000ff00 & color) >> 8);
            NSInteger originalAlpha = ((0x000000ff & color));
            
            if (Using_Antialiasing) {
                imageData[byteIndex + 0] = (newRed + originalRed) / 2;
                imageData[byteIndex + 1] = (newGreen + originalGreen) / 2;
                imageData[byteIndex + 2] = (newBlue + originalBlue) / 2;
                imageData[byteIndex + 3] = (newAlpha + originalAlpha) / 2;
            } else {
                imageData[byteIndex + 0] = originalRed;
                imageData[byteIndex + 1] = originalGreen;
                imageData[byteIndex + 2] = originalBlue;
                imageData[byteIndex + 3] = originalAlpha;
            }
        }
        
        //左边的点
        if (x > 0) {
            byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x-1);
            color = getColorCode(byteIndex, imageData);
            
            if (!compareColor(newColorCode, color, 0)) {
                NSInteger originalRed = ((0xff000000 & color) >> 24);
                NSInteger originalGreen = ((0x00ff0000 & color) >> 16);
                NSInteger originalBlue = ((0x0000ff00 & color) >> 8);
                NSInteger originalAlpha = ((0x000000ff & color));
                
                if (Using_Antialiasing) {
                    imageData[byteIndex + 0] = (newRed + originalRed) / 2;
                    imageData[byteIndex + 1] = (newGreen + originalGreen) / 2;
                    imageData[byteIndex + 2] = (newBlue + originalBlue) / 2;
                    imageData[byteIndex + 3] = (newAlpha + originalAlpha) / 2;
                } else {
                    imageData[byteIndex + 0] = originalRed;
                    imageData[byteIndex + 1] = originalGreen;
                    imageData[byteIndex + 2] = originalBlue;
                    imageData[byteIndex + 3] = originalAlpha;
                }
            }
        }
        
        // 右边的点
        if (x < imageWidth - 1) {
            byteIndex = (bytesPerRow * roundf(y)) + bytesPerPixel * roundf(x + 1);
            color = getColorCode(byteIndex, imageData);
            
            if (!compareColor(newColorCode, color, 0)) {
                NSInteger originalRed = ((0xff000000 & color) >> 24);
                NSInteger originalGreen = ((0x00ff0000 & color) >> 16);
                NSInteger originalBlue = ((0x0000ff00 & color) >> 8);
                NSInteger originalAlpha = ((0x000000ff & color));
                
                if (Using_Antialiasing) {
                    imageData[byteIndex + 0] = (newRed + originalRed) / 2;
                    imageData[byteIndex + 1] = (newGreen + originalGreen) / 2;
                    imageData[byteIndex + 2] = (newBlue + originalBlue) / 2;
                    imageData[byteIndex + 3] = (newAlpha + originalAlpha) / 2;
                } else {
                    imageData[byteIndex + 0] = originalRed;
                    imageData[byteIndex + 1] = originalGreen;
                    imageData[byteIndex + 2] = originalBlue;
                    imageData[byteIndex + 3] = originalAlpha;
                }
            }
        }
        
        // 上面的点
        if (y > 0) {
            byteIndex = (bytesPerRow * roundf(y - 1)) + bytesPerPixel * roundf(x);
            color = getColorCode(byteIndex, imageData);
            
            if (!compareColor(newColorCode, color, 0)) {
                NSInteger originalRed = ((0xff000000 & color) >> 24);
                NSInteger originalGreen = ((0x00ff0000 & color) >> 16);
                NSInteger originalBlue = ((0x0000ff00 & color) >> 8);
                NSInteger originalAlpha = ((0x000000ff & color));
                
                if (Using_Antialiasing) {
                    imageData[byteIndex + 0] = (newRed + originalRed) / 2;
                    imageData[byteIndex + 1] = (newGreen + originalGreen) / 2;
                    imageData[byteIndex + 2] = (newBlue + originalBlue) / 2;
                    imageData[byteIndex + 3] = (newAlpha + originalAlpha) / 2;
                } else {
                    imageData[byteIndex + 0] = originalRed;
                    imageData[byteIndex + 1] = originalGreen;
                    imageData[byteIndex + 2] = originalBlue;
                    imageData[byteIndex + 3] = originalAlpha;
                }
            }
        }
        
        // 下面的点
        if (y < imageHeight) {
            byteIndex = (bytesPerRow * roundf(y + 1)) + bytesPerPixel * roundf(x);
            color = getColorCode(byteIndex, imageData);
            
            if (!compareColor(newColorCode, color, 0)) {
                NSInteger originalRed = ((0xff000000 & color) >> 24);
                NSInteger originalGreen = ((0x00ff0000 & color) >> 16);
                NSInteger originalBlue = ((0x0000ff00 & color) >> 8);
                NSInteger originalAlpha = ((0x000000ff & color));
                
                if (Using_Antialiasing) {
                    imageData[byteIndex + 0] = (newRed + originalRed) / 2;
                    imageData[byteIndex + 1] = (newGreen + originalGreen) / 2;
                    imageData[byteIndex + 2] = (newBlue + originalBlue) / 2;
                    imageData[byteIndex + 3] = (newAlpha + originalAlpha) / 2;
                } else {
                    imageData[byteIndex + 0] = originalRed;
                    imageData[byteIndex + 1] = originalGreen;
                    imageData[byteIndex + 2] = originalBlue;
                    imageData[byteIndex + 3] = originalAlpha;
                }
            }
        }
        
    }/* 反锯齿栈里面每个node都循环完了 */
    
    CGImageRef newCGImage = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:newCGImage scale:[self.image scale] orientation:UIImageOrientationUp];
    
    CGImageRelease(newCGImage);
    CGContextRelease(context);
    free(imageData);
    
    if ([self.revokePointsArray containsObject:@(savePoint)]) {
        [self.revokePointsArray removeObject:@(savePoint)];
    } else {
        /* 存储已画的点 */
        [self.revokePointsArray addObject:@(savePoint)];
    }
    
    return result;
}

#pragma mark - Privated Method

/*  颜色的数值 eg:0xffaabbcc
 *  转为连续的数
 */
NSUInteger getColorCode (NSUInteger byteIndex, unsigned char *imageData) {
    
    NSUInteger red = imageData[byteIndex];
    NSUInteger green = imageData[byteIndex + 1];
    NSUInteger blue = imageData[byteIndex + 2];
    NSUInteger alpha = imageData[byteIndex + 3];
    
    return (red << 24) | (green << 16) | (blue << 8) | alpha;
}

/*
 *  UIColor 转为颜色的数值
 */
NSUInteger getColorCodeFromUIColor (UIColor *color, CGBitmapInfo orderMask) {
    NSInteger newRed, newGreen, newBlue, newAlpha;
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    if (CGColorGetNumberOfComponents(color.CGColor) == 2) {
        // 只有黑白灰的种类
        /* (这里*255,eg: 0.1*255=>0x19) */
        newRed = newGreen = newBlue = components[0] * 255;
        newAlpha = components[1] * 255;
    } else if (CGColorGetNumberOfComponents(color.CGColor) == 4) {
        // RGBA彩色种类
        /* 小端 */
        if (orderMask == kCGBitmapByteOrder32Little) {
            newRed = components[2] * 255;
            newGreen = components[1] * 255;
            newBlue = components[0] * 255;
            newAlpha = 255;
        } else {
            newRed = components[0] * 255;
            newGreen = components[1] * 255;
            newBlue = components[2] * 255;
            newAlpha = 255;
        }
    } else {
        newRed = newGreen = newBlue = 0;
        newAlpha = 255;
    }
    
    NSUInteger newColor = (newRed << 24) | (newGreen << 16) | (newBlue << 8) | newAlpha;
    return newColor;
}

/*  对比颜色
 *  容差之内返回true，相差太大返回false
 */
bool compareColor (NSUInteger colorA, NSUInteger colorB, NSInteger tolorance) {
    if (colorA == colorB) {
        return true;
    }
    
    NSInteger redA = ((0xff000000 & colorA) >> 24);
    NSInteger greenA = ((0x00ff0000 & colorA) >> 16);
    NSInteger blueA = ((0x0000ff00 & colorA) >> 8);
    NSInteger alphaA = (0x000000ff & colorA);
    
    NSInteger redB = ((0xff000000 & colorB) >> 24);
    NSInteger greenB = ((0x00ff0000 & colorB) >> 16);
    NSInteger blueB = ((0x0000ff00 & colorB) >> 8);
    NSInteger alphaB = (0x000000ff & colorB);
    
    // labs()绝对值
    NSInteger distanceRed = labs(redB - redA);
    NSInteger distanceGreen = labs(greenB - greenA);
    NSInteger distanceBlue = labs(blueB - blueA);
    NSInteger distanceAlpha = labs(alphaB - alphaA);
    
    if (distanceRed > tolorance || distanceGreen > tolorance || distanceBlue > tolorance || distanceAlpha > tolorance) {
        return false;
    }
    
    return true;
}

@end
