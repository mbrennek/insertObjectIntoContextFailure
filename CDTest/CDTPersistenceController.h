//
//  CDTPersistenceController.h
//  CDTest
//

@import Foundation;
@import CoreData;

@interface CDTPersistenceController : NSObject

- (void)insertString:(NSString *)string intoContext:(NSManagedObjectContext *)context;

- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectContext *)writingManagedObjectContext;

- (void)saveContext;

@end
