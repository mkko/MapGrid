//
//  MapGrid.swift
//  Grid
//
//  Created by Mikko Välimäki on 17-05-07.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import Foundation
import MapKit

public struct MapTile {
    public let mapIndex: MapIndex
}

extension MapTile: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "(x:\(self.mapIndex.index.x), y:\(self.mapIndex.index.y))"
    }
}

public struct TileUpdate {
    public let newTiles: [MapTile]
    public let removedTiles: [MapTile]
}

public struct MapIndex {
    internal let index: GridIndex
}

extension MapIndex: Equatable {
    
    public static func ==(lhs: MapIndex, rhs: MapIndex) -> Bool {
        return lhs.index == rhs.index
    }
}

//public struct GridSize {
//    let width, height: Int
//}

//public struct GridRect {
//    let origin: GridIndex
//    let size: GridSize
//}

//extension GridRect {
//    
//    static var empty: GridRect {
//        return GridRect(origin: GridIndex(x: 0, y: 0), size: GridSize(width: 0, height: 0))
//    }
//}

//extension GridRect {
//    
//    func asIndices() -> [GridIndex] {
//        
//        let dx = origin.x...(origin.x + size.width)
//        let dy = origin.y...(origin.y + size.height)
//        
//        return dx.flatMap { x in
//            dy.map { y in GridIndex(x: x, y: y) }
//        }
//    }
//}

public class MapGrid {
    
    var grid: Grid<MapTile>
    
    let tileLatitudinalSize: CLLocationDistance
    
    let tileLongitudinalSize: CLLocationDistance
    
    public convenience init(tileSize: CLLocationDistance) {
        self.init(tileLatitudinalSize: tileSize, tileLongitudinalSize: tileSize)
    }
    
    public init(tileLatitudinalSize: CLLocationDistance, tileLongitudinalSize: CLLocationDistance) {
        self.tileLatitudinalSize = tileLatitudinalSize
        self.tileLongitudinalSize = tileLongitudinalSize
        
        grid = Grid<MapTile>()
    }
    public func update(visibleRegion region: MKCoordinateRegion) -> TileUpdate {
        let gridIndices = getGridRect(forRegion: region, withOrigin: self.regionOfOrigin)
        return update(visibleIndices: gridIndices)
    }
    
    /**
     Load tiles for the given indices. Returns the delta.
     */
    public func update(visibleIndices: [MapIndex]) -> TileUpdate {
        
        // TODO: Could be improved in performance.
        
        
//        let newTiles = visibleIndices.filter { mapIndex -> Bool in
//            return !grid.contains(index: mapIndex.index)
//        }.map { index in
//            return MapTile(mapIndex: index)
//        }
        
        var visibleGridIndices = visibleIndices.map { $0.index }
        var existingTiles = [MapTile]()
        var removedTiles = [MapTile]()
        
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
        var newTiles = [MapTile]()
        for gridIndex in visibleGridIndices {
            let tile = MapTile(mapIndex: MapIndex(index: gridIndex))
            newTiles.append(tile)
            grid[gridIndex] = tile
        }
        
//        let visible = visibleIndices.reduce((existing: [MapTile](), new: [MapTile]())) { acc, index in
//            if let tile = grid[index.index] {
//                return (
//                    existing: acc.existing + [tile],
//                    new: acc.new
//                )
//            } else {
//                return (
//                    existing: acc.existing,
//                    new: acc.new + [MapTile(mapIndex: index)]
//                )
//            }
//        }
//        
//        let items = visible.existing + visible.new
//        
//        let nextGrid = Grid<MapTile>()
//        for item in items {
//            nextGrid[item.mapIndex.index] = item
//        }
//        self.grid = nextGrid
        
        print("new: \(newTiles)")
        print("removed: \(removedTiles)")
        
        return TileUpdate(newTiles: newTiles, removedTiles: removedTiles)

        
        // Get the new tiles first.
        
//        let x = visibleIndices.map { index -> (tile: MapTile, existed: Bool) in
//            if let tile = grid[index.index] {
//                return (tile, true)
//            } else {
//                return (MapTile(mapIndex: index), false)
//            }
//        }
//        
//        var newTiles: [MapTile] = []
//        for index in visibleIndices {
//            if grid[index.index] == nil {
//                let mapTile = MapTile(mapIndex: index)
//                newTiles.append(mapTile)
//                grid[index.index] = mapTile
//            } else {
//                // Index exists, do nothing.
//            }
//        }
//        
//        var removedTiles: [MapTile] = []
//        for tile in grid {
//            if !visibleIndices.contains(tile.mapIndex) {
//                removedTiles.append(tile)
//            } else {
//                // Exists on both.
//            }
//        }
//        
//        grid.remove(indices: removedTiles.map { $0.mapIndex.index })
//        
//        return TileUpdate(newTiles: newTiles, removedTiles: removedTiles)
        
//        let nextTiles = grid.reduce((existing: [MapTile](), removed: [MapTile]())) { result, tile in
//            if visibleIndices.contains(tile.index) {
//                return (
//                    existing: result.existing + [tile],
//                    removed: result.removed
//                )
//            } else {
//                return (
//                    existing: result.existing,
//                    removed: result.removed + [tile]
//                )
//            }
//        }
        
        //self.tiles = nextTiles.existing + newTiles
        
        
        
//        let s = visibleIndices.flatMap { gidx -> MapTile? in
//            if grid[gidx.x, gidx.y] == nil {
//                // New tile
//                let tile = MapTile()
//                grid[gidx.x, gidx.y] = tile
//                return tile
//            } else {
//                return nil
//            }
//        }
//        
//        return TileUpdate()
    }
    
    var regionOfOrigin: MKCoordinateRegion {
        return MKCoordinateRegionMakeWithDistance(
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            tileLatitudinalSize, tileLongitudinalSize)
    }
}

fileprivate func getGridRect(forRegion region: MKCoordinateRegion, withOrigin origin: MKCoordinateRegion) -> [MapIndex] {
    
    let north = (region.center.latitude + region.span.latitudeDelta / 2.0) - origin.center.latitude
    let east = (region.center.longitude + region.span.longitudeDelta / 2.0) - origin.center.longitude
    let south = (region.center.latitude - region.span.latitudeDelta / 2.0) - origin.center.latitude
    let west = (region.center.longitude - region.span.longitudeDelta / 2.0) - origin.center.longitude
    
    let y1 = Int(floor(south / origin.span.latitudeDelta))
    let y2 = Int(ceil(north / origin.span.latitudeDelta))
    
    let x1 = Int(floor(west / origin.span.longitudeDelta))
    let x2 = Int(ceil(east / origin.span.longitudeDelta))
    
    
    return (x1...x2).flatMap { x in
        (y1...y2).map { y in MapIndex(index: GridIndex(x: x, y: y)) }
    }
}

//fileprivate func MKMapRectForCoordinateRegion(_ region: MKCoordinateRegion) -> MKMapRect {
//    let a: MKMapPoint = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2.0, region.center.longitude - region.span.longitudeDelta / 2.0))
//    let b: MKMapPoint = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2.0, region.center.longitude + region.span.longitudeDelta / 2.0))
//    return MKMapRectMake(min(a.x, b.x), min(a.y, b.y), abs(a.x - b.x), abs(a.y - b.y))
//}
