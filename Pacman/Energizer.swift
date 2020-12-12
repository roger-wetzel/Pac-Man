//
//  Energizer.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Energizer: Pellet {
    var blinkToggle = false

    override init(_ x: Int, _ y: Int) {
        super.init(y, y)

        blinkToggle = false

        let color = UIColor(red: 0xff / 0xff, green: 0xb8 / 0xff, blue: 0xae / 0xff, alpha: 1.0)

        let energizer = SKShapeNode(circleOfRadius: 8.0)
        energizer.strokeColor = .clear
        energizer.fillColor = color

        let pos = (x: x * Constants.tileSize + 9, y: y * Constants.tileSize + 8)
        energizer.position = CGPoint(x: pos.x - Constants.boardWidth * Constants.tileSize / 2,
                                     y: pos.y - Constants.boardHeight * Constants.tileSize / 2)

        shape.addChild(energizer)

        framesToWaitWhenAte = 3
    }

    func blink() {
        if !isEaten {
            shape.isHidden = blinkToggle
            blinkToggle.toggle()
        }
    }

    override func reset() {
        super.reset()
        blinkToggle = false
    }
}
