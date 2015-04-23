//
//  AppDelegate.m
//  CDTest
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _persistenceController = [[CDTPersistenceController alloc] init];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.persistenceController saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.persistenceController saveContext];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.persistenceController saveContext];
}

@end
