//
//  TYPEID_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DoExt_WebView_IView <NSObject>

@required
//属性方法

- (void)change_url: (NSString *)_url;
- (void)change_headerView: (NSArray *)_parms;


- (void)loadString :(NSArray *)_parms;

@end
