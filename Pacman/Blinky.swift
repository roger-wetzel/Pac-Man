//
//  Blinky.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Blinky: Ghost {
    override init(name: String) {
        super.init(name: name)

        let color = UIColor(red: 0xff / 0xff, green: 0x00 / 0xff, blue: 0x00 / 0xff, alpha: 1.0)
        createShapes(color)

        scatterTarget = (x: 25, y: 36)

        resurrectPatterns.append(
            [AutopilotPattern(direction: .down, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false)])
        resurrectPatterns.append(
            [AutopilotPattern(direction: .up, stopDelta: 3 * Constants.tileSize - 1 + 8,
                                   interruptable: false, setAliveShape: true)])

        reset()
    }

    override func update(game: Game) -> Bool {
        isElroy1 = game.eatenPellets >= Constants.totalPellets - 50
        isElroy2 = game.eatenPellets >= Constants.totalPellets - 30
        chaseTarget = game.pacMan.tile

        return super.update(game: game)
    }

    override func reset() {
        super.reset()
        tile = (x: 14, y: Constants.tunnelY + 3)
        tileDelta = Constants.tileSize / 2
        direction = .left
        controlSystem = .chase
        speedPatternIndex = 0
    }
}
