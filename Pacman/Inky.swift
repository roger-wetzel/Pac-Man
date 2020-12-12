//
//  Inky.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Inky: Ghost {
    override init(name: String) {
        super.init(name: name)

        let color = UIColor(red: 0x00 / 0xff, green: 0xff / 0xff, blue: 0xff / 0xff, alpha: 1.0)
        createShapes(color)

        scatterTarget = (x: 27, y: 1)

        leavingHomePatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: Constants.tileSize / 2, interruptable: true),
             AutopilotPattern(direction: .down, stopDelta: Constants.tileSize, interruptable: true),
             AutopilotPattern(direction: .up, stopDelta: Constants.tileSize / 2, interruptable: true)])
        leavingHomePatterns.append(
            [AutopilotPattern(direction: .right, stopDelta: 2 * Constants.tileSize, interruptable: false)])
        leavingHomePatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1, interruptable: false)])

        resurrectPatterns.append(
            [AutopilotPattern(direction: .down, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .left, stopDelta: 2 * Constants.tileSize,
                                   interruptable: false)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .right, stopDelta: 2 * Constants.tileSize,
                                   interruptable: false, setAliveShape: true)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false)])

        reset()
    }

    override func update(game: Game) -> Bool {
        let pacManDirectionVector = Constants.directionVectors[game.pacMan.direction]!
        let center = (x: game.pacMan.tile.x + pacManDirectionVector.x * 2,
                      y: game.pacMan.tile.y + pacManDirectionVector.y * 2)

        let directionVector = (x: center.x - game.blinky.tile.x,
                               y: center.y - game.blinky.tile.y)

        chaseTarget = (x: center.x + directionVector.x,
                       y: center.y + directionVector.y)

        if game.eatenPellets > 30 && tick > 3 * 60 {
            leaveHome = true
        }

        return super.update(game: game)
    }

    override func reset() {
        super.reset()
        tile = (x: 11, y: Constants.tunnelY)
        tileDelta = 0
        direction = .up
        autopilot = Autopilot(patterns: leavingHomePatterns)
        controlSystem = .autopilotLeavingHome
        speedPatternIndex = 8
    }
}
