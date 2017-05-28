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

public struct TileDelta<T> {
    public let newTiles: [MapTile<T>]
    public let removedTiles: [MapTile<T>]
}

// TODO: Might be redundant.
public struct MapIndex {
    internal let index: GridIndex
}

extension MapIndex: Equatable {
    
    public static func ==(lhs: MapIndex, rhs: MapIndex) -> Bool {
        return lhs.index == rhs.index
    }
}

public struct MapGrid<T> {
    
    fileprivate var grid: Grid<MapTile<T>>
    
    let tileLatitudinalSize: CLLocationDistance
    
    let tileLongitudinalSize: CLLocationDistance
    
    public var tiles: [MapTile<T>] {
        return grid.getTiles().map { $0.1 }
    }
    
    // MARK: Init
    
    public init(tileSize: CLLocationDistance) {
        self.init(tileLatitudinalSize: tileSize, tileLongitudinalSize: tileSize)
    }
    
    public init(tileLatitudinalSize: CLLocationDistance, tileLongitudinalSize: CLLocationDistance) {
        self.tileLatitudinalSize = tileLatitudinalSize
        self.tileLongitudinalSize = tileLongitudinalSize
        
        self.grid = Grid<MapTile<T>>()
    }
    
    // MARK: Indexing
    
    public func tiles(atRegion region: MKCoordinateRegion) -> [MapTile<T>] {
        let gridIndices = region.getGridRect(withOrigin: self.regionOfOrigin)
        return gridIndices.flatMap { self.grid[$0] }
    }
    
    public func tile(atCoordinates coordinate: CLLocationCoordinate2D) -> MapTile<T>? {
        let mapIndex = getIndex(forCoordinate: coordinate, withOrigin: self.regionOfOrigin)
        return self.grid[mapIndex.index]
    }

    // MARK: Public
    
    public func region(at mapIndex: MapIndex) -> MKCoordinateRegion {
        return mapIndex.index.getRegion(forOrigin: self.regionOfOrigin)
    }
    
    // MARK: Privates
    
    var regionOfOrigin: MKCoordinateRegion {
        return MKCoordinateRegionMakeWithDistance(
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            tileLatitudinalSize, tileLongitudinalSize)
    }
}

// MARK: - Mutable
extension MapGrid {
    
    public mutating func clip(toRegion region: MKCoordinateRegion, newTile: (MapIndex, MapGrid<T>) -> T) -> TileDelta<T> {
        let gridIndices = region.getGridRect(withOrigin: self.regionOfOrigin).map { MapIndex(index: $0) }
        return clip(toIndices: gridIndices, newTile: newTile)
    }
    
    /**
     Fill the map to cover given region. Will return newly created tiles.
     */
    public mutating func fill(toRegion region: MKCoordinateRegion, newTile: (MapIndex, MapGrid<T>) -> T) -> [MapTile<T>] {
        let gridIndices = region.getGridRect(withOrigin: self.regionOfOrigin)
        let newTiles = gridIndices.flatMap { (gridIndex) -> MapTile<T>? in
            if !self.grid.contains(index: gridIndex) {
                let mapIndex = MapIndex(index: gridIndex)
                let item = newTile(mapIndex, self)
                let tile = MapTile(mapIndex: mapIndex, item: item)
                grid[gridIndex] = tile
                return tile
            }
            return nil
        }
        return newTiles
    }

    /**
     Crop the map to only cover the given region.
     */
    public mutating func crop(toRegion region: MKCoordinateRegion) -> [MapTile<T>] {
        //let gridIndices = region.getGridRect(withOrigin: self.regionOfOrigin)
        var newGrid = Grid<MapTile<T>>()
        var removedTiles = [MapTile<T>]()
        
        for (index, mapTile) in grid.getTiles() {
            // If region contains the tile, add it.
            if region.containsIndex(index, withOrigin: self.regionOfOrigin) {
                newGrid[index] = mapTile
            } else {
                removedTiles.append(mapTile)
            }
        }
        
        self.grid = newGrid
        
        return removedTiles
    }

    /**
     Load tiles for the given indices. Returns the delta.
     */
    private mutating func clip(toIndices remainingIndices: [MapIndex], newTile: (MapIndex, MapGrid<T>) -> T) -> TileDelta<T> {
        
        // TODO: Could be improved in performance.
        var visibleGridIndices = remainingIndices.map { $0.index }
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
            let item = newTile(mapIndex, self)
            let tile = MapTile(mapIndex: mapIndex, item: item)
            newTiles.append(tile)
            grid[gridIndex] = tile
        }
        
        return TileDelta(newTiles: newTiles, removedTiles: removedTiles)
    }
}

// MARK: - Helpers

private extension MKCoordinateRegion {
    
    func getGridRect(withOrigin origin: MKCoordinateRegion) -> [GridIndex] {
        
        let latd = origin.center.latitude - origin.span.latitudeDelta / 2.0
        let lond = origin.center.longitude - origin.span.longitudeDelta / 2.0
        
        let northDist = (self.center.latitude + self.span.latitudeDelta / 2.0) - latd
        let southDist = (self.center.latitude - self.span.latitudeDelta / 2.0) - latd
        let eastDist = (self.center.longitude + self.span.longitudeDelta / 2.0) - lond
        let westDist = (self.center.longitude - self.span.longitudeDelta / 2.0) - lond
        
        let y1 = Int(floor(southDist / origin.span.latitudeDelta))
        let y2 = Int(floor(northDist / origin.span.latitudeDelta))
        
        let x1 = Int(floor(westDist / origin.span.longitudeDelta))
        let x2 = Int(floor(eastDist / origin.span.longitudeDelta))
        
        return (x1...x2).flatMap { x in
            (y1...y2).map { y in GridIndex(x: x, y: y) }
        }
    }
    
    func containsIndex(_ index: GridIndex, withOrigin origin: MKCoordinateRegion) -> Bool {
        return false
    }

}

private extension GridIndex {
    
    func getRegion(forOrigin origin: MKCoordinateRegion) -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: origin.span.latitudeDelta * (Double(self.y)),
                longitude: origin.span.longitudeDelta * (Double(self.x))),
            span: origin.span)
    }

}

fileprivate func getIndex(forCoordinate coordinate: CLLocationCoordinate2D, withOrigin origin: MKCoordinateRegion) -> MapIndex {
    
    let y = Int(floor(coordinate.latitude / origin.span.latitudeDelta))
    let x = Int(floor(coordinate.longitude / origin.span.longitudeDelta))
    
    return MapIndex(index: GridIndex(x: x, y: y))
}
