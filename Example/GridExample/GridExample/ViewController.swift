//
//  ViewController.swift
//  GridExample
//
//  Created by Mikko Välimäki on 17-05-15.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import UIKit
import MapKit
import Grid

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var grid = MapGrid(tileSize: 200)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let update = grid.update(visibleRegion: mapView.region)
        
        print("update: \(update)")
        
        
        mapView.addOverlays(overlays)
    }

}
