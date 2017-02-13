//
//  ContextObserver.swift
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

public protocol ManagedObjectContextObservable: class {
    func contextObserver(observer: ContextObserver, didUpdate update: [String: [NSManagedObject]])
}

public final class ContextObserver {
    
    private let context: NSManagedObjectContext
    private var internalPredicate: NSPredicate?
    
    public weak var delegate: ManagedObjectContextObservable?
    
    // MARK: Initialization
    
    public init(context: NSManagedObjectContext) {
        self.context = context
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidSaveNotification(_:)),
                                               name: NSNotification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    public convenience init(context: NSManagedObjectContext, entityName: String, predicate: NSPredicate) {
        self.init(context: context)
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError() }
        
        observeEntity(entityDescription, predicate: predicate)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Instance methods
    
    /// add a new predicate observer for the given entity
    ///
    /// name      - the name of the entity in the database
    /// predicate - a custom predicate to evaluate the objects
    public final func observeEntityWithName(_ name: String, predicate: NSPredicate) {
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else { fatalError() }
        
        observeEntity(entity, predicate: predicate)
    }
    
    /// add a new predicate observer for the given entity
    ///
    /// entity    - the entity description
    /// predicate - a custom predicate to evaluate the objects
    public final func observeEntity(_ entity: NSEntityDescription, predicate: NSPredicate) {
        guard let name = entity.name else { fatalError() }
        
        var predicates = [NSPredicate(format: "entity.name == %@", name), predicate]
        let __predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        if internalPredicate == nil {
            internalPredicate = __predicate
        }
        else if let predicate = internalPredicate {
            predicates = [predicate, __predicate]
            internalPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
    }
    
    // MARK: Notification methods
    
    @objc func managedObjectContextDidSaveNotification(_ notification: Notification) {
        guard let
            /// the predicate
            predicate = internalPredicate,
        
            /// the saved context
            let context = notification.object as? NSManagedObjectContext,
        
            /// the user info
            let userInfo = notification.userInfo, context !== self.context else { return }
        
        var results: [String: [NSManagedObject]] = [:]
        
        if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> , insertedObjects.isEmpty == false {
            results[NSInsertedObjectsKey] = insertedObjects.filter({ predicate.evaluate(with: $0) })
        }
        
        if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> , deletedObjects.isEmpty == false {
            results[NSDeletedObjectsKey] = deletedObjects.filter({ predicate.evaluate(with: $0) })
        }
        
        if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> , updatedObjects.isEmpty == false {
            results[NSUpdatedObjectsKey] = updatedObjects.filter({ predicate.evaluate(with: $0) })
        }
        
        guard results.values.reduce([], { $0 + $1 }).count > 0 else { return }
        
        DispatchQueue.main.async {
            self.delegate?.contextObserver(observer: self, didUpdate: results)
        }
    }
}
