//
//  UIBarButtonItem+TL.m
//  BGTabBar-自定义
//
//  Created by liao on 14-10-11.
//  Copyright (c) 2014年 BangGu. All rights reserved.
//

#import "UIBarButtonItem+TL.h"
//#define UIBarButtonItemWH 30

@implementation UIBarButtonItem (TL)

+(UIBarButtonItem *)itemWithIcon:(NSString *)icon target:(id)target action:(SEL)action{
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [UIImage imageNamed:icon];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateHighlighted];
    button.frame = CGRectMake(10, 0, image.size.width + 20, image.size.height+20);
//    [button expandClickAreaWithTop:50 Right:50 Bottom:50 Left:50];
    button.imageView.contentMode = UIViewContentModeRight;
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    return barButtonItem;
    
}

+(NSArray<UIBarButtonItem *> *)itemsWithIcon:(nullable NSString *)icon target:(id)target action:(SEL)action{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [UIImage imageNamed:icon];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:image forState:UIControlStateHighlighted];
    button.frame = CGRectMake(10, 0, image.size.width + 20, image.size.height+20);
    button.backgroundColor = [UIColor orangeColor];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    UIBarButtonItem *nagetiveSpacer = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    nagetiveSpacer.width = -15;
    return @[barButtonItem,nagetiveSpacer];
    
}

+(NSArray *)itemWithBackIconTarget:(id)target action:(SEL)action{
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setImage:[UIImage imageNamed:@"icon_return"] forState:UIControlStateNormal];
    [leftButton setImage:[UIImage imageNamed:@"icon_return"] forState:UIControlStateHighlighted];
    leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                       target:nil action:nil];
    negativeSpacer.width = 0;
    leftButton.frame = (CGRect){(CGPointZero),CGSizeMake(40, 44)};
    [leftButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    return @[negativeSpacer,leftBarButtonItem];
}

+(UIBarButtonItem *)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action{
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.frame = (CGRect){(CGPointMake(0, 0)),CGSizeMake(30+15, 30)};
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}


@end
