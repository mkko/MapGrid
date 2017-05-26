//
//  MapGrid.swift
//  Grid
//
//  Created by Mikko Välimäki on 17-05-07.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import Foundation
import MapKit

public struct MapTile<T> {
    public let mapIndex: MapIndex
    public let item: T
}

extension MapTile: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "(x:\(self.mapIndex.index.x), y:\(self.mapIndex.index.y), item: \(item))"
    }
}

public struct TileUpdate<T> {
    public let newTiles: [MapTile<T>]
    public let removedTiles: [MapTile<T>]
}

public struct MapIndex {
    internal let index: GridIndex
}

extension MapIndex: Equatable {
    
    public static func ==(lhs: MapIndex, rhs: MapIndex) -> Bool {
        return lhs.index == rhs.index
    }
}

public class MapGrid<T> {
    
    var grid: Grid<MapTile<T>>
    
    let tileLatitudinalSize: CLLocationDistance
    
    let tileLongitudinalSize: CLLocationDistance
    
    // Protocols don't support generics the way it is needed here, so we use base class.
    private let factory: TileFactory<T>
    
    public var visibleTiles: [MapTile<T>] {
        return grid.getTiles().map { $0.1 }
    }
    
    public convenience init(tileSize: CLLocationDistance, factory: TileFactory<T>) {
        self.init(tileLatitudinalSize: tileSize, tileLongitudinalSize: tileSize, factory: factory)
    }
    
    public init(tileLatitudinalSize: CLLocationDistance, tileLongitudinalSize: CLLocationDistance, factory: TileFactory<T>) {
        self.tileLatitudinalSize = tileLatitudinalSize
        self.tileLongitudinalSize = tileLongitudinalSize
        
        self.grid = Grid<MapTile<T>>()
        self.factory = factory
    }
    
    public func update(visibleRegion region: MKCoordinateRegion) -> TileUpdate<T> {
        let gridIndices = getGridRect(forRegion: region, withOrigin: self.regionOfOrigin)
        return update(visibleIndices: gridIndices)
    }
    
    public func region(at mapIndex: MapIndex) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: self.regionOfOrigin.span.latitudeDelta * (Double(mapIndex.index.y)+0.5),
                longitude: self.regionOfOrigin.span.longitudeDelta * (Double(mapIndex.index.x)+0.5)),
            span: self.regionOfOrigin.span)
    }
    
    /**
     Load tiles for the given indices. Returns the delta.
     */
    private func update(visibleIndices: [MapIndex]) -> TileUpdate<T> {
        
        // TODO: Could be improved in performance.
        var visibleGridIndices = visibleIndices.map { $0.index }
        var existingTiles = [MapTile<T>]()
        var removedTiles = [MapTile<T>]()
        
        // Check the existing ones first.
        for (index, mapTile) in grid.getTiles() {
            if let i = visibleGridIndices.index(of: index) {
                // The tile exists.
                visibleGridIndices.remove(at: i)
                existingTiles.append(mapTile)
            } else {
                // The tile doesn't exist, so remove it.
                grid.remove(index: index)
                removedTiles.append(mapTile)
            }
        }
        
        // Remaining visible indices should be new.
        var newTiles = [MapTile<T>]()
        for gridIndex in visibleGridIndices {
            let mapIndex = MapIndex(index: gridIndex)
            let item = self.factory.value(forMapIndex: mapIndex, inMapGrid: self)
            let tile = MapTile(mapIndex: mapIndex, item: item)
            newTiles.append(tile)
            grid[gridIndex] = tile
        }
        
//        print("new: \(newTiles)")
//        print("removed: \(removedTiles)")
        
        return TileUpdate(newTiles: newTiles, removedTiles: removedTiles)
    }
    
    var regionOfOrigin: MKCoordinateRegion {
        return MKCoordinateRegionMakeWithDistance(
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            tileLatitudinalSize, tileLongitudinalSize)
    }
}

fileprivate func getGridRect(forRegion region: MKCoordinateRegion, withOrigin origin: MKCoordinateRegion) -> [MapIndex] {
    
    let north = (region.center.latitude + region.span.latitudeDelta / 2.0) - origin.center.latitude
    let south = (region.center.latitude - region.span.latitudeDelta / 2.0) - origin.center.latitude
    let east = (region.center.longitude + region.span.longitudeDelta / 2.0) - origin.center.longitude
    let west = (region.center.longitude - region.span.longitudeDelta / 2.0) - origin.center.longitude
    
    let y1 = Int(floor(south / origin.span.latitudeDelta))
    let y2 = Int(floor(north / origin.span.latitudeDelta))
    
    let x1 = Int(floor(west / origin.span.longitudeDelta))
    let x2 = Int(floor(east / origin.span.longitudeDelta))
    
    
    return (x1...x2).flatMap { x in
        (y1...y2).map { y in MapIndex(index: GridIndex(x: x, y: y)) }
    }
}
