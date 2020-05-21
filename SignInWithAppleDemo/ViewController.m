//
//  ViewController.m
//  SignInWithAppleDemo
//
//  Created by vivian on 2020/5/19.
//  Copyright © 2020 vivian. All rights reserved.
//

#import "ViewController.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "SAMKeychain.h"

NSString* const ShareCurrentIdentifier = @"ShareCurrentIdentifier";

@interface ViewController ()
<ASAuthorizationControllerDelegate, // 提供关于授权请求结果信息的接口
ASAuthorizationControllerPresentationContextProviding> // 控制器的代理找一个展示授权控制器的上下文的接口
@property (nonatomic, strong) UITextView *appleIDInfoTextView; //用于展示Sign In With Apple 登录过程的信息

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        [self observeAppleSignInState];
        [self setupUI];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self perfomExistingAccountSetupFlows];
}

#pragma mark - 添加苹果登录的状态通知

- (void)observeAppleSignInState {
    if (@available(iOS 13.0, *)) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(handleSignInWithAppleStateChanged:) name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
    }
}

#pragma mark - 观察SignInWithApple状态改变

- (void)handleSignInWithAppleStateChanged:(NSNotification *) noti {
    NSLog(@"%@", noti.name);
    NSLog(@"%@", noti.userInfo);
}

#pragma mark - 如果存在iCloud Keychain 凭证或者AppleID 凭证提示用户

- (void)perfomExistingAccountSetupFlows {
    if (@available(iOS 13.0, *)) {
        // 基于用户的Apple ID授权用户，生成用户授权请求的一种机制
        ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
        // 授权请求依赖于用于的AppleID
        ASAuthorizationAppleIDRequest *authAppleIDRequest = [appleIDProvider createRequest];
        // 为了执行钥匙串凭证分享生成请求的一种机制
        ASAuthorizationPasswordRequest *passwordRequest = [[ASAuthorizationPasswordProvider new] createRequest];
        
        NSMutableArray <ASAuthorizationRequest *>* mArr = [NSMutableArray arrayWithCapacity:2];
        if (authAppleIDRequest) {
            [mArr addObject:authAppleIDRequest];
        }
        if (passwordRequest) {
            [mArr addObject:passwordRequest];
        }
        // ASAuthorizationRequest：对于不同种类授权请求的基类
        NSArray <ASAuthorizationRequest *>* requests = [mArr copy];
        // ASAuthorizationController是由ASAuthorizationAppleIDProvider创建的授权请求 管理授权请求的控制器
        ASAuthorizationController *authorizationController = [[ASAuthorizationController alloc] initWithAuthorizationRequests:requests];
        // 设置授权控制器通知授权请求的成功与失败的代理
        authorizationController.delegate = self;
        // 设置提供 展示上下文的代理，在这个上下文中 系统可以展示授权界面给用户
        authorizationController.presentationContextProvider = self;
        // 在控制器初始化期间启动授权流
        [authorizationController performRequests];
    }
}

- (void)setupUI {
    self.appleIDInfoTextView = [[UITextView alloc] initWithFrame:CGRectMake(.0, 40.0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) * 0.4) textContainer:nil];
    self.appleIDInfoTextView.font = [UIFont systemFontOfSize:32.0];
    [self.view addSubview:self.appleIDInfoTextView];
    
    UIButton *removeKeyboardBtn = [[UIButton alloc] init];
    removeKeyboardBtn.backgroundColor = [UIColor grayColor];
    [removeKeyboardBtn setTitle:@"移除键盘" forState:UIControlStateNormal];
    removeKeyboardBtn.frame = CGRectMake(CGRectGetMidX(self.appleIDInfoTextView.frame) - 50.0, CGRectGetMaxY(self.appleIDInfoTextView.frame), 100.0, 40.0);
    [removeKeyboardBtn addTarget:self action:@selector(removeFirstResponder:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:removeKeyboardBtn];

    if (@available(iOS 13.0, *)) {
        ASAuthorizationAppleIDButton *appleIDButton = [ASAuthorizationAppleIDButton new];
        appleIDButton.frame =  CGRectMake(.0, .0, CGRectGetWidth(self.view.frame) - 40.0, 100.0);
        CGPoint origin = CGPointMake(20.0, CGRectGetMidY(self.view.frame));
        CGRect frame = appleIDButton.frame;
        frame.origin = origin;
        appleIDButton.frame = frame;
        appleIDButton.cornerRadius = CGRectGetHeight(appleIDButton.frame) * 0.25;
        [self.view addSubview:appleIDButton];
        [appleIDButton addTarget:self action:@selector(handleAuthrization:) forControlEvents:UIControlEventTouchUpInside];
    }
    NSMutableString *mutableString = [NSMutableString string];
    [mutableString appendString:@"显示Sign In With Apple 登录信息\n"];
    self.appleIDInfoTextView.text = [mutableString copy];
}


#pragma mark - 点击授权按钮

- (void)handleAuthrization:(UIButton *)sender {
    if (@available(iOS 13.0, *)) {
        // 基于用户的Apple ID授权用户，生成用户授权请求的一种机制
        ASAuthorizationAppleIDProvider *appleIDProvider = [ASAuthorizationAppleIDProvider new];
        // 创建新的AppleID 授权请求
        ASAuthorizationAppleIDRequest *request = appleIDProvider.createRequest;
        // 在用户授权期间请求的联系信息
        request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
        // 由ASAuthorizationAppleIDProvider创建的授权请求 管理授权请求的控制器
        ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
        // 设置授权控制器通知授权请求的成功与失败的代理
        controller.delegate = self;
        // 设置提供 展示上下文的代理，在这个上下文中 系统可以展示授权界面给用户
        controller.presentationContextProvider = self;
        // 在控制器初始化期间启动授权流
        [controller performRequests];
    }
}

#pragma mark - ASAuthorizationControllerDelegate

#pragma mark - 授权成功地回调

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization  API_AVAILABLE(ios(13.0)) {
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"%@", controller);
    NSLog(@"%@", authorization);
    NSLog(@"authorization.credential：%@", authorization.credential);
    NSMutableString *mutableString = [NSMutableString string];
    mutableString = [self.appleIDInfoTextView.text mutableCopy];
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
        // 用户登录使用ASAuthorizationAppleIDCredential
        ASAuthorizationAppleIDCredential *appleIDCredential = authorization.credential;
        NSString *user = appleIDCredential.user;
        // 使用钥匙串的方式保存用户的唯一信息
        NSString *bundleId = [NSBundle mainBundle].bundleIdentifier;
        [SAMKeychain setPassword:user forService:bundleId account:ShareCurrentIdentifier];
        [mutableString appendString:user?:@""];
        NSString *familyName = appleIDCredential.fullName.familyName;
        [mutableString appendString:familyName?:@""];
        NSString *givenName = appleIDCredential.fullName.givenName;
        [mutableString appendString:givenName?:@""];
        NSString *email = appleIDCredential.email;
        [mutableString appendString:email?:@""];
        NSLog(@"mStr：%@", mutableString);
        [mutableString appendString:@"\n"];
        self.appleIDInfoTextView.text = mutableString;
    } else if ([authorization.credential isKindOfClass:[ASPasswordCredential class]]) {
        // 用户登录使用现有的密码凭证
        ASPasswordCredential *passwordCredential = authorization.credential;
        // 密码凭证对象的用户标识 用户的唯一标识
        NSString *user = passwordCredential.user;
        // 密码凭证对象的密码
        NSString *password = passwordCredential.password;
        [mutableString appendString:user?:@""];
        [mutableString appendString:password?:@""];
        [mutableString appendString:@"\n"];
        NSLog(@"mStr：%@", mutableString);
        self.appleIDInfoTextView.text = mutableString;
    } else {
        NSLog(@"授权信息均不符");
        mutableString = [@"授权信息均不符" mutableCopy];
        self.appleIDInfoTextView.text = mutableString;
    }
}

#pragma mark - 授权失败的回调

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error  API_AVAILABLE(ios(13.0)) {
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"错误信息：%@", error);
    NSString *errorMsg = nil;
    switch (error.code) {
        case ASAuthorizationErrorCanceled:
            errorMsg = @"用户取消了授权请求";
            break;
        case ASAuthorizationErrorFailed:
            errorMsg = @"授权请求失败";
            break;
        case ASAuthorizationErrorInvalidResponse:
            errorMsg = @"授权请求响应无效";
            break;
        case ASAuthorizationErrorNotHandled:
            errorMsg = @"未能处理授权请求";
            break;
        case ASAuthorizationErrorUnknown:
            errorMsg = @"授权请求失败未知原因";
            break;
    }
    NSMutableString *mStr = [self.appleIDInfoTextView.text mutableCopy];
    [mStr appendString:errorMsg];
    [mStr appendString:@"\n"];
    self.appleIDInfoTextView.text = [mStr copy];
    if (errorMsg) {
        return;
    }
    if (error.localizedDescription) {
        NSMutableString *mStr = [self.appleIDInfoTextView.text mutableCopy];
        [mStr appendString:error.localizedDescription];
        [mStr appendString:@"\n"];
        self.appleIDInfoTextView.text = [mStr copy];
    }
    NSLog(@"controller requests：%@", controller.authorizationRequests);
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

#pragma mark - 告诉代理应该在哪个window 展示内容给用户

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller  API_AVAILABLE(ios(13.0)){
    NSLog(@"调用展示window方法：%s", __FUNCTION__);
    // 返回window
    return self.view.window;
}

#pragma mark - 点击移除键盘

- (void)removeFirstResponder:(id)gesture {
    [self.view endEditing:YES];
}

- (void)dealloc {
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
    }
}

@end
