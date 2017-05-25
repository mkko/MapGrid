# MapGrid

MapGrid is stateful data structure that helps loading partial map data. It keeps track of loaded tiles and gives you the control to handle loading and unloading of tiles.

It is best described with an example that can be found in `MapGridExample`.

# How does it work?

MapGrid is a grid data structure that can be used as an abstraction over the map. It splits the area into distinct rectangular boundaries, tiles. Because of the geometry of the Earth it assumes the cylindrical map projection and thus, the tile size will vary based on latitude. Longitudinal size of the tile will be constant.

# Usage

You initialize a MapGrid by providing what kind of tiles it will hold and a factory to create these tiles. You also need to give the size of the tile. This applies only at the grid origin which is currently set to be at zero coordinates.

    var grid = MapGrid<CustomData>(tileSize: 100000 /* meters */, factory: CustomTileFactory())

Here is an example of a factory.

```
class CustomTileFactory: TileFactory<CustomTile> {
    
    override func value(forMapIndex mapIndex: MapIndex, inMapGrid mapGrid: MapGrid<Tile>) -> CustomTile {
        let region = mapGrid.region(at: mapIndex)
        /* Here you would provide data, such as annotations for the tile */
        return CustomTile(...)
    }
}
```

Finally you call `update(visibleRegion:)` to get new tiles for the given region. The new tiles you need to add to the map. This will also give you tiles that were removed from the grid and it is up to you to remove the contents of these tiles from the map.

This code snippet is from the example project.

```
let update = grid.update(visibleRegion: region)
print("update: +\(update.newTiles.count) -\(update.removedTiles.count)")

let newOverlays = update.newTiles.map { $0.item.overlay }
mapView.addOverlays(newOverlays)

let removedOverlays = update.removedTiles.map { $0.item.overlay }
mapView.removeOverlays(removedOverlays)
```

And that's it! With MapGrid you only need to deal with the logic of handling new and removed tiles.


# TODO:

- Better example with annotations
- Provide the origin in initialization

