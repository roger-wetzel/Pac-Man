//
//  Clyde.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Clyde: Ghost {
    override init(name: String) {
        super.init(name: name)

        let color = UIColor(red: 0xff / 0xff, green: 0xb8 / 0xff, blue: 0x51 / 0xff, alpha: 1.0)
        createShapes(color)

        scatterTarget = (x: 0, y: 1)

        leavingHomePatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: Constants.tileSize / 2, interruptable: true),
             AutopilotPattern(direction: .down, stopDelta: Constants.tileSize, interruptable: true),
             AutopilotPattern(direction: .up, stopDelta: Constants.tileSize / 2, interruptable: true)])
        leavingHomePatterns.append(
            [AutopilotPattern(direction: .left, stopDelta: 2 * Constants.tileSize, interruptable: false)])
        leavingHomePatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1, interruptable: false)])

        resurrectPatterns.append(
            [AutopilotPattern(direction: .down, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .right, stopDelta: 2 * Constants.tileSize,
                                   interruptable: false)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .left, stopDelta: 2 * Constants.tileSize,
                                   interruptable: false, setAliveShape: true)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false)])

        reset()
    }

    override func update(game: Game) -> Bool {
        var target = game.pacMan.tile

        let x = tile.x - game.pacMan.tile.x
        let y = tile.y - game.pacMan.tile.y

        let distance = x * x + y * y
        if distance > 64 { // 8 (= sqrt(64)) tiles
            target = scatterTarget
        }

        chaseTarget = target

        if game.eatenPellets > 60 && tick > 5 * 60 {
            leaveHome = true
        }

        return super.update(game: game)
    }

    override func reset() {
        super.reset()
        tile = (x: 15, y: Constants.tunnelY)
        tileDelta = 0
        direction = .up
        autopilot = Autopilot(patterns: leavingHomePatterns)
        controlSystem = .autopilotLeavingHome
        speedPatternIndex = 12
    }
}
