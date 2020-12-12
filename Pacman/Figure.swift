//
//  Figure.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Figure: Hashable {
    var tile = (x: 0, y: 0)
    var tileDelta = 0
    var direction: Direction
    var tick: Int
    var speedPatternIndex: Int
    var repetitionCount: Int
    var node = SKNode()
    var name: String

    init(name: String) {
        self.name = name
        direction = .unknown
        tick = 0
        speedPatternIndex = 0
        repetitionCount = 0

        node.xScale = 2.0
        node.yScale = -2.0
    }

    static func == (lhs: Figure, rhs: Figure) -> Bool {
        return lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    func position() -> CGPoint {
        let directionVector = Constants.directionVectors[direction]!
        let delta = (x: tileDelta * directionVector.x, y: tileDelta * directionVector.y)
        return CGPoint(x: tile.x * Constants.tileSize + delta.x,
                       y: tile.y * Constants.tileSize + delta.y)
    }

    func setNodePosition(delta: (x: Int, y: Int)) {
        node.position = CGPoint(x: Int(Constants.center.x) + tile.x * Constants.tileSize + delta.x,
                                y: Int(Constants.center.y) + tile.y * Constants.tileSize + delta.y)
    }

    func tunnel() {
        // Tunnel (teleport)
        if tile.y == Constants.tunnelY && tile.x == -2 { // On left side of tunnel?
            tile.x = Constants.boardWidth + 2 - 1
            tileDelta = 2 // Hack: Prevent from nirvana
        } else if tile.y == Constants.tunnelY &&
                    tile.x == Constants.boardWidth + 2 - 1 { // On right side of tunnel?
            tile.x = -2
            tileDelta = 2 // Hack: Prevent from nirvana
        }
    }

    func reset() {
        node.xScale = 2.0
        node.yScale = -2.0
        direction = .unknown
        tick = 0
        speedPatternIndex = 0
        repetitionCount = 0
        tileDelta = 0
    }
}
