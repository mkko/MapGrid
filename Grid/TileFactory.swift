//
//  TileFactory.swift
//  Grid
//
//  Created by Mikko Välimäki on 17-05-21.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import Foundation

open class TileFactory<T> {
    
    public init() {
    }
    
    open func value(forMapIndex mapIndex: MapIndex, inMapGrid mapGrid: MapGrid<T>) -> T {
        NSLog("value(forMapIndex:inMapGrid:) not implemented")
        abort()
    }
}

final class BlockBasedTileFactory<T>: TileFactory<T> {
    
    private let create: (MapIndex, MapGrid<T>) -> T
    
    init(create: @escaping (MapIndex, MapGrid<T>) -> T) {
        self.create = create
    }
    
    override func value(forMapIndex mapIndex: MapIndex, inMapGrid mapGrid: MapGrid<T>) -> T {
        return self.create(mapIndex, mapGrid)
    }
}
