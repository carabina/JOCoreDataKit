//
//  NSPersistentStoreCoordinator+Additions.swift
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

extension NSPersistentStoreCoordinator {
    
    // MARK: Instance methods
    
    /// creates a new store
    /// 
    /// url  - the location for the store
    /// type - the store type
    @discardableResult
    public func createPersistentStore(atURL url: URL?, type: String = NSSQLiteStoreType) -> Error? {
        var error: Error?
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            try addPersistentStore(ofType: type, configurationName: nil, at: url, options: options)
        }
        catch let storeError {
            error = storeError
        }
        
        return error
    }
    
    /// destroy the persistent store for the given context
    ///
    /// url  - the url for the store location
    /// type - the store type
    public func destroyPersistentStore(atURL url: URL, type: String = NSSQLiteStoreType) {
        do {
            if #available(iOS 9.0, *) {
                try destroyPersistentStore(at: url, ofType: type, options: nil)
            }
            else if let persistentStore = persistentStores.last {
                try remove(persistentStore)
                try FileManager.default.removeItem(at: url)
            }
        }
        catch {
            print("unable to destroy perstistent store at url: \(url), type: \(type)")
        }
    }
    
    /// migrates the current store to the given url
    ///
    /// url - the new location for the store
    public func migrate(to url: URL) {
        guard let currentStore = persistentStores.last else { return }
        
        try! migratePersistentStore(currentStore, to: url, options: nil, withType: NSSQLiteStoreType)
    }
}
