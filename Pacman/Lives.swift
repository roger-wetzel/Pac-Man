//
//  Lives.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Lives {
    static let lives = 3

    enum State {
        case reset, hide, show
    }

    var liveShapes = [PacManShape]()
    var node = SKNode()

    var numberOfLives: Int

    var state: State = .reset {
        didSet {
            switch state {
            case .show:
                showNumberOfLives()
            case .hide:
                for liveShape in liveShapes {
                    liveShape.shape.isHidden = true
                }
            case .reset:
                numberOfLives = Lives.lives
            }
        }
    }

    init() {
        numberOfLives = Lives.lives
        createShapes()
    }

    func createShapes() {
        for i in 0..<3 {
            let pacMan = PacManShape(.left, CGFloat.pi / 6.0)

            let pos = (x: (3 - i) * Constants.tileSize, y: 1 * Constants.tileSize)
            pacMan.shape.position = CGPoint(x: pos.x + Int(Constants.center.x),
                                            y: pos.y + Int(Constants.center.y))

            liveShapes.append(pacMan)
            node.addChild(pacMan.shape)
        }
    }

    func decrementLives() {
        numberOfLives -= 1
    }

    func showNumberOfLives() {
        for i in 0..<Lives.lives {
            liveShapes[i].shape.isHidden = i < Lives.lives - numberOfLives
        }
    }
}
