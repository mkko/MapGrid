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
        
        print("new: \(newTiles)")
        print("removed: \(removedTiles)")
        
        return TileUpdate(newTiles: newTiles.map, removedTiles: removedTiles)
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
