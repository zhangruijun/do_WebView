//
//  TYPEID_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DoExt_WebView_IView.h"
#import "doIUIModuleView.h"
#import "DoExt_WebView_UIModel.h"

@interface DoExt_WebView_UIView : UIWebView <DoExt_WebView_IView,doIUIModuleView,UIWebViewDelegate>
//可根据具体实现替换UIView
{
    @private
    __weak DoExt_WebView_UIModel *_model;
}

@end
