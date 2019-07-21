//
//  File.swift
//  
//
//  Created by Vladislav Prusakov on 21.07.2019.
//

import Foundation

struct ObserverSet<T: AnyObject>: Sequence {
    
    private var delegates: Set<Weak<T>> = []
    
    func makeIterator() -> SetIterator<Weak<T>> {
        return self.delegates.makeIterator()
    }
    
    @discardableResult
    mutating func insert(_ newMember: T) -> (inserted: Bool, memberAfterInsert: Weak<T>) {
        self.removeDestroyedObservers()
        return self.delegates.insert(Weak(value: newMember))
    }
    
    
    private mutating func removeDestroyedObservers() {
        let destroyedObservers = self.delegates.filter { $0.value == nil }
        destroyedObservers.forEach { observerContainer in
            self.delegates.remove(observerContainer)
        }
    }
    
    mutating func remove(_ member: T) {
        guard let container = self.delegates.first(where: { $0.value === member }) else { return }
        self.delegates.remove(container)
    }
}

extension ObserverSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.delegates = Set(elements.map(Weak.init))
    }
}

struct Weak<T: AnyObject>: Hashable {
    
    weak var value: T?
    private let pointeeHash: Int
    
    init(value: T) {
        self.value = value
        self.pointeeHash = withUnsafePointer(to: &self.value) { UnsafeRawPointer($0).hashValue }
    }
    
    // MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.pointeeHash)
    }
    
    // MARK: Equtable
    
    static func ==(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
        return lhs.value === rhs.value && lhs.pointeeHash == rhs.pointeeHash
    }
}


