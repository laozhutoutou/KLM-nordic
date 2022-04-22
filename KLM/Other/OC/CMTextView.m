//
//  CMTextView.m
//  onecm
//
//  Created by 朱雨 on 2018/5/8.
//  Copyright © 2018年 朱雨. All rights reserved.
//

#import "CMTextView.h"

@interface CMTextView ()

@property (unsafe_unretained, nonatomic, readonly) NSString* realText;

- (void) beginEditing:(NSNotification*) notification;
- (void) endEditing:(NSNotification*) notification;

@end

@implementation CMTextView

@synthesize realTextColor;
@synthesize placeholderTitle;
@synthesize placeholderColor;

#pragma mark -
#pragma mark Initialisation

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib {
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginEditing:) name:UITextViewTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditing:) name:UITextViewTextDidEndEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textEditChanged:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
    
    self.realTextColor = self.textColor;
    self.placeholderColor = [UIColor lightGrayColor];
    [super awakeFromNib];
}

#pragma mark -
#pragma mark Setter/Getters

- (void)setPlaceholder:(NSString *)aPlaceholder {
    if ([self.realText isEqualToString:placeholderTitle] && ![self isFirstResponder]) {
        self.text = aPlaceholder;
    }
    if (aPlaceholder != placeholderTitle) {
        placeholderTitle = aPlaceholder;
    }
    
    
    [self endEditing:nil];
}

- (void)setPlaceholderColor:(UIColor *)aPlaceholderColor {
    placeholderColor = aPlaceholderColor;
    
    if ([super.text isEqualToString:self.placeholderTitle]) {
        self.textColor = self.placeholderColor;
    }
}

- (NSString *) text {
    NSString* text = [super text];
    if ([text isEqualToString:self.placeholderTitle]) return @"";
    return text;
}

- (void) setText:(NSString *)text {
    if (([text isEqualToString:@""] || text == nil) && ![self isFirstResponder]) {
        super.text = self.placeholderTitle;
    }else {
        super.text = text;
    }
    
    if ([text isEqualToString:self.placeholderTitle] || text == nil) {
        self.textColor = self.placeholderColor;
    }else {
        self.textColor = self.realTextColor;
    }
}

- (NSString *) realText {
    return [super text];
}

- (void) beginEditing:(NSNotification*) notification {
    
    if ([self.realText isEqualToString:self.placeholderTitle]) {
        super.text = nil;
        self.textColor = self.realTextColor;
    }
}

- (void) endEditing:(NSNotification*) notification {
    
    if ([self.realText isEqualToString:@""] || self.realText == nil) {
        super.text = self.placeholderTitle;
        self.textColor = self.placeholderColor;
    }
    
}

- (void) setTextColor:(UIColor *)textColor {
    if ([self.realText isEqualToString:self.placeholderTitle]) {
        if ([textColor isEqual:self.placeholderColor]){
            [super setTextColor:textColor];
        } else {
            self.realTextColor = textColor;
        }
    }
    else {
        self.realTextColor = textColor;
        [super setTextColor:textColor];
    }
}

-(void)textEditChanged:(NSNotification *)obj{
    
    UITextView *textView = (UITextView *)obj.object;
    
    NSString *toBeString = textView.text;
    
    NSString *lang = [[[UIApplication sharedApplication]textInputMode]primaryLanguage];
    
    if ([lang isEqualToString:@"zh-Hans"]) {
        
        UITextRange *selectedRange = [textView markedTextRange];
        
        UITextPosition *positon = [textView positionFromPosition:selectedRange.start offset:0];
        
        if (!positon) {
            
            if (toBeString.length > self.limitTextLeght && self.limitTextLeght >0) {
                
                textView.text = [toBeString substringToIndex:self.limitTextLeght];
                
            }else{
                
            }
        }
        
    }
    else{
        
        if (toBeString.length > self.limitTextLeght && self.limitTextLeght >0) {
            textView.text = [toBeString substringToIndex:self.limitTextLeght];
        }
    }
    
    if (self.textEdittingBlock) {
        self.textEdittingBlock (textView.text);
    }
    
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end
