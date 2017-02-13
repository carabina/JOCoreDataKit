//
//  ManagedObjectConvertible+Additions.swift
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

private let DeletionAgeBeforePermanentlyDeletingObjects = TimeInterval(2 * 60)

extension ManagedObjectConvertible where Self: NSManagedObject {
    
    public static var localIdKeyName: String {
        return "id"
    }
    
    public static var remoteIdKeyName: String {
        return "id"
    }
    
    public static var markedForLocalDeletionKey: String {
        return "markedForDeletionDate"
    }
    
    public static var markedForRemoteChangeKey: String {
        return "markedForRemoteChange"
    }
    
    public static var markedForRemoteDeletionKey: String {
        return "markedForRemoteDeletion"
    }
    
    /// returns the dictionary representation for the model
    public var dictionaryValue: [String: Any] {
        let modelMirror = Mirror(reflecting: self)
        var propertyKeysAndValues: [String: Any] = [:]
        for child in modelMirror.children {
            guard let propertyName = child.label else { continue }
            
            propertyKeysAndValues[propertyName] = child.value
        }
        
        return propertyKeysAndValues
    }
    
    /// Delete all the objects marked for local deletion
    public static func batchDeleteObjectsMarkedForLocalDeletion(in context: NSManagedObjectContext) {
        let cutoff = NSDate(timeIntervalSinceNow: -DeletionAgeBeforePermanentlyDeletingObjects)
        let predicate = NSPredicate(format: "%K < %@", markedForLocalDeletionKey, cutoff)
        deleteAll(in: context, matchingPredicate: predicate, shouldSyncChanges: true)
    }
    
    /// Delete all the objects from the entity, if saveChanges == true then the context
    /// will sync the changes inmediately, if saveChanged == false then the operation
    /// should sync the context
    public static func deleteAll(in context: NSManagedObjectContext, matchingPredicate predicate: NSPredicate?, shouldSyncChanges: Bool) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Self.entityName)
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        // when we drop ios 8 support we should use NSBatchDeleteRequest
        context.executeRequest(fetchRequest, completionHandler: { results, error in
            guard let elements = results as? [Self] , error == nil else { return }
            
            for element in elements {
                context.delete(element)
            }
            
            guard shouldSyncChanges == true else { return }
            
            context.saveChanges({
                guard let error = $0 else { return }
                
                print("error deleting the objects in the entity \(Self.entityName), error: \(error)")
            })
        })
    }
    
    /// Find/Create the object in core data
    public static func findOrCreate(in context: NSManagedObjectContext, matchingPredicate predicate: NSPredicate, configure: (Self) -> ()) -> Self {
        let object = fetch(in: context) { fetchRequest in
            fetchRequest.predicate = predicate
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchLimit = 1
        }
        
        guard let existingObject = object.first else {
            let newObject: Self = context.insertObject()
            configure(newObject)
            return newObject
        }
        
        configure(existingObject)
        return existingObject
    }
    
    /// Finds the first ocurrence of the object
    public static func findOrFetch(in context: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> Self? {
        var materializedObject: Self?
        
        context.performAndWait {
            if let object = self.materializedObject(in: context, matchingPredicate: predicate) {
                materializedObject = object
            }
            else {
                materializedObject = fetch(in: context) { request in
                    request.predicate = predicate
                    request.returnsObjectsAsFaults = false
                    request.fetchLimit = 1
                }.first
            }
        }
        
        return materializedObject
    }
    
    /// Fetch the object with the configured request
    public static func fetch(in context: NSManagedObjectContext, configurationBlock: (NSFetchRequest<Self>) -> () = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        var results: [Self] = []
        
        context.performAndWait {
            results = try! context.fetch(request)
        }
        
        return results
    }
    
    /// Inserts a new model in the given context
    public static func insert(in context: NSManagedObjectContext, configure: (Self) -> ()) -> Self {
        let newObject: Self = context.insertObject()
        configure(newObject)
        return newObject
    }
    
    /// returns the materialized object if exists
    public static func materializedObject(in moc: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> Self? {
        for obj in moc.registeredObjects where !obj.isFault && !obj.isDeleted {
            guard let res = obj as? Self , predicate.evaluate(with: res) else { continue }
            return res
        }
        
        return nil
    }
}
