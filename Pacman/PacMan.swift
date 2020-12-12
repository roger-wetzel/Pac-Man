//
//  PacMan.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class PacMan: Figure {
    enum State {
        case reset, hide, show, play, fixed, die
    }

    var velocity = 2
    var desiredDirection: Direction = .unknown
    var shapes: [[Direction: PacManShape]] = []
    var cornering = (direction: Direction.unknown, tileDelta: 0, active: false)

    // Dossier: Every time Pac-Man eats a regular dot, he stops moving for one frame (1/60th of a second),
    var framesToWait = 0

    let speedPattern           = [1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1]
    let speedPatternEngergized = [1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1]

    var state: State = .reset {
        didSet {
            switch state {
            case .hide:
                hideAll()
            case .reset:
                reset()
            case .die:
                hideAll()
                shapes[0][direction]?.shape.isHidden = false // Mouth closed
                tick = 0
            case .show, .play, .fixed:
                break
            }
        }
    }

    override init(name: String) {
        super.init(name: name)
        createShapes()
        reset()
    }

    func createShapes() {
        let shapesFrame0 = [Direction.left: PacManShape(.left, 0.0),
                            Direction.right: PacManShape(.right, 0.0),
                            Direction.up: PacManShape(.up, 0.0),
                            Direction.down: PacManShape(.down, 0.0)]
        initPacManNode(shapesFrame0)

        let shapesFrame1 = [Direction.left: PacManShape(.left, CGFloat.pi / 6.0),
                            Direction.right: PacManShape(.right, CGFloat.pi / 6.0),
                            Direction.up: PacManShape(.up, CGFloat.pi / 6.0),
                            Direction.down: PacManShape(.down, CGFloat.pi / 6.0)]
        initPacManNode(shapesFrame1)

        let shapesFrame2 = [Direction.left: PacManShape(.left, CGFloat.pi / 3.0),
                            Direction.right: PacManShape(.right, CGFloat.pi / 3.0),
                            Direction.up: PacManShape(.up, CGFloat.pi / 3.0),
                            Direction.down: PacManShape(.down, CGFloat.pi / 3.0)]
        initPacManNode(shapesFrame2)

        shapes = [shapesFrame0, shapesFrame1, shapesFrame2]
    }

    func initPacManNode(_ shapes: [Direction: PacManShape]) {
        for (_, pacManShape) in shapes {
            pacManShape.shape.isHidden = true
            node.addChild(pacManShape.shape)
        }
    }

    func hideAll() {
        for shapesForFrame in shapes {
            for (_, pacManShape) in shapesForFrame {
                pacManShape.shape.isHidden = true
            }
        }
    }

    func eatPellet(game: Game, _ x: Int, _ y: Int) {
        // Protect virtual large tunnel
        guard x >= 0 && x < Constants.boardWidth && y >= 0 && y < Constants.boardHeight else {
            return
        }
        if let pellet = game.pellets.pellets[tile.y][tile.x] {
            if !pellet.isEaten {
                pellet.shape.isHidden = true
                pellet.isEaten = true
                framesToWait = pellet.framesToWaitWhenAte
                game.eatenPellets += 1
                if pellet is Energizer {
                    game.energize()
                }
            }
        }
    }

    func update(game: Game) -> Bool {
        if state == .die {
            let s = CGFloat(sin(Double(Double(tick) / 12.0)) * 4.0)
            node.xScale = s * 2.0
            node.yScale = s * -2.0
            tick += 1
            return false
        }

        guard framesToWait <= 0 else {
            framesToWait -= 1
            return false
        }

        hideAll()
        // Show sprite for current frame/shapes and direction
        let frame = tick / 8 % shapes.count

        if state != .hide && state != .reset {
            shapes[frame][direction]?.shape.isHidden = false
        }

        if state == .reset || state == .fixed || state == .show {
            let directionVector = Constants.directionVectors[direction]!

            setNodePosition(delta: (x: tileDelta * directionVector.x + 10,
                                    y: tileDelta * directionVector.y + 8))
            return false
        }

        // Player would like to change direction of Pac-Man
        if desiredDirection != .unknown && !cornering.active {
            let oppositeDirection = Constants.oppositeDirections[direction]
            if oppositeDirection == desiredDirection && velocity != 0 && tileDelta != 0 {
                // Immediate change of direction in opposite direction is allowed
                let directionVector = Constants.directionVectors[direction]!
                tile.x += directionVector.x
                tile.y += directionVector.y
                tileDelta = Constants.tileSize - tileDelta

                direction = desiredDirection
            } else if tileDelta == 0 { // Allowed to change direction at this place (full tile)?
                let desiredDirectionVector = Constants.directionVectors[desiredDirection]!
                let desiredTile = (x: tile.x + desiredDirectionVector.x,
                                   y: tile.y + desiredDirectionVector.y)
                if game.isLegalSpace(desiredTile) {
                    direction = desiredDirection
                    velocity = 2
                }
            } else if tileDelta >= 4 * 2 && desiredDirection != direction { // Cornering?
                let directionVector = Constants.directionVectors[direction]!
                let desiredDirectionVector = Constants.directionVectors[desiredDirection]!
                let desiredTile = (x: tile.x + directionVector.x + desiredDirectionVector.x,
                                   y: tile.y + directionVector.y + desiredDirectionVector.y)
                if game.isLegalSpace(desiredTile) {
                    cornering.active = true
                    cornering.direction = direction
                    cornering.tileDelta = tileDelta
                    direction = desiredDirection
                    tileDelta = 0
                    velocity = 2
                }
            }
        }
        desiredDirection = .unknown

        // Cornering
        var corneringDelta = (x: 0, y: 0)
        if cornering.active {
            let corneringDirectionVector = Constants.directionVectors[cornering.direction]!
            cornering.tileDelta += velocity
            if cornering.tileDelta == Constants.tileSize {
                tile.x += corneringDirectionVector.x
                tile.y += corneringDirectionVector.y
                cornering.active = false

                eatPellet(game: game, tile.x, tile.y)
            } else {
                corneringDelta = (x: cornering.tileDelta * corneringDirectionVector.x,
                                  y: cornering.tileDelta * corneringDirectionVector.y)
            }
        }

        // Motion
        var doRepeat = true
        if state == .play {
            tileDelta += velocity
        }
        let directionVector = Constants.directionVectors[direction]!
        if tileDelta == Constants.tileSize {
            tileDelta = 0
            tile.x += directionVector.x // Move to next tile
            tile.y += directionVector.y

            eatPellet(game: game, tile.x, tile.y)

            tunnel()
            
            let nextTile = (x: tile.x + directionVector.x,
                            y: tile.y + directionVector.y)
            if !game.isLegalSpace(nextTile) { // Stuck?
                velocity = 0 // Stop Pac-Man
                doRepeat = false
            }
        }

        setNodePosition(delta: (x: tileDelta * directionVector.x + corneringDelta.x + 10,
                                y: tileDelta * directionVector.y + corneringDelta.y + 8))

        // Speed
        let pattern = game.scaredTimer > 0 ? speedPatternEngergized : speedPattern
        let numberOfRepetitions = pattern[speedPatternIndex]
        if repetitionCount >= numberOfRepetitions {
            doRepeat = false
            repetitionCount = 1
            speedPatternIndex += 1
            if speedPatternIndex == speedPattern.count - 1 {
                speedPatternIndex = 0
            }
        } else {
            repetitionCount += 1
        }

        if velocity != 0 && doRepeat == false && (state == .play || state == .die) {
            tick += 1
        }

        return doRepeat
    }

    override func reset() {
        super.reset()
        direction = .right
        tile = (x: 13, y: 9)
        tileDelta = Constants.tileSize / 2
        cornering.active = false
        tick = 0
        state = .fixed
        velocity = 2
    }
}
