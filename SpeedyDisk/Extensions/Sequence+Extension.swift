//
//  Sequence+Extension.swift
//  SpeedyDisk
//
//  Created by Doug on 7/5/22.
//

extension Sequence {
    func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
        return map { $0[keyPath: keyPath] }
    }
}
