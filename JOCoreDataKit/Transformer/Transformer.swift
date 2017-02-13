//
//  ValueTransformer.swift
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

import Foundation

public class Transformer<A: AnyObject, B: AnyObject>: ValueTransformer {
    
    public typealias Transform = (A?) -> B?
    public typealias ReverseTransform = (B?) -> A?
    
    private let transform: Transform
    private let reverseTransform: ReverseTransform
    
    public init(transform: @escaping Transform, reverseTransform: @escaping ReverseTransform) {
        self.transform = transform
        self.reverseTransform = reverseTransform
        super.init()
    }
    
    // MARK: Static methods
    
    public static func registerTransformer(with name: String, transform: @escaping Transform, reverseTransform: @escaping ReverseTransform) {
        let valueTransformer = Transformer(transform: transform, reverseTransform: reverseTransform)
        ValueTransformer.setValueTransformer(valueTransformer, forName: NSValueTransformerName(rawValue: name))
    }

    /// MARK: Overrrided methods
    
    public override static func transformedValueClass() -> AnyClass {
        return B.self
    }
    
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    public override func transformedValue(_ value: Any?) -> Any? {
        return transform(value as? A)
    }
    
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        return reverseTransform(value as? B)
    }
}
