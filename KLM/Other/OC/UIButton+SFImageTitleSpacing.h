//
//  UIButton+SFImageTitleSpacing.h
//  SF
//
//  Created by 赵坤(Kun Zhao)-顺维修与丰觅项目 on 2017/9/9.
//  Copyright © 2017年 深圳市顺丰大当家科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SFButtonEdgeInsetsStyle) {
    SFButtonEdgeInsetsStyleTop, // image在上，label在下
    SFButtonEdgeInsetsStyleLeft, // image在左，label在右
    SFButtonEdgeInsetsStyleBottom, // image在下，label在上
    SFButtonEdgeInsetsStyleRight // image在右，label在左
};


@interface UIButton (SFImageTitleSpacing)

/**
 *  设置button的titleLabel和imageView的布局样式，及间距
 *
 *  @param style titleLabel和imageView的布局样式
 *  @param space titleLabel和imageView的间距
 */
- (void)layoutButtonWithEdgeInsetsStyle:(SFButtonEdgeInsetsStyle)style
                        imageTitleSpace:(CGFloat)space;




@end
