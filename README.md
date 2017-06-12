# MapGrid

MapGrid is stateful data structure that helps loading partial map data. It keeps track of loaded tiles and gives you the control to handle loading and unloading of tiles.

It is best described with an example that can be found in `MapGridExample`.

# How does it work?

MapGrid is a grid data structure that can be used as an abstraction over the map. It splits the area into distinct rectangular boundaries, tiles. Because of the geometry of the Earth it assumes the cylindrical map projection and thus, the tile size will vary based on latitude. Longitudinal size of the tile will be constant.

# Usage

You initialize a MapGrid by providing what kind of tiles it will hold and a factory to create these tiles. You also need to give the size of the tile. This applies only at the grid origin which is currently set to be at zero coordinates.

    var grid = MapGrid<Tile>(tileSize: 100000 /* meters */)

And here's an example on how to use it. 

```
func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

    let visibleRegion = mapView.region
    let removedTiles = grid.crop(toRegion: visibleRegion)
    let newTiles = grid.fill(toRegion: visibleRegion, newTile: self.createTile)
    print("update: +\(newTiles.count) -\(removedTiles.count)")
    
    mapView.addAnnotations(newTiles.flatMap { $0.item.cities })
    mapView.removeAnnotations(removedTiles.flatMap { $0.item.cities })
}
```

And that's it! With MapGrid you only need to deal with the logic of handling new and removed tiles.

For the sake of completeness here's the setup:

```
struct Tile {
    let cities: [City]
}

func createTile(mapIndex: MapIndex, mapGrid: MapGrid<Tile>) -> Tile {
    let region = mapGrid.region(at: mapIndex)
    let cities = /* Get the cities for the region here */
    return Tile(cities: cities)
}
```

### Filling

With the grid you call `fill(toRegion:newTile:)` to get new tiles for the given region. As a result, you only get newly created tiles back and you need to update the UI with these tiles.

### Cropping

To remove tiles from the grid you use `crop(toRegion:)`. This will give you tiles that were removed from the grid and it is up to you to remove the contents of these tiles from the map.


# TODO:

- Provide the origin in initialization
- Implement animations for the demo
- Tests

