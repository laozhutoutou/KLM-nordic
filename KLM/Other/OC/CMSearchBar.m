//
//  CMSearchBar.m
//  onecm
//
//  Created by 朱雨 on 2018/9/1.
//  Copyright © 2018年 朱雨. All rights reserved.
//

#import "CMSearchBar.h"

NS_ASSUME_NONNULL_BEGIN

static const CGFloat CMSearchBarMargin = 0;

@interface CMSearchBar ()<UITextFieldDelegate>
/** 2.取消按钮 */
@property (nonatomic, strong) UIButton *buttonCancel;
/** 3.搜索图标 */
@property (nonatomic, strong) UIImageView *imageIcon;
/** 4.中间视图 */
@property (nonatomic, strong) UIButton *buttonCenter;

@end

NS_ASSUME_NONNULL_END

@implementation CMSearchBar

#pragma mark - --- 1. init 视图初始化 ---
- (instancetype)init
{
    if (self = [super init]) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setupUI];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupUI];
}

- (void)setupUI{
    _placeholder = @"";
    _showsCancelButton = YES;
    _placeholderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    
    self.backgroundColor = [UIColor colorWithRed:(201.0/255) green:(201.0/255) blue:(206.0/255) alpha:1];
    self.clipsToBounds = YES;
    [self addSubview:self.buttonCancel];
    [self addSubview:self.textField];
    [self addSubview:self.buttonCenter];
}

#pragma mark - --- 2. delegate 视图委托 ---

#pragma mark - UITextField delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    CGRect frameButtonCenter = self.buttonCenter.frame;
    frameButtonCenter.origin.x = CGRectGetMinX(self.textField.frame);
    [UIView animateWithDuration:0.3 animations:^{
        self.buttonCenter.frame = frameButtonCenter;
        if (self.showsCancelButton) {
            CGRect buttonRect = self.buttonCancel.frame;
            buttonRect.origin.x -=  self.buttonCancel.frame.size.width;
            self.buttonCancel.frame = buttonRect;
            self.textField.frame = CGRectMake(CMSearchBarMargin, 0, self.buttonCancel.frame.origin.x-CMSearchBarMargin, self.frame.size.height);
        }
    } completion:^(BOOL finished) {
        [self.buttonCenter setHidden:YES];
        [self.imageIcon setHidden:NO];
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.placeholder attributes:@{NSForegroundColorAttributeName:self.placeholderColor}];
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)])
    {
        return [self.delegate searchBarShouldBeginEditing:self];
    }
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBarTextDidBeginEditing:)])
    {
        [self.delegate searchBarTextDidBeginEditing:self];
    }
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)])
    {
        return [self.delegate searchBarShouldEndEditing:self];
    }
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBarTextDidEndEditing:)])
    {
        [self.delegate searchBarTextDidEndEditing:self];
    }
    
}

- (void)stopSearch{
    [self.textField resignFirstResponder];
    self.textField.text = @"";
    [self.buttonCenter setHidden:NO];
    [self.imageIcon setHidden:YES];
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName:self.placeholderColor}];
    [UIView animateWithDuration:0.3 animations:^{
        if (self.showsCancelButton) {
            CGRect buttonRect = self.buttonCancel.frame;
            buttonRect.origin.x +=  self.buttonCancel.frame.size.width;
            self.buttonCancel.frame = buttonRect;
            self.textField.frame = CGRectMake(CMSearchBarMargin, 0, self.frame.size.width-CMSearchBarMargin*2, self.frame.size.height);
        }
        self.buttonCenter.center = self.textField.center;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)textFieldDidChange:(UITextField *)textField
{
    
    if (textField.text.length > 0) {
        [self.buttonCancel setHighlighted:YES];
    }else {
        [self.buttonCancel setHighlighted:NO];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBar:textDidChange:)])
    {
        [self.delegate searchBar:self textDidChange:textField.text];
    }
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBar:shouldChangeTextInRange:replacementText:)])
    {
        return [self.delegate searchBar:self shouldChangeTextInRange:range replacementText:string];
    }
    return YES;
}
- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBar:textDidChange:)])
    {
        [self.delegate searchBar:self textDidChange:@""];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)])
    {
        [self.delegate searchBarSearchButtonClicked:self];
    }
    return YES;
}
#pragma mark - --- 3. event response 事件相应 ---
-(void)cancelButtonTouched
{
    self.textField.text = @"";
    [self.textField resignFirstResponder];
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)])
    {
        [self.delegate searchBarCancelButtonClicked:self];
    }
}
#pragma mark - --- 4. private methods 私有方法 ---
- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.textField resignFirstResponder];
}
#pragma mark - --- 5. setters 属性 ---
- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;

}

- (void)setText:(NSString *)text
{
    self.textField.text = text?:@"";
    if (text.length > 0) {
        [self textFieldShouldBeginEditing:self.textField];
    }
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView
{
    _inputAccessoryView = inputAccessoryView;
    self.textField.inputAccessoryView = inputAccessoryView;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.textField.textColor = textColor;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    NSAssert(_placeholder, @"Please set placeholder before setting placeholdercolor");
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName:placeholderColor}];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    self.textField.font = font;
}

#pragma mark - --- 6. getters 属性 —

- (NSString *)text
{
    return self.textField.text;
}

- (UITextField *)textField
{
    if (!_textField) {
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(CMSearchBarMargin, 0, self.frame.size.width-CMSearchBarMargin*2, self.frame.size.height)];
        textField.delegate = self;
        textField.borderStyle = UITextBorderStyleNone;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.returnKeyType = UIReturnKeySearch;
        textField.enablesReturnKeyAutomatically = YES;
        textField.font = [UIFont systemFontOfSize:14.0f];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [textField addTarget:self
                      action:@selector(textFieldDidChange:)
            forControlEvents:UIControlEventEditingChanged];
        textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        textField.backgroundColor = [UIColor clearColor];
        textField.tintColor = [UIColor whiteColor];
        [textField setLeftViewMode:UITextFieldViewModeAlways];
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 25, textField.frame.size.height)];
        [leftView addSubview:self.imageIcon];
        self.imageIcon.center = leftView.center;
        textField.leftView = leftView;
        [textField setClipsToBounds:YES];
        _textField = textField;
        
    }
    return _textField;
}

- (UIButton *)buttonCancel
{
    if (!_buttonCancel) {
        UIButton *buttonCancel = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonCancel.frame = CGRectMake(self.frame.size.width, 0, 40, self.frame.size.height);
        buttonCancel.titleLabel.font = [UIFont systemFontOfSize:13];
        [buttonCancel addTarget:self
                         action:@selector(cancelButtonTouched)
               forControlEvents:UIControlEventTouchUpInside];
        [buttonCancel setTitle:@"cancel" forState:UIControlStateNormal];
        [buttonCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [buttonCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        buttonCancel.autoresizingMask =UIViewAutoresizingFlexibleLeftMargin;
        
        _buttonCancel = buttonCancel;
    }
    return _buttonCancel;
}

- (UIButton *)buttonCenter
{
    if (!_buttonCenter) {
        UIButton *buttonCenter = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonCenter.frame = CGRectMake(0, 0, 60, self.frame.size.height);
        [buttonCenter setImage:[UIImage imageNamed:@"icon_search"] forState:UIControlStateNormal];
        [buttonCenter setTitle:@"search" forState:UIControlStateNormal];
        [buttonCenter setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [buttonCenter.titleLabel setFont:[UIFont systemFontOfSize:13]];
        [buttonCenter setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
        [buttonCenter setEnabled:NO];
        buttonCenter.center = self.textField.center;
        _buttonCenter = buttonCenter;
    }
    return _buttonCenter;
}

- (UIImageView *)imageIcon
{
    if (!_imageIcon) {
        UIImageView *imageIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_search"]];
        [imageIcon setHidden:YES];
        _imageIcon = imageIcon;
    }
    return _imageIcon;
}

@end
