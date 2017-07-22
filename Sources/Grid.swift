//
//  Grid.swift
//  Grid
//
//  Created by Mikko Välimäki on 17-05-07.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import Foundation

struct GridIndex {
    let x, y: Int
}

struct GridTile<T> {
    let index: GridIndex
    let item: T
}

extension GridIndex: Equatable {
    
    public static func ==(lhs: GridIndex, rhs: GridIndex) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension GridIndex: Hashable {
    
    public var hashValue: Int {
        var hash = 5381
        hash = ((hash << 5) &+ hash) &+ x
        hash = ((hash << 5) &+ hash) &+ y
        return hash
    }
}

struct Grid<T> {
    
    //private var rows = ExpandingCollection<ExpandingCollection<T>>()
    //private var indices = [GridIndex: T]()
    
    init() {
    }
    
    // For the lack of better hash, try to avoid overlap with nested dictionaries.
    fileprivate var rows = [Int: [Int:T]]()
    
    subscript(index: GridIndex) -> T? {
        get { return self[index.x, index.y] }
        set { self[index.x, index.y] = newValue }
    }
    
    subscript(x: Int, y: Int) -> T? {
        get { return rows[y]?[x] }
        set {
            var row = rows[y] ?? [Int: T]()
            row[x] = newValue
            rows.updateValue(row, forKey: y)
        }
    }
    
//    private func getRow(at: Int) -> ExpandingCollection<T> {
//        if let row = rows[at] {
//            return row
//        } else {
//            let row = ExpandingCollection<T>()
//            rows[at] = row
//            return row
//        }
//    }
    
    func contains(index: GridIndex) -> Bool {
        return self[index] != nil
    }
    
    func getTiles() -> [(GridIndex, T)] {
        return rows.flatMap { y, row in
            return row.map { x, item in
                return (GridIndex(x: x, y: y), item)
            }
        }
    }
    
    mutating func remove(index: GridIndex) {
        self[index] = nil
    }
    
    mutating func remove(indices: [GridIndex]) {
        for index in indices {
            remove(index: index)
        }
    }
}

internal class ExpandingCollection<T> {
    
    var items: [T?] = []
    var origin: Int = 0
    
    subscript(index: Int) -> T? {
        get {
            return items[safe: map(index: index)] ?? nil
        }
        set {
            expand(to: index)
            let mapped: Int = map(index: index)
            items[mapped] = newValue
        }
    }
    
    private func map(index: Int) -> Int {
        return index - self.origin
    }
    
    private func expand(to index: Int) {
        var mapped: Int = map(index: index)
        // Pad to the right.
        while mapped >= items.count {
            items.append(nil)
        }
        
        // Pad to the left.
        while mapped < 0 {
            items.insert(nil, at: 0)
            origin = origin - 1
            // Re-evaluate the mapped value.
            mapped = map(index: index)
        }
    }
}

extension Collection where Indices.Iterator.Element == Index {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Sequence implementation

extension Grid: Sequence {
    
    func makeIterator() -> GridIterator<T> {
        return GridIterator(self)
    }
}


struct GridIterator<T>: IteratorProtocol {
    
    let grid: Grid<T>
    
    init(_ grid: Grid<T>) {
        self.grid = grid
    }
    
    mutating func next() -> T? {
        return nil
    }
}

extension Grid: CustomDebugStringConvertible {
    
    var debugDescription: String {
        let rows = self.rows.map { row, value -> String in
            let cols = value.map { col, _ -> String in
                return "\(col)"
            }.joined(separator: ",")
            return "\(row): \(cols)"
        }.joined(separator: ",")
        return "Grid:\n\(rows)"
    }
}
