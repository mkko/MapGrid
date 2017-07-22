import XCTest
@testable import MapGrid

class MapGridTests: XCTestCase {
    
    func testConstruct() {
        _ = MapGrid<String>(tileSize: 200)
        
    }
    
    static var allTests = [
        ("testConstruct", testConstruct),
        ]
}
