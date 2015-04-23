//
//  AppDelegate.h
//  CDTest
//

@import UIKit;

#import "CDTPersistenceController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) CDTPersistenceController *persistenceController;

@end

