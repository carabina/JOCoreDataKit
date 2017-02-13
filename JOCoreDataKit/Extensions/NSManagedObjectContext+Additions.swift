//
//  NSManagedObjectContext+Additions.swift
//
//  Copyright © 2017. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import CoreData

extension NSManagedObjectContext {
    
    /// creates a background context to perform a task
    public final func createBackgroundContext() -> NSManagedObjectContext {
        let internalContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        internalContext.persistentStoreCoordinator = persistentStoreCoordinator
        internalContext.mergePolicy = NSOverwriteMergePolicy
        return internalContext
    }
    
    /// Creates the main context for the app
    public static func createMainContext(in url: URL, name: String, bundle: Bundle = Bundle.main) -> NSManagedObjectContext {
        let storeURL = url.appendingPathComponent("\(name).sqlite")
        
        /// Force unwrap this model, because this would only fail if we haven't
        /// included the xcdatamodel in our app resources.
        let url = bundle.url(forResource: name, withExtension: "momd")
        let model =  NSManagedObjectModel(contentsOf: url!)! //NSManagedObjectModel.mergedModel(from: [bundle ?? Bundle.main])!
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        
        var error = persistentStoreCoordinator.createPersistentStore(atURL: storeURL)
        
        if persistentStoreCoordinator.persistentStores.isEmpty {
            /// Our persistent store does not contain irreplaceable data (which
            /// is why it's in the Caches folder). If we fail to add it, we can
            /// delete it and try again.
            context.persistentStoreCoordinator?.destroyPersistentStore(atURL: storeURL)
            error = persistentStoreCoordinator.createPersistentStore(atURL: storeURL)
        }
        
        if persistentStoreCoordinator.persistentStores.isEmpty {
            error = persistentStoreCoordinator.createPersistentStore(atURL: nil)
            print(".Falling back to `.InMemory` store.")
        }
        
        if let error = error {
            print("Error creating SQLite store: \(error)")
        }
        
        return context
    }
    
    /// Returns the entity description
    public func entity(for name: String) -> NSEntityDescription {
        guard
            // store coordinator
            let persistentStoreCoordinator = persistentStoreCoordinator,
        
            // entity
            let entity = persistentStoreCoordinator.managedObjectModel.entitiesByName[name] else { fatalError("Conditions fails") }
        
        return entity
    }
    
    /// Execute the request in the current context
    public func executeRequest(_ request: NSFetchRequest<NSFetchRequestResult>, completionHandler: @escaping ([AnyObject], NSError?) -> Void){
        perform {
            var results: [AnyObject] = []
            var error: NSError?
            do {
                results = try self.fetch(request)
            } catch let requestError as NSError {
                error = requestError
            }
            
            completionHandler(results, error)
        }
    }
    
    /// Inserts a new object in the current context
    ///
    /// Element - The core data model to insert
    public func insertObject<Element: NSManagedObject>() -> Element where Element: ManagedObjectConvertible {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: Element.entityName, into: self) as? Element else { fatalError("Wrong object type") }
        
        return obj
    }
    
    /// Save the changes in the current context
    public func saveChanges(_ completionHandler: @escaping (NSError?) -> Void) {
        perform {
            var error: NSError?
            
            if self.hasChanges {
                do {
                    try self.save()
                }
                catch let saveError as NSError {
                    error = saveError
                    print("unable to store the data error: \(error)")
                }
            }
            
            completionHandler(error)
        }
    }
    
    /// Merges the changes specified in notification object received from another context's
    /// In the context queue
    public func performMergeChangesFromContextDidSaveNotification(_ notification: Notification, completionHandler: (() -> Void)? = nil) {
        perform {
            self.mergeChanges(fromContextDidSave: notification)
            completionHandler?()
        }
    }
}
