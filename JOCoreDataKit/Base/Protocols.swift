//
//  Protocols.swift
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

public protocol ContextObservable: class {
    /// Invoked when a new notification is fired
    func contextDidSaveNotification(_ notification: Notification)
}

public protocol ManagedObjectConvertible: class {
    associatedtype ResultType: NSFetchRequestResult
    
    /// The Core Data entity name
    static var entityName: String { get }
    
    /// The fetch request for the entity
    static var sortedFetchRequest: NSFetchRequest<NSFetchRequestResult> { get }
    
    /// returns the dictionary representantion
    var dictionaryValue: [String: Any] { get }
    
    /// Delete all the objects from the entity, if saveChanges == true then the context
    /// will sync the changes inmediately, if saveChanged == false then the operation
    /// should sync the context
    static func deleteAll(in context: NSManagedObjectContext, matchingPredicate predicate: NSPredicate?, shouldSyncChanges: Bool)
    
    /// Finds or create a new managed object
    @discardableResult
    static func findOrCreate(in context: NSManagedObjectContext, matchingPredicate predicate: NSPredicate, configure: (Self) -> ()) -> Self
    
    /// Finds the first ocurrence of the object
    @discardableResult
    static func findOrFetch(in context: NSManagedObjectContext, matchingPredicate predicate: NSPredicate) -> Self?
    
    /// Inserts a new model in the given context
    @discardableResult
    static func insert(in context: NSManagedObjectContext, configure: (Self) -> ()) -> Self
    
    /// Inserts or return a model in the given context
    @discardableResult
    static func insertOrUpdate(in context: NSManagedObjectContext, dictionary: [String: Any]) -> Self?
}

public protocol RemoteSyncronizable: ManagedObjectConvertible {

    /// the name for the local id field
    static var localIdKeyName: String { get }
    
    /// the name for the local deletion key
    static var markedForLocalDeletionKey: String { get }
    
    /// the name for the remote change key
    static var markedForRemoteChangeKey: String { get }
    
    /// the name for the remote deletion key
    static var markedForRemoteDeletionKey: String { get }
    
    /// the primary key in the remote store
    var remoteId: String { get }
    
    /// the name for the remote id field
    static var remoteIdKeyName: String { get }
}
