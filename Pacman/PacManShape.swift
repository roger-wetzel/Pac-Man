//
//  PacManShape.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class PacManShape {
    let shape: SKNode = SKNode()

    init(_ direction: Direction, _ angle: CGFloat) {
        shape.addChild(createShape(direction, angle))
    }

    func createShape(_ direction: Direction, _ angle: CGFloat) -> SKNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -3, y: 0))
        path.addArc(center: CGPoint(x: 0, y: 0),
                    radius: 6.5,
                    startAngle: angle,
                    endAngle: 2.0 * CGFloat.pi - angle,
                    clockwise: false)

        let pacMan = SKShapeNode(path: path)
        pacMan.strokeColor = .clear
        pacMan.fillColor = UIColor(red: 1, green: 1, blue: 0, alpha: 1.0)
        pacMan.isAntialiased = false
        let rotation = [
            Direction.left: 2.0 * CGFloat.pi / 2.0,
            Direction.right: 0.0,
            Direction.up: 3.0 * CGFloat.pi / 2.0,
            Direction.down: CGFloat.pi / 2.0]
        pacMan.zRotation = rotation[direction]!

        return pacMan
    }
}
