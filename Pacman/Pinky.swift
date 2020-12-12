//
//  Pinky.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Pinky: Ghost {
    override init(name: String) {
        super.init(name: name)

        let color = UIColor(red: 0xff / 0xff, green: 0xb8 / 0xff, blue: 0xff / 0xff, alpha: 1.0)
        createShapes(color)

        scatterTarget = (x: 2, y: 36)

        leavingHomePatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1,
                                   interruptable: false)])
        
        resurrectPatterns.append(
            [AutopilotPattern(direction: .down, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false, setAliveShape: true)])

        reset()
    }

    override func update(game: Game) -> Bool {
        isElroy1 = game.eatenPellets >= Constants.totalPellets - 30 // Info: Differs from Pac-Man dossier

        var directionVector = Constants.directionVectors[game.pacMan.direction]!

        if game.pacMan.direction == .up { // Implement Pinky's bug
            directionVector.x = -1
        }

        chaseTarget = (x: directionVector.x * 4 + game.pacMan.tile.x,
                       y: directionVector.y * 4 + game.pacMan.tile.y)

        return super.update(game: game)
    }

    override func reset() {
        super.reset()
        tile = (x: 13, y: Constants.tunnelY)
        tileDelta = 0
        direction = .down
        autopilot = Autopilot(patterns: leavingHomePatterns)
        controlSystem = .autopilotLeavingHome
        speedPatternIndex = 4
    }
}
