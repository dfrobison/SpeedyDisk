//
//  IdentifiedArray+Extension.swift
//  SpeedyDisk
//
//  Created by Doug on 7/5/22.
//
import ComposableArchitecture

extension IdentifiedArray {
    mutating func sort<T: Comparable>(by keyPath: KeyPath<Element, T>) {
        
        if self.count < 2 {
            return
        }
        
        sort { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}
