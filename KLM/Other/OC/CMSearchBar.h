//
//  CMSearchBar.h
//  onecm
//
//  Created by 朱雨 on 2018/9/1.
//  Copyright © 2018年 朱雨. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CMSearchBar;
@protocol CMSearchBarDelegate <UIBarPositioningDelegate>

@optional
-(BOOL)searchBarShouldBeginEditing:(CMSearchBar *)searchBar;                      // return NO to not become first responder
- (void)searchBarTextDidBeginEditing:(CMSearchBar *)searchBar;                     // called when text starts editing
- (BOOL)searchBarShouldEndEditing:(CMSearchBar *)searchBar;                        // return NO to not resign first responder
- (void)searchBarTextDidEndEditing:(CMSearchBar *)searchBar;                       // called when text ends editing
- (void)searchBar:(CMSearchBar *)searchBar textDidChange:(NSString *)searchText;   // called when text changes (including clear)
- (BOOL)searchBar:(CMSearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text; // called before text changes

- (void)searchBarSearchButtonClicked:(CMSearchBar *)searchBar;                     // called when keyboard search button pressed
- (void)searchBarCancelButtonClicked:(CMSearchBar *)searchBar;                     // called when cancel button pressed
// called when cancel button pressed
@end

@interface CMSearchBar : UIView <UITextInputTraits>

@property (nonatomic, strong) UITextField *textField;

@property(nullable,nonatomic,weak) id<CMSearchBarDelegate> delegate; // default is nil. weak reference
@property(nullable,nonatomic,copy) NSString  *text;                  // current/starting search text
@property(nullable,nonatomic,copy) NSString  *placeholder;           // default is nil. string is drawn 70% gray
@property(nonatomic) BOOL  showsCancelButton;                        // default is yes
@property(nullable,nonatomic,strong) UIColor *textColor;             // default is nil. use opaque black
@property(nullable,nonatomic,strong) UIFont  *font;                  // default is nil. use system font 12 pt
@property(nullable,nonatomic,strong) UIColor *placeholderColor;      // default is drawn 70% gray

/* Allow placement of an input accessory view to the keyboard for the search bar
 */
@property (nullable,nonatomic,readwrite,strong) UIView *inputAccessoryView;

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

/**
 停止
 */
- (void)stopSearch;

@end

NS_ASSUME_NONNULL_END

