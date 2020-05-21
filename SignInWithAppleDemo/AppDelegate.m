//
//  AppDelegate.m
//  SignInWithAppleDemo
//
//  Created by vivian on 2020/5/19.
//  Copyright © 2020 vivian. All rights reserved.
//

#import "AppDelegate.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "ViewController.h"
#import "SAMKeychain.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
    [self.window makeKeyAndVisible];
    NSString *bundleId = [NSBundle mainBundle].bundleIdentifier;
    NSString *userIdentifier = [SAMKeychain passwordForService:bundleId account:ShareCurrentIdentifier];
    [self checkAuthorizationStateWithUser:userIdentifier completeHandler:nil];
    return YES;
}

#pragma mark - 使用 user 信息，查询当前用户的状态

- (void) checkAuthorizationStateWithUser:(NSString *) user
                         completeHandler:(void(^)(BOOL authorized, NSString *msg)) completeHandler {
    if (user == nil || user.length <= 0) {
        if (completeHandler) {
            completeHandler(NO, @"用户标识符错误");
        }
        return;
    }
    ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc]init];
    [provider getCredentialStateForUserID:user completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError * _Nullable error) {
        NSString *msg = @"未知";
        BOOL authorized = NO;
        switch (credentialState) {
            case ASAuthorizationAppleIDProviderCredentialRevoked:
                msg = @"授权被撤销";
                authorized = NO;
                break;
            case ASAuthorizationAppleIDProviderCredentialAuthorized:
                msg = @"已授权";
                authorized = YES;
                break;
            case ASAuthorizationAppleIDProviderCredentialNotFound:
                msg = @"未查到授权信息";
                authorized = NO;
                break;
            case ASAuthorizationAppleIDProviderCredentialTransferred:
                msg = @"授权信息变动";
                authorized = NO;
                break;
            default:
                authorized = NO;
                break;
        }
        if (completeHandler) {
            completeHandler(authorized, msg);
        }
    }];
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentCloudKitContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentCloudKitContainer alloc] initWithName:@"SignInWithAppleDemo"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
