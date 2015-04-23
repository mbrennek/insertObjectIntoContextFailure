//
//  CDTPersistenceController.m
//  CDTest
//

#import "CDTPersistenceController.h"

@interface CDTPersistenceController ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *privateManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CDTPersistenceController

@synthesize managedObjectContext=_managedObjectContext;
@synthesize managedObjectModel=_managedObjectModel;
@synthesize persistentStoreCoordinator=_persistentStoreCoordinator;

#pragma mark - Object Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self saveContext];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(writingContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
}

#pragma mark - The Meat of the Bug

- (void)insertString:(NSString *)string intoContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *ent = [NSEntityDescription entityForName:@"AnObject" inManagedObjectContext:context];
    NSManagedObject *theObject = [[NSManagedObject alloc] initWithEntity:ent insertIntoManagedObjectContext:nil];

    // Do meat of the insert, creating attributes, checking to see if the object is really needed, etc
    [theObject setValue:string forKey:@"nameOfTheObject"];

    // If we decide the object is really needed, insert it into the context
    [context insertObject:theObject];

    // Create any relationships here

    // Save
    [self saveContext:context];
}

#pragma mark - Core Data stack

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CDTest" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CDTest.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_privateManagedObjectContext setPersistentStoreCoordinator:coordinator];
    _managedObjectContext.parentContext = _privateManagedObjectContext;
    return _managedObjectContext;
}

- (NSManagedObjectContext *)writingManagedObjectContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    return context;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    [self saveContext:self.managedObjectContext];
}

- (void)saveContext:(NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil) {
        __block BOOL parentChanges = NO;
        if (managedObjectContext.parentContext) {
            [managedObjectContext.parentContext performBlockAndWait:^{
                parentChanges = managedObjectContext.parentContext.hasChanges;
            }];
        }

        if ([managedObjectContext hasChanges] || parentChanges) {
            [managedObjectContext performBlockAndWait:^{
                NSError *error = nil;
                if(![managedObjectContext save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }];

            if (managedObjectContext.parentContext) {
                [managedObjectContext.parentContext performBlock:^{
                    NSError *parentError = nil;
                    if (![managedObjectContext.parentContext save:&parentError]) {
                        NSLog(@"Unresolved error %@, %@", parentError, [parentError userInfo]);

                        // Did you insert into the child context?
                        // KABOOM!
                        abort();
                    }
                }];
            }
        }
    }
}

- (void)writingContextDidSave:(NSNotification *)notif
{
    NSManagedObjectContext *savingContext = (NSManagedObjectContext *)notif.object;
    if (savingContext != self.managedObjectContext && savingContext != self.privateManagedObjectContext) {
        [self.managedObjectContext performBlock:^{
            [self mergeAndRefreshNotification:notif];
            [self saveContext];
        }];
    }
}

- (void)mergeAndRefreshNotification:(NSNotification *)saveNotification
{
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
}


@end
