//
//  GridShape.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class GridShape {
    let shape: SKNode = SKNode()

    init() {
        shape.addChild(createShape())
    }

    func createShape() -> SKNode {
        let tileSize: Int = 16

        let path = CGMutablePath()

        let width = 28
        let height = 31

        for i in 0...width {
            path.move(to: CGPoint(x: i * tileSize, y: 0))
            path.addLine(to: CGPoint(x: i * tileSize, y: height * tileSize))
        }

        for i in 0...height {
            path.move(to: CGPoint(x: 0, y: i * tileSize))
            path.addLine(to: CGPoint(x: width * tileSize, y: i * tileSize))
        }

        let grid = SKShapeNode(path: path)
        let color = UIColor(red: 0x80 / 0xff, green: 0x80 / 0xff, blue: 0x80 / 0xff, alpha: 1.0)
        grid.strokeColor = color
        grid.lineWidth = 1

        return grid
   }
}
