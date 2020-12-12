//
//  Maze.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Maze {
    enum State {
        case reset, show, hide
    }

    let node = SKEffectNode()

    var state: State = .reset {
        didSet {
            switch state {
            case .show:
                node.isHidden = false
            case .hide:
                node.isHidden = true
            case .reset:
                // nop
                break
            }
        }
    }

    init() {
        let maze = MazeShape()
        maze.shape.position = Constants.center
        node.addChild(maze.shape)

        // Black quards on right side and on left side of the tunnel to make figures disappear
        let rect = CGRect(x: 0, y: 0, width: Constants.tileSize * 3, height: Constants.tileSize * 3)
        let quadLeftFromMaze = SKShapeNode(rect: rect)
        quadLeftFromMaze.fillColor = .black
        quadLeftFromMaze.strokeColor = .black
        // quadLeftFromTunnel.zPosition = 10
        var pos = (x: -3 * Constants.tileSize, y: (Constants.tunnelY - 1) * Constants.tileSize)
        quadLeftFromMaze.position = CGPoint(x: pos.x + Int(Constants.center.x),
                                            y: pos.y + Int(Constants.center.y))
        node.addChild(quadLeftFromMaze)
        let quadRightFromMaze = quadLeftFromMaze.copy() as! SKShapeNode
        pos = (x: Constants.boardWidth * Constants.tileSize, y: (Constants.tunnelY - 1) * Constants.tileSize)
        quadRightFromMaze.position = CGPoint(x: pos.x + Int(Constants.center.x),
                                             y: pos.y + Int(Constants.center.y))
        node.addChild(quadRightFromMaze)

        node.shouldRasterize = true
    }
}
