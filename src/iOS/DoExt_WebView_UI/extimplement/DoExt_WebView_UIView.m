//
//  TYPEID_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "DoExt_WebView_UIView.h"

#import "doScriptEngineHelper.h"
#import "doSourceFile.h"
#import "doUIModuleHelper.h"
#import "doUIModule.h"
#import "doInvokeResult.h"
#import "doIPage.h"
#import "doIScriptEngine.h"
#import "doEventCenter.h"
#import "doServiceContainer.h"
#import "doIUIModuleFactory.h"
#import "doScriptEngineHelper.h"
#import "doTextHelper.h"
#import "doISourceFS.h"
#import "doUIContainer.h"


@implementation DoExt_WebView_View
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
}

//销毁所有的全局对象
- (void) OnDispose
{
    _model = nil;
    //自定义的全局属性
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取（该值为最新值）
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_url: (NSString *)_url
{
    if (_url != nil && _url.length > 0)
    {
        NSString *_fullUrl = [self getFullWebUrl:_url];
        [self navigate:_fullUrl];
    }
}

- (void)change_headerView: (NSArray *)_parms
{
    if (_parms != nil && _parms.count > 0)
    {
        doJsonNode *_dictParas = [_parms objectAtIndex:0];
        id<doIScriptEngine> _scriptEngine = [_parms objectAtIndex:1];
        doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
        
        NSString *_viewTemplate = [_dictParas GetOneText:@"path" :@""];
        
        // 根据viewTemplate构造view
        doSourceFile *_uiFile = [_scriptEngine.CurrentApp.SourceFS GetSourceByFileName :_viewTemplate ];
        if (_uiFile == nil)
            [NSException raise:@"webView" format:@"无效的headView:%@",_viewTemplate,nil];
        doUIContainer *_container = [[doUIContainer alloc] init:_scriptEngine.CurrentPage];
        
        doUIModule *_headViewModel = _container.RootView;
        if (_headViewModel == nil)
        {
            [NSException raise:@"webView" format:@"创建headView失败",nil];
        }
        
        UIView *_headView = (UIView *)_headViewModel.CurrentUIModuleView;
        
        if (_headView == nil)
        {
            [NSException raise:@"webView" format:@"创建headView失败",nil];
        }
        
        [self addSubview:_headView];
        
        [_invokeResult SetResultText:_headViewModel.UniqueKey];
    }
    else
    {
        [NSException raise:@"webView" format:@"无效的属性值",nil];
    }
}

#pragma mark -
#pragma mark - private
- (NSString *)getFullWebUrl:(NSString *)_name
{
    if (_name == nil || _name.length <= 0) return @"";
    if ([_name hasPrefix:@"http:"]|| [_name hasPrefix:@"https:"] || [_name hasPrefix:@"file:"])
    {
        return _name;
    }
    id<doISourceFS>  sourceFS = _model.CurrentPage.CurrentApp.SourceFS;
    NSString * _urlPath = [sourceFS GetFileFullPathByName:_name];
    return _urlPath;
}

- (void)navigate:(NSString *)_fullUrl
{
    NSURL *loadUrl = [NSURL fileURLWithPath:_fullUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_fullUrl]) {
    }else{
        NSString *urlStr = [NSString stringWithFormat:@"%@",_fullUrl];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        loadUrl = [NSURL URLWithString:urlStr];
        
    }
    
    [self loadRequest:[NSURLRequest requestWithURL:loadUrl]];
}


#pragma mark -
#pragma mark - event

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    doInvokeResult * _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_model.EventCenter FireEvent:@"loaded":_invokeResult];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    doInvokeResult * _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_model.EventCenter FireEvent:@"start":_invokeResult];
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    doInvokeResult * _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_model.EventCenter FireEvent:@"didScroll":_invokeResult];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    doInvokeResult * _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_model.EventCenter FireEvent:@"endScroll":_invokeResult];
}



#pragma mark -
#pragma mark - 同步异步方法的实现
/*
    1.参数节点
        doJsonNode *_dictParas = [parms objectAtIndex:0];
        a.在节点中，获取对应的参数
            NSString *title = [_dictParas GetOneText:@"title" :@"" ];
            说明：第一个参数为对象名，第二为默认值
 
    2.脚本运行时的引擎
        id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
 
 同步：
    3.同步回调对象(有回调需要添加如下代码)
        doInvokeResult *_invokeResult = [parms objectAtIndex:2];
            回调信息
                如：（回调一个字符串信息）
                [_invokeResult SetResultText:((doUIModule *)_model).UniqueKey];
 异步：
    3.获取回调函数名(异步方法都有回调)
        NSString *_callbackName = [parms objectAtIndex:2];
        在合适的地方进行下面的代码，完成回调
            新建一个回调对象
            doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
                填入对应的信息
                    如：（回调一个字符串）
                    [_invokeResult SetResultText: @"异步方法完成"];
                    [_scritEngine Callback:_callbackName :_invokeResult];
 */
#pragma mark -
#pragma mark Methods
- (void)loadString :(NSArray *)_parms
{
    doJsonNode *_dictParas = [_parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine =[_parms objectAtIndex:1];
    NSString *_callbackFuncName = [_parms objectAtIndex:2];
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init:_model.UniqueKey];
    @try {
        NSString* _text = [_dictParas GetOneText : @"text" : @""];
        
        [self loadHTMLString:_text baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    }
    @catch (NSException *exception) {
        [_invokeResult SetException:exception];
    }
    [_scriptEngine Callback:_callbackFuncName :_invokeResult];
}

- (void)back
{
    [self goBack];
}

- (void)forward
{
    [self goForward];
}

- (void)reload
{
    [self reload];
}

- (void)stop
{
    [self stopLoading];
}

- (void)canForward :(NSArray *)_parms
{
    doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
    [_invokeResult SetResultBoolean:self.canGoForward];
}

- (void)canBack :(NSArray *)_parms
{
    doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
    [_invokeResult SetResultBoolean:self.canGoBack];
}

- (void)getOffsetX :(NSArray *)_parms
{
    doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
    NSString *offsetX = [NSString stringWithFormat:@"%f", self.scrollView.contentOffset.x];
    [_invokeResult SetResultText:offsetX];
}

- (void)getOffsetY :(NSArray *)_parms
{
    doInvokeResult *_invokeResult = [_parms objectAtIndex:2];
    NSString *offsetY = [NSString stringWithFormat:@"%f", self.scrollView.contentOffset.y];
    [_invokeResult SetResultText:offsetY];
}


#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (doJsonNode *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (doJsonNode *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}


- (doUIModule *) GetModel
{
    return _model;
}

@end
