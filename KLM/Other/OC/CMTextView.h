//
//  CMTextView.h
//  onecm
//
//  Created by 朱雨 on 2018/5/8.
//  Copyright © 2018年 朱雨. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^returnTextBlock)(NSString *text);

@interface CMTextView : UITextView

@property (nonatomic, strong) NSString *placeholderTitle;

@property (nonatomic, strong) UIColor *realTextColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *placeholderColor UI_APPEARANCE_SELECTOR;

/**
 *  限制文字长度
 */
@property (nonatomic, assign) NSInteger limitTextLeght;

/**
 *  输入框编辑中block
 */
@property (copy, nonatomic) returnTextBlock textEdittingBlock;

@end
