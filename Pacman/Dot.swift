//
//  Dot.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Dot: Pellet {
    override init(_ x: Int, _ y: Int) {
        super.init(x, y)

        let color = UIColor(red: 0xff / 0xff, green: 0xb8 / 0xff, blue: 0xae / 0xff, alpha: 1.0)

        let dot = SKShapeNode(rect: CGRect(x: 4 * 2, y: 3 * 2, width: 2 * 2, height: 2 * 2))

        dot.strokeColor = .clear
        dot.fillColor = color

        let pos = (x: x * Constants.tileSize, y: y * Constants.tileSize)
        dot.position = CGPoint(x: pos.x - Constants.boardWidth * Constants.tileSize / 2,
                               y: pos.y - Constants.boardHeight * Constants.tileSize / 2)

        shape.addChild(dot)

        framesToWaitWhenAte = 1
    }

    override func reset() {
        super.reset()
    }
}
