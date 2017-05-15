//
//  GridTests.swift
//  GridTests
//
//  Created by Mikko Välimäki on 17-05-07.
//  Copyright © 2017 Mikko Välimäki. All rights reserved.
//

import XCTest
@testable import Grid

class GridTests: XCTestCase {
    
    var grid: Grid<Int>! = nil
    
    override func setUp() {
        super.setUp()
        grid = Grid<Int>()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasicIndexing() {
        grid[1,2] = 100
        
        XCTAssertNil(grid[2,1])
        XCTAssertEqual(grid[1,2], 100)
    }
    
    func testHashes() {
        var h = [Int: Int]()
        for x in 0...1000 {
            for y in 0...1000 {
                let hash = GridIndex(x: x, y: y).hashValue
                print("\(hash) (\(x),\(y))")
                h[hash] = h[hash].map { $0 + 1 } ?? 1
            }
        }
        print("\(h)")
    }
    
    func testIndexingPerformance() {
        
//        for x in 0...1000 {
//            for y in 0...1000 {
//                grid[x,y] = (x + y) % 2 == 0 ? 0 : x + y
//            }
//        }
//        var z = [Int]()
        
        self.measure {
            // Put the code you want to measure the time of here.
            for x in 0...500 {
                for y in 0...500 {
                    let i = (x + y) % 2 == 0 ? 0 : x + y
                    self.grid[x,y] = i
                }
            }
        }
    }
    
}
