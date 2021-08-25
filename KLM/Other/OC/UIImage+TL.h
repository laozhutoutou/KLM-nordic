//
//  UIImage+TL.h
//  KLM
//
//  Created by 朱雨 on 2021/6/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (TL)

/// 翻转照片，因为拍照的照片问题
/// @param aImage aImage
+ (UIImage *)fixOrientation:(UIImage *)aImage;

+ (UIImage *)yp_imagecutWithOriginalImage:(UIImage *)originalImage withCutRect:(CGRect)rect;

/// 根据某点获取图片颜色
/// @param point point
- (UIColor *)getPixelColorAtPoint:(CGPoint)point;

/// 将图片转化成data
/// @param image image
- (unsigned char *) convertUIImageToBitmapRGBA8:(UIImage *) image;

/**
 *  Create an image from a given color
 *
 *  @param color Color value
 *
 *  @return Returns the created UIImage
 */
+ (UIImage * _Nonnull)imageWithColor:(UIColor * _Nonnull)color;

@end

NS_ASSUME_NONNULL_END
