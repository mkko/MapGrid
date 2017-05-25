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

let GRID_BASED_LOADING = true

class City: NSObject, MKAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    
    let title: String?
    
    var subtitle: String? { return "Population \(population)" }
    
    let population: Int
    
    init(title: String, coordinate: CLLocationCoordinate2D, population: Int) {
        self.title = title
        self.coordinate = coordinate
        self.population = population
    }
}

struct Tile {
    let cities: [City]
    let overlay: MKOverlay
}

class ViewController: UIViewController {
        
    var regionOverlay = MKPolygon(region: MKCoordinateRegion())
    
    func value<Int>(forMapIndex mapIndex: MapIndex) -> Int {
        return 0 as! Int
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    var grid = MapGrid<Tile>(tileSize: 100000 /* meters */, factory: CustomTileFactory(cities: loadCities()))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !GRID_BASED_LOADING {
            mapView.addAnnotations(loadCities())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        if !GRID_BASED_LOADING {
            return
        }
        
        print("\(mapView.currentMetersPerPoint)")
        let region = getRegion(mapView: mapView)
        
        // Update the grid.
        let update = grid.update(visibleRegion: region)
        print("update: +\(update.newTiles.count) -\(update.removedTiles.count)")
        
        mapView.addAnnotations(update.newTiles.flatMap { $0.item.cities })
        mapView.removeAnnotations(update.removedTiles.flatMap { $0.item.cities })
    }
    
    func getRegion(mapView: MKMapView) -> MKCoordinateRegion {
        return mapView.currentMetersPerPoint > 2000
            ? MKCoordinateRegion()
            : MKCoordinateRegion(
                center: mapView.region.center,
                span: MKCoordinateSpan(
                    latitudeDelta: mapView.region.span.latitudeDelta,
                    longitudeDelta: mapView.region.span.longitudeDelta))
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.magenta
        renderer.fillColor = UIColor.magenta.withAlphaComponent(0.3)
        return renderer
    }
}

class CustomTileFactory: TileFactory<Tile> {
    
    let cities: [City]
    
    init(cities: [City]) {
        self.cities = cities
    }
    
    override func value(forMapIndex mapIndex: MapIndex, inMapGrid mapGrid: MapGrid<Tile>) -> Tile {
        let region = mapGrid.region(at: mapIndex)
        let bounds = region.bounds
        let cities = self.cities.filter { city in
            let p = city.coordinate
            return
                p.latitude < bounds.ne.latitude && p.latitude > bounds.se.latitude &&
                p.longitude < bounds.ne.longitude && p.longitude > bounds.nw.longitude
        }
        return Tile(cities: cities, overlay: MKPolygon(region: region))
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

func loadCities() -> [City] {
    if let path = Bundle.main.path(forResource: "simplemaps-worldcities-basic", ofType: "csv") {
        // Just read the whole chunk, it should be small enough for the example.
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            let cities = data.components(separatedBy: .newlines).flatMap { line -> City? in
                let csv = line.components(separatedBy: ",")
                guard csv.count > 3,
                    let lat = Double(csv[2]),
                    let lon = Double(csv[3]),
                    let pop = Int(csv[4]) else {
                    print("Skipping line: \(line)")
                    return nil
                }
                let name = csv[0]
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                return City(title: name, coordinate: coord, population: pop)
            }
            return cities
        } catch {
            print(error)
            abort()
        }
    }
    
    return []
}
