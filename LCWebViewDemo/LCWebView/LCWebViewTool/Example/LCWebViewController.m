//
//  LCWebViewController.m
//  LCWebView
//
//  Created by care on 2018/1/2.
//  Copyright © 2018年 luochuan. All rights reserved.
//

#import "LCWebViewController.h"
#import "LCWebView.h"
#define iPhoneXSeries (([[UIApplication sharedApplication] statusBarFrame].size.height == 44.0f) ? (YES):(NO))
@interface LCWebViewController ()<LCWebViewDelegate,LCWebViewWKSupplementDelegate>
@property (nonatomic, strong) LCWebView * webView;
@property (nonatomic, strong) UIProgressView * progressView;
@end

@implementation LCWebViewController
- (void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)loadRequest:(NSURLRequest *)request{
    [self setUpWebView];
    [self.webView LC_loadRequest:request];
}
- (void)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL{
    [self setUpWebView];
    [self.webView LC_loadHTMLString:string baseURL:baseURL];
}
- (void)loadHTMLFileName:(NSString *)htmlName{
    [self setUpWebView];
    [self.webView LC_loadHTMLFileName:htmlName];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar addSubview:self.progressView];
    [self.view addSubview:_webView];
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]){
        NSString *str=change[NSKeyValueChangeNewKey];
        NSLog(@"=======进度条=======%@",str);
        //self.progressView.progress = str.floatValue;
        [self.progressView setProgress:str.floatValue animated:YES];
        if (str.floatValue>=1.0) {
            self.progressView.hidden=YES;
        }
    }
}

- (void)setUpWebView{
    if (!_webView) {
        _webView=[[LCWebView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) withWKWebViewConfiguration:nil];//configuration若为nil,则会默认设置,前往查看LCWebView.m
        _webView.webDelegate=self;
        _webView.supplementDelegate=self;
        _webView.backgroundColor=[UIColor whiteColor];
        _webView.scalesPageToFit=YES;
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    }
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,44, [UIScreen mainScreen].bounds.size.width, 1)];
        _progressView.progressViewStyle = UIProgressViewStyleDefault;
        _progressView.tintColor = [UIColor greenColor];
        _progressView.trackTintColor = [UIColor lightGrayColor];
        _progressView.hidden=NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.progressView.hidden=YES;
}
#pragma mark -----基本用法----LCWebViewDelegate------------
- (BOOL)LC_webView:(LCWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(LCWebViewNavigationType)navigationType{
    /**例如,提交表单,NO
     if (navigationType==LCWebViewNavigationTypeFormSubmitted) {
     return NO;
     }
     */
    return YES;
}
/*
 *  开始加载
 */
- (void)LC_webViewDidStartLoad:(LCWebView *)webView{
    NSLog(@"开始加载");
}
/*
 * 加载结束
 */
- (void)LC_webViewDidFinishLoad:(LCWebView *)webView{
    NSLog(@"加载结束");
}
/*
 * 加载失败
 */
- (void)LC_webView:(LCWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"加载失败%@",error.localizedDescription);
}
/*
 *  js传递OC的字符串
 */
- (void)LC_jsCallWebViewReceiveString:(NSString *)string{
    NSLog(@"---js传递OC的字符串------%@",string);
    NSMutableDictionary *param = [self queryStringToDictionary:string];
    NSLog(@"get param:%@",[param description]);
    NSString *func = [param objectForKey:@"func"];
    //调用本地函数
    if([func isEqualToString:@"Alert"])//此处为样例
    {
        [self showMessage:@"来自网页的提示" message:[param objectForKey:@"message"]];
    }
    
}
//get参数转字典
- (NSMutableDictionary*)queryStringToDictionary:(NSString*)string {
    NSMutableArray *elements = (NSMutableArray*)[string componentsSeparatedByString:@"&"];
    NSMutableDictionary *retval = [NSMutableDictionary dictionaryWithCapacity:[elements count]];
    for(NSString *e in elements) {
        NSArray *pair = [e componentsSeparatedByString:@"="];
        [retval setObject:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
    }
    return retval;
}
-(void)showMessage:(NSString *)title message:(NSString *)message;
{
    if (message == nil) return;
    if (NSClassFromString(@"WKWebView")){
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"是" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *jsString=[NSString stringWithFormat:@"document.getElementsByTagName('p')[0].style.color='%@';",@"green"];
            [self.webView LC_evaluatJavaScript:jsString completionHandler:^(id _Nullable customObject, NSError * _Nullable error) {
                
            }];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"否" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSString *jsString=[NSString stringWithFormat:@"document.getElementsByTagName('p')[0].style.color='%@';",@"red"];
            [self.webView LC_evaluatJavaScript:jsString completionHandler:^(id _Nullable customObject, NSError * _Nullable error) {
                
            }];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    
    
    
}

#pragma mark -----更好的用户体验用法----LCWebViewWKSupplementDelegate------------

/*
 *  收到服务器响应决定是否跳转
 *  Example:
 *  if (mainFrame==NO) {
 *  return NO;
 *  }
 */
- (BOOL)LC_webView:(LCWebView *)webView decidePolicyForNavigationResponse:(NSURLResponse *)response IsForMainFrame:(BOOL)mainFrame{
    NSLog(@"收到服务器响应决定是否跳转");
    return YES;
}
/*
 *  接收服务器跳转请求之后调用
 */
-(void)LC_webView:(LCWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    NSLog(@"接收服务器跳转请求之后调用");
}
/*
 *  当内容开始返回时调用
 */
- (void)LC_webView:(LCWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"当内容开始返回时调用");
}
/** 此方法 解决多窗口问题 (例如 js中使用windows.open方法打开一个新窗口)
*/
- (nullable LCWebView *)LC_webView:(LCWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    NSLog(@"打开新窗口");
    if(navigationAction.targetFrame == nil || !navigationAction.targetFrame.isMainFrame)
    {
        [self loadRequest:navigationAction.request];
    }
    return nil;
}
/*
 *  证书验证
 */
- (void)LC_webView:(LCWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    //NSLog(@"权限认证. 注意测试iOS8系统,自签证书的验证是否可以");
    //completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
    
    NSString *hostName = webView.URL.host;
    
    NSString *authenticationMethod = [[challenge protectionSpace] authenticationMethod];
    if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodDefault]
        || [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
        || [authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        
        NSString *title = @"Authentication Challenge";
        NSString *message = [NSString stringWithFormat:@"%@ requires user name and password", hostName];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"User";
            //textField.secureTextEntry = YES;
        }];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Password";
            textField.secureTextEntry = YES;
        }];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            NSString *userName = ((UITextField *)alertController.textFields[0]).text;
            NSString *password = ((UITextField *)alertController.textFields[1]).text;
            
            NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:userName password:password persistence:NSURLCredentialPersistenceNone];
            
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertController animated:YES completion:^{}];
        });
        
    }
    else if ([authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // needs this handling on iOS 9
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        // or, see also http://qiita.com/niwatako/items/9ae602cb173625b4530a#%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB%E3%82%B3%E3%83%BC%E3%83%89
    }
    else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    
    
    
//    //忽略不受信任的证书
//    NSURLCredential *credential = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
//
//    completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    
}
/*
 *  WKwebView关闭
 */
- (void)LC_webViewDidClose:(LCWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)){
    NSLog(@"WKwebView关闭");
}
/*
 *  进程终止
 */
- (void)LC_webViewWebContentProcessDidTerminate:(LCWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0));
{
//    首先 在此处刷新[webView reload]高内存消耗,解决白屏; 其次,在viewWillAppear中检测到webview.title为空,则reload webview.
    NSLog(@"进程终止");
    [_webView LC_reload];
}
/*
 *  是否预览
 */
- (BOOL)LC_webView:(LCWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo API_AVAILABLE(macosx(10.12), ios(10.0)){
    NSLog(@"是否预览");
    return NO;
}
/*
 *  自定义预览视图
 */
- (nullable UIViewController *)LC_webView:(LCWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions API_AVAILABLE(macosx(10.12), ios(10.0)){
    NSLog(@"自定义预览视图");
    return nil;
}
/*
 *  提交预览视图
 */
- (void)LC_webView:(LCWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(macosx(10.12), ios(10.0)){
    NSLog(@"提交预览视图");
}


@end
