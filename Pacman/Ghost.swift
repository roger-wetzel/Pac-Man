//
//  Ghost.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

enum ShapeType {
    case alive, scared, scaredHighlighted, eaten
}

class Ghost: Figure {
    enum State {
        case reset, hide, show, play, fixed, frozen, done
    }

    enum Visual {
        case alive, scared, eaten, none
    }

    enum ControlSystem {
        case chase, scatter, autopilotLeavingHome, autopilotResurrect, random, headingHome, none
    }

    var visual: Visual = .none
    var controlSystem: ControlSystem = .none
    var move = true

    var autopilot: Autopilot? = nil
    var leavingHomePatterns = [[AutopilotPattern]]() // Leave home for the first time
    var resurrectPatterns = [[AutopilotPattern]]() // Come home and leave

    var leaveHome = false

    var shapes: [[Direction: GhostShape]] = []
    var scaredShapes: [GhostShape] = []
    var scaredHighlightedShapes: [GhostShape] = []
    var eatenShapes: [Direction: GhostShape] = [:]

    var chaseTarget = (x: 0, y: 0)
    var scatterTarget = (x: 0, y: 0)

    var isElroy1 = false
    var isElroy2 = false

    var view: SKView? = nil
    var particles: SKEmitterNode? = nil

     // "Level 4" speed
    let speedPattern           = [1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1] // normal (chase, scatter)
    let speedPatternFrightened = [0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1] // frightened (random)
    let speedPatternTunnel     = [0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1] // tunnel
    let speedPatternElroy1     = [1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1] // elroy 1
    let speedPatternElroy2     = [1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1] // elroy 2
    let speedEaten             = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2] // eaten (headingHome)

    var state: State = .reset {
        didSet {
            switch state {
            case .hide:
                visual = .none
                hideAll()
            case .reset:
                reset()
            case .show:
                visual = .alive
            case .play, .fixed, .frozen:
                visual = .alive
            case .done:
                showParticles()
            }
        }
    }

    override init(name: String) {
        super.init(name: name)
        direction = .right
    }

    func createShapes(_ color: UIColor) {
        // Normal
        let shapesFrame0 = [Direction.left: GhostShape(.alive, color, .left, 0),
                            Direction.right: GhostShape(.alive, color, .right, 0),
                            Direction.up: GhostShape(.alive, color, .up, 0),
                            Direction.down: GhostShape(.alive, color, .down, 0)]
        initGhostNode(shapesFrame0)

        let shapesFrame1 = [Direction.left: GhostShape(.alive, color, .left, 1),
                            Direction.right: GhostShape(.alive, color, .right, 1),
                            Direction.up: GhostShape(.alive, color, .up, 1),
                            Direction.down: GhostShape(.alive, color, .down, 1)]
        initGhostNode(shapesFrame1)

        shapes = [shapesFrame0, shapesFrame1]

        // Scared
        scaredShapes = [GhostShape(.scared, 0), GhostShape(.scared, 1)]
        initGhostNode(scaredShapes)

        scaredHighlightedShapes = [GhostShape(.scaredHighlighted, 0), GhostShape(.scaredHighlighted, 1)]
        initGhostNode(scaredHighlightedShapes)

        // Eaten
        eatenShapes = [Direction.left: GhostShape(.eaten, .left),
                       Direction.right: GhostShape(.eaten, .right),
                       Direction.up: GhostShape(.alive, .up),
                       Direction.down: GhostShape(.alive, .down)]
        initGhostNode(eatenShapes)
    }

    func initGhostNode(_ shapes: [Direction: GhostShape]) {
        for (_, ghostShape) in shapes {
            ghostShape.shape.isHidden = true
            node.addChild(ghostShape.shape)
        }
    }

    func initGhostNode(_ shapes: [GhostShape]) {
        for ghostShape in shapes {
            ghostShape.shape.isHidden = true
            node.addChild(ghostShape.shape)
        }
    }

    func hideAll() {
        for shapesForFrame in shapes {
            for (_, ghostShape) in shapesForFrame {
                ghostShape.shape.isHidden = true
            }
        }

        for shape in scaredShapes {
            shape.shape.isHidden = true
        }

        for shape in scaredHighlightedShapes {
            shape.shape.isHidden = true
        }

        for (_, ghostShape) in eatenShapes {
            ghostShape.shape.isHidden = true
        }
    }

    func updateVisual(game: Game) {
        hideAll()
        // Show sprite for current frame and direction
        let frame = tick / 8 % 2

        switch visual {
        case .alive:
            shapes[frame][direction]?.shape.isHidden = false
        case .scared:
            if game.scaredTimer < Constants.scaredTime / 3 && (game.scaredTimer / 16 % 2 == 0) {
                scaredHighlightedShapes[frame].shape.isHidden = false
            } else {
                scaredShapes[frame].shape.isHidden = false
            }
        case .eaten:
            eatenShapes[direction]?.shape.isHidden = false
        case .none:
            break
        }
    }

    func requestControlSystem(_ requestedControlSystem: ControlSystem, _ requestedVisual: Visual? = nil) {
        switch requestedControlSystem {
        case .random:
            if controlSystem == .chase || controlSystem == .scatter &&
                (controlSystem != .autopilotLeavingHome || controlSystem != .autopilotResurrect){
                controlSystem = requestedControlSystem

                // Turn 180 degrees when not home
                let directionVector = Constants.directionVectors[direction]!
                tile.x += directionVector.x
                tile.y += directionVector.y
                tileDelta = Constants.tileSize - tileDelta
                direction = Constants.oppositeDirections[direction]!
            }
            if let requestedVisual = requestedVisual {
                if visual != .eaten {
                    visual = requestedVisual
                }
            }
        case .chase, .scatter:
            if controlSystem != .autopilotLeavingHome &&
                controlSystem != .autopilotResurrect &&
                visual != .eaten &&
                visual != .scared {
                controlSystem = requestedControlSystem
            }
            if let requestedVisual = requestedVisual {
                if visual != .eaten {
                    visual = requestedVisual
                }
            }
        case .headingHome:
            if controlSystem == .random {
                controlSystem = requestedControlSystem
                if let requestedVisual = requestedVisual {
                    visual = requestedVisual
                }
                // Now, wait until ghost is at the door. Then autopilot will take over.
            }
        case .autopilotResurrect:
            if controlSystem == .headingHome {
                autopilot = Autopilot(patterns: resurrectPatterns)
                controlSystem = .autopilotResurrect
                if let requestedVisual = requestedVisual {
                    visual = requestedVisual
                }
            }
        case .autopilotLeavingHome, .none:
            break // TODO
        }
    }

    func isAtDoor() -> Bool {
        return (tile.x == 13 && tile.y == Constants.tunnelY + 3 &&
            direction == .left && tileDelta == Constants.tileSize / 2) ||
            (tile.x == 13 && tile.y == Constants.tunnelY + 3 &&
                direction == .right && tileDelta == Constants.tileSize / 2)
    }

    func update(game: Game) -> Bool {
        if state == .play {
            updateControlSystem(game: game)
            updateVisual(game: game)
            return updatePattern(game: game)
        }

        if state != .hide {
            updateVisual(game: game)
        }

        if state != .play && state != .hide {
            if state == .fixed {
                tick += 1
            }
            if let autopilot = autopilot {
                let delta = autopilot.getDelta()
                setNodePosition(delta: (x: delta.x + 2, y: delta.y + 22)) // Hack 2, 22: Fit ghost in home
            } else {
                let directionVector = Constants.directionVectors[direction]!
                setNodePosition(delta: (x: tileDelta * directionVector.x - 4,
                                y: tileDelta * directionVector.y + 22))
            }
        }

        return false
    }

    func updateControlSystem(game: Game) {
        switch controlSystem {
        case .none:
            break
        case .headingHome:
            if isAtDoor() { // Standing at the door of the home?
                requestControlSystem(.autopilotResurrect)
            } else {
                advancePosition(game: game)
            }
        case .chase, .scatter:
            advancePosition(game: game)
        case .autopilotLeavingHome, .autopilotResurrect:
            if let autopilot = autopilot {
                if autopilot.active {
                    autopilot.execute(interrupt: leaveHome,
                                      ghost: self,
                                      wait: game.eatenWaitTimer > 0)
                    let delta = autopilot.getDelta()
                    setNodePosition(delta: (x: delta.x + 2, y: delta.y + 22)) // Hack 2, 22: Fit ghost in home
                } else {
                    self.autopilot = nil

                    // Let's start at this position outside home
                    tile = (x: 14, y: Constants.tunnelY + 3)
                    tileDelta = Constants.tileSize / 2
                    direction = .left
                    repetitionCount = 0
                    if visual == .scared {
                        controlSystem = .random // Force
                    } else {
                        controlSystem = .chase // Force
                    }
                }
            }
        case .random:
            advancePosition(game: game)
        }
    }

    func updatePattern(game: Game) -> Bool {
        if move == false {
            move = true
            speedPatternIndex += 1
            if speedPatternIndex == speedPattern.count - 1 {
                speedPatternIndex = 0
            }
        }

        // Speed
        var pattern = speedPattern // defaut speed (normal)
        if isElroy2 {
            pattern = speedPatternElroy2
        } else if isElroy1 {
            pattern = speedPatternElroy1
        }
        if game.isTunnelSpace(tile) {
            pattern = speedPatternTunnel
        }
        if visual == .scared {
            pattern = speedPatternFrightened
        } else if visual == .eaten {
            pattern = speedEaten
        }

        var doRepeat = true
        let numberOfRepetitions = pattern[speedPatternIndex]
        if numberOfRepetitions == 0 {
            doRepeat = false
            move = false // Don't move in the next frame/update
            if game.eatenWaitTimer == 0 {
                tick += 1
            }
        } else {
            if repetitionCount >= numberOfRepetitions {
                doRepeat = false
                repetitionCount = 1
                speedPatternIndex += 1
                if speedPatternIndex == pattern.count - 1 {
                    speedPatternIndex = 0
                }
                if game.eatenWaitTimer == 0 {
                    tick += 1
                }
            } else {
                repetitionCount += 1
            }
        }

        return doRepeat
    }

    func advancePosition(game: Game) {
        guard move else {
            return
        }

        let directionVector = Constants.directionVectors[direction]!

        if game.eatenWaitTimer == 0 || controlSystem == .headingHome {
            tileDelta += 2 // 2 = velocity
        }
        if tileDelta >= Constants.tileSize { // Might be greater than (change direction when frightened)
            tileDelta = 0

            tile.x += directionVector.x
            tile.y += directionVector.y

            tunnel()

            if controlSystem == .random { // Choose a random valid direction
                var directionsToChooseFrom = [Direction]()
                for possibleDirection in possibleDirections(currentDirection: direction) {
                    let possibleDirectionVector = Constants.directionVectors[possibleDirection]!
                    let newTile = (x: tile.x + possibleDirectionVector.x,
                                   y: tile.y + possibleDirectionVector.y)
                    if game.isLegalSpace(newTile) {
                        directionsToChooseFrom.append(possibleDirection)
                    }
                }
                if directionsToChooseFrom.count > 0 {
                    direction = directionsToChooseFrom[game.deterministicRandomNumber() %
                                                        directionsToChooseFrom.count]
                } else {
                    fatalError("This should really really never happen")
                }
            } else { // Choose shortest way to Pac-Man
                var shortestDistance: Int = Int.max
                for possibleDirection in possibleDirections(currentDirection: direction) {
                    let possibleDirectionVector = Constants.directionVectors[possibleDirection]!
                    let newTile = (x: tile.x + possibleDirectionVector.x,
                                   y: tile.y + possibleDirectionVector.y)
                    if game.isLegalSpace(newTile) {
                        var target = scatterTarget
                        if controlSystem == .chase || isElroy1 || isElroy2 {
                            target = chaseTarget
                        }
                        if controlSystem == .headingHome {
                            target = (x: 13, y: Constants.tunnelY) // center of home (seat)
                        }
                        let x = newTile.x - target.x
                        let y = newTile.y - target.y
                        let distance = x * x + y * y
                        if distance < shortestDistance {
                            shortestDistance = distance
                            direction = possibleDirection
                        }
                    }
                }
            }
        }
        setNodePosition(delta: (x: tileDelta * directionVector.x - 4,
                                y: tileDelta * directionVector.y + 22))
    }

    func showParticles() {
        if let texture = view?.texture(from: self.node) {
            if let particles = SKEmitterNode(fileNamed: "Particle.sks") {
                self.particles = particles
                particles.particleTexture = texture
                particles.xScale = 0.5
                particles.yScale = -0.5
                node.addChild(particles)
            }
        }
    }

    func possibleDirections(currentDirection: Direction) -> [Direction] {
        let directions = [Direction.right: [Direction.up, Direction.right, Direction.down],
                          Direction.left: [Direction.up, Direction.left, Direction.down],
                          Direction.up: [Direction.up, Direction.right, Direction.left],
                          Direction.down: [Direction.right, Direction.left, Direction.down]]

        return directions[currentDirection]!
    }

    override func reset() {
        super.reset()
        leaveHome = false
        move = true
        visual = .none
        particles?.removeFromParent()
     }
}
