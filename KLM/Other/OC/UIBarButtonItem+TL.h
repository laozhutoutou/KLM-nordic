//
//  UIBarButtonItem+TL.h
//  BGTabBar-自定义
//
//  Created by liao on 14-10-11.
//  Copyright (c) 2014年 BangGu. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIBarButtonItem (TL)

NS_ASSUME_NONNULL_BEGIN

+(UIBarButtonItem *)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action;

+(NSArray *)itemWithBackIconTarget:(id)target action:(SEL)action;

+(UIBarButtonItem *)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action;

+(NSArray<UIBarButtonItem *> *)itemsWithIcon:(nullable NSString *)icon target:(id)target action:(SEL)action;

NS_ASSUME_NONNULL_END

@end
