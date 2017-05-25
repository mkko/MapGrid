//
//  ViewController.swift
//  MapGridExample
//
//  Created by Mikko Välimäki on 17-05-15.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit
import MapKit
import MapGrid

struct Tile {
    let overlay: MKOverlay
}

class ViewController: UIViewController {
        
    var regionOverlay = MKPolygon(region: MKCoordinateRegion())
    
    func value<Int>(forMapIndex mapIndex: MapIndex) -> Int {
        return 0 as! Int
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    var grid = MapGrid<Tile>(tileSize: 100000 /* meters */, factory: CustomTileFactory())
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("\(mapView.currentMetersPerPoint)")
        let region = getRegion(mapView: mapView)
        
        // Update the
        mapView.remove(regionOverlay)
        self.regionOverlay = MKPolygon(region: region)
        mapView.add(regionOverlay)
        
        // Update the grid.
        let update = grid.update(visibleRegion: region)
        print("update: +\(update.newTiles.count) -\(update.removedTiles.count)")
        
        let newOverlays = update.newTiles.map { $0.item.overlay }
        mapView.addOverlays(newOverlays)
        
        let removedOverlays = update.removedTiles.map { $0.item.overlay }
        mapView.removeOverlays(removedOverlays)
    }
    
    func getRegion(mapView: MKMapView) -> MKCoordinateRegion {
        return mapView.currentMetersPerPoint > 2000
            ? MKCoordinateRegion()
            : MKCoordinateRegion(
                center: mapView.region.center,
                span: MKCoordinateSpan(
                    latitudeDelta: mapView.region.span.latitudeDelta / 2.0,
                    longitudeDelta: mapView.region.span.longitudeDelta / 2.0))
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.magenta
        renderer.fillColor = UIColor.magenta.withAlphaComponent(0.3)
        return renderer
    }
}

class CustomTileFactory: TileFactory<Tile> {
    
    override func value(forMapIndex mapIndex: MapIndex, inMapGrid mapGrid: MapGrid<Tile>) -> Tile {
        let region = mapGrid.region(at: mapIndex)
        return Tile(overlay: MKPolygon(region: region))
    }
}

extension MKCoordinateRegion {
    
    var bounds: (nw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D, se: CLLocationCoordinate2D, sw: CLLocationCoordinate2D) {
        let nw = CLLocationCoordinate2D(
            latitude: self.center.latitude + self.span.latitudeDelta / 2.0,
            longitude: self.center.longitude - self.span.longitudeDelta / 2.0)
        let ne = CLLocationCoordinate2D(
            latitude: self.center.latitude + self.span.latitudeDelta / 2.0,
            longitude: self.center.longitude + self.span.longitudeDelta / 2.0)
        let se = CLLocationCoordinate2D(
            latitude: self.center.latitude - self.span.latitudeDelta / 2.0,
            longitude: self.center.longitude + self.span.longitudeDelta / 2.0)
        let sw = CLLocationCoordinate2D(
            latitude: self.center.latitude - self.span.latitudeDelta / 2.0,
            longitude: self.center.longitude - self.span.longitudeDelta / 2.0)
        return (nw, ne, se, sw)
    }
}

extension MKPolygon {
    
    convenience init(region: MKCoordinateRegion) {
        let bounds = region.bounds
        var coordinates = [bounds.nw, bounds.ne, bounds.se, bounds.sw]
        self.init(coordinates: &coordinates, count: coordinates.count)
    }
}

extension MKMapView {
    
    var currentMetersPerPoint: CLLocationDistance {
        guard self.bounds.width > 0 else {
            return 0
        }
        let loc1 = CLLocation(latitude: self.region.center.latitude,
                              longitude: (region.center.longitude - region.span.longitudeDelta * 0.5))
        let loc2 = CLLocation(latitude: self.region.center.latitude,
                              longitude: (region.center.longitude + region.span.longitudeDelta * 0.5))
        let latitudinalDistance = loc1.distance(from: loc2)
        return latitudinalDistance / CLLocationDistance(self.bounds.width)
    }
}
