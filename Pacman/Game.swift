//
//  Game.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

enum Direction {
    case left, right, up, down, unknown
}

struct Constants {
    static let boardWidth = 28
    static let boardHeight = 36
    static let tileSize = 16
    static let tunnelY = 18
    static let totalPellets = 244 // 240 dots + 4 energizers
    static let eatenWaitTime = 60 // "Freeze" game when a ghost has been eaten
    static let scaredTime = 6 * 60
    static let collisionDistance: Float = 8.0

    static let directionVectors = [
        Direction.left: (x: -1, y: 0),
        Direction.right: (x: 1, y: 0),
        Direction.up: (x: 0, y: 1),
        Direction.down: (x: 0, y: -1)]

    static let oppositeDirections = [
        Direction.left: Direction.right,
        Direction.right: Direction.left,
        Direction.up: Direction.down,
        Direction.down: Direction.up]

    static let center = CGPoint(x: -Constants.boardWidth * Constants.tileSize / 2,
                                y: -Constants.boardHeight * Constants.tileSize / 2)
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

class Game {
    let board =
        "____________________________" +
        "____________________________" +
        "____________________________" +
        "||||||||||||||||||||||||||||" +
        "|............||............|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|.|__|.|___|.||.|___|.|__|.|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|..........................|" +
        "|.||||.||.||||||||.||.||||.|" +
        "|.||||.||.||||||||.||.||||.|" +
        "|......||....||....||......|" +
        "||||||.|||||.||.|||||.||||||" +
        "_____|.|||||.||.|||||.|_____" +
        "_____|.||..........||.|_____" +
        "_____|.||.|||--|||.||.|_____" +
        "||||||.||.|______|.||.||||||" +
        "..........|______|.........." +
        "||||||.||.|______|.||.||||||" +
        "_____|.||.||||||||.||.|_____" +
        "_____|.||..........||.|_____" +
        "_____|.||.||||||||.||.|_____" +
        "||||||.||.||||||||.||.||||||" +
        "|............||............|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|...||................||...|" +
        "|||.||.||.||||||||.||.||.|||" +
        "|||.||.||.||||||||.||.||.|||" +
        "|......||....||....||......|" +
        "|.||||||||||.||.||||||||||.|" +
        "|.||||||||||.||.||||||||||.|" +
        "|..........................|" +
        "||||||||||||||||||||||||||||" +
        "____________________________" +
        "____________________________"

    let chaseScatterPattern = [
        (Ghost.ControlSystem.scatter,  7 * 60),
        (Ghost.ControlSystem.chase,   20 * 60),
        (Ghost.ControlSystem.scatter,  7 * 60),
        (Ghost.ControlSystem.chase,   20 * 60),
        (Ghost.ControlSystem.scatter,  5 * 60),
        (Ghost.ControlSystem.chase, 1033 * 60),
        (Ghost.ControlSystem.scatter,  1 * 60),
        (Ghost.ControlSystem.chase,        -1)] // Forever
    var chaseScatterPatternIndex = 0
    var chaseScatterTimer = 0

    var tick: Int = 0
    var eatenPellets: Int = 0
    var desiredDirection = Direction.unknown
    var eatenWaitTimer = 0
    var scaredTimer = 0
    var signalPacManHit = false
    var bestTick = 0
    var randomNumberSeed: Int = 0
    var signalButtonAPressed = false
    var buttonAWasReleased = true
    var otherGame: Game? = nil
    var isVersus = false

    // Figures
    var pacMan = PacMan(name: "Pac-Man")
    var blinky = Blinky(name: "Blinky")
    var pinky = Pinky(name: "Pinky")
    var inky = Inky(name: "Inky")
    var clyde = Clyde(name: "Clyde")
    var ghosts = [Ghost]()

    var maze = Maze()
    var pellets = Pellets()
    var lives = Lives()
    var display = Display()

    var view: SKView! {
        didSet {
            for ghost in ghosts {
                ghost.view = view
            }
        }
    }
    var gameNode = SKNode() // Main node

    // State machine
    enum State {
        case reset, start, waitOrPlay, ready, play, die, die2, prepare,
             gameOver, done, doneWithBestTime, setInCondition
    }

    var state: State = .reset {
        didSet {
            switch state {
            case .reset:
                chaseScatterPatternIndex = 0
                chaseScatterTimer = 0
                eatenPellets = 0
                randomNumberSeed = 0
                tick = 0
                signalButtonAPressed = false
                buttonAWasReleased = true
                isVersus = false
                display.bestTime = Int(Float(bestTick) / 50.0)
                fallthrough
            case .prepare:
                desiredDirection = Direction.unknown
                eatenWaitTimer = 0
                scaredTimer = 0
            case .play:
                signalPacManHit = false
                lives.decrementLives()
            case .doneWithBestTime:
                bestTick = tick
                UserDefaults.standard.set(bestTick, forKey: "bestTick") // Save
                fallthrough
            case .done:
                if isVersus {
                    if let otherGame = self.otherGame {
                        if otherGame.isVersus {
                            otherGame.signalPacManHit = true
                            otherGame.lives.numberOfLives = 0
                        }
                    }
                }
            case .start, .waitOrPlay, .ready, .die, .die2, .gameOver, .setInCondition:
                break
            }
        }
    }

    var stateTimer = 0

    struct StateTableEntry {
        var maze: Maze.State
        var pellets: Pellets.State
        var pacMan: PacMan.State
        var ghosts: Ghost.State
        var lives: Lives.State
        var display: Display.State

        var condition: (() -> Bool)?
        var duration: Int = 0

        var nextState: State
    }

    var stateTable: [State: StateTableEntry] = [
        .reset: StateTableEntry(maze: .reset, pellets: .reset, pacMan: .reset,
                                ghosts: .reset, lives: .reset, display: .reset,
                                nextState: .start),

        // conditionButtonPressed
        .start: StateTableEntry(maze: .show, pellets: .hide, pacMan: .hide,
                                ghosts: .hide, lives: .hide, display: .start,
                                nextState: .waitOrPlay),

        // conditionWaitOrPlay
        .waitOrPlay: StateTableEntry(maze: .show, pellets: .hide, pacMan: .hide,
                                     ghosts: .hide, lives: .hide, display: .waitOrPlay,
                                     nextState: .ready),

        .ready: StateTableEntry(maze: .show, pellets: .show, pacMan: .show,
                                ghosts: .show, lives: .show, display: .ready,
                                duration: 2 * 60, nextState: .play),

        // conditionPlay
        .play: StateTableEntry(maze: .show, pellets: .show, pacMan: .play,
                               ghosts: .play, lives: .show, display: .play,
                               nextState: .setInCondition),

        .die: StateTableEntry(maze: .show, pellets: .show, pacMan: .fixed,
                              ghosts: .fixed, lives: .show, display: .play,
                              duration: 30, nextState: .die2),

        .die2: StateTableEntry(maze: .show, pellets: .show, pacMan: .die,
                               ghosts: .hide, lives: .show, display: .play,
                               duration: 40, nextState: .prepare),

        // conditionPrepare
        .prepare: StateTableEntry(maze: .show, pellets: .show, pacMan: .reset,
                                  ghosts: .reset, lives: .show, display: .prepare,
                                  nextState: .setInCondition),

        .gameOver: StateTableEntry(maze: .show, pellets: .show, pacMan: .hide,
                                   ghosts: .hide, lives: .show, display: .gameOver,
                                   duration: 6 * 60, nextState: .reset),

        .done: StateTableEntry(maze: .show, pellets: .show, pacMan: .show,
                               ghosts: .done, lives: .show, display: .done,
                               duration: 6 * 60, nextState: .reset),

        .doneWithBestTime: StateTableEntry(maze: .show, pellets: .show, pacMan: .show,
                                           ghosts: .done, lives: .show, display: .doneWithBestTime,
                                           duration: 6 * 60, nextState: .reset)
    ]

    init() {
        ghosts.append(blinky)
        ghosts.append(pinky)
        ghosts.append(inky)
        ghosts.append(clyde)
        createNode()

        chaseScatterTimer = chaseScatterPattern[chaseScatterPatternIndex].1

        // Init conditions
        stateTable[.start]?.condition = conditionButtonPressed
        stateTable[.waitOrPlay]?.condition = conditionWaitOrPlay
        stateTable[.play]?.condition = conditionPlay
        stateTable[.prepare]?.condition = conditionPrepare

        // Read high score
        if let bestTick = UserDefaults.standard.object(forKey: "bestTick") as? Int {
            self.bestTick = bestTick // 0 if missing
        }
        if bestTick == 0 {
            bestTick = 9999 * 50
        }
        display.bestTime = Int(Float(bestTick) / 50.0)
    }

    func stateMachine() {
        if stateTimer > 0 {
            stateTimer -= 1
        } else {
            // Check conditions
            var conditionMet = true
            if let condition = stateTable[state]!.condition {
                conditionMet = condition()
            }

            if conditionMet { // Go to next state
                state = stateTable[state]!.nextState

                maze.state = stateTable[state]!.maze
                pellets.state = stateTable[state]!.pellets
                pacMan.state = stateTable[state]!.pacMan
                for ghost in ghosts {
                    ghost.state = stateTable[state]!.ghosts
                }
                lives.state = stateTable[state]!.lives
                display.state = stateTable[state]!.display

                stateTimer = stateTable[state]!.duration
            }
        }
    }

    // State machine: Conditions
    func conditionButtonPressed() -> Bool { // First press, controller is mapped
        if signalButtonAPressed  {
            if let otherGame = self.otherGame {
                if otherGame.state == .waitOrPlay { // Does opponent want to play a versus?
                    isVersus = true
                    otherGame.isVersus = true
                }
            }

            signalButtonAPressed = false
            return true
        }
        return false
    }

    func conditionWaitOrPlay() -> Bool {
        if isVersus == true {
            return true
        }
        if signalButtonAPressed {
            signalButtonAPressed = false
            return true
        }
        return false
    }

    func conditionPlay() -> Bool {
        if eatenPellets == Constants.totalPellets {
            stateTable[.play]?.nextState = tick <= bestTick ? .doneWithBestTime : .done
            return true
        }

        if signalPacManHit {
            signalPacManHit = false
            stateTable[.play]?.nextState = .die
            return true
        }

        return false
    }

    func conditionPrepare() -> Bool {
        stateTable[.prepare]?.nextState = lives.numberOfLives == 0 ? .gameOver : .ready
        return true
    }

    func createNode() {
/* DEBUG only
        let grid = GridShape()
        grid.shape.position = Constants.center
        gameNode.addChild(grid.shape)
*/
        gameNode.addChild(pellets.node)
        gameNode.addChild(pacMan.node)
        gameNode.addChild(blinky.node)
        gameNode.addChild(pinky.node)
        gameNode.addChild(inky.node)
        gameNode.addChild(clyde.node)
        gameNode.addChild(maze.node)
        gameNode.addChild(lives.node)
        gameNode.addChild(display.node)
    }

    func isLegalSpace(_ tile: (x: Int, y: Int)) -> Bool {
        var cappedX = tile.x
        if tile.y == Constants.tunnelY ||
            tile.y == Constants.tunnelY + 1 ||
            tile.y == Constants.tunnelY - 1 { // Pretend there is a long tunnel
            if cappedX <= 0 {
                cappedX = 0
            } else if cappedX >= Constants.boardWidth - 1 {
                cappedX = Constants.boardWidth - 1
            }
        }
        let row = Constants.boardHeight - 1 - tile.y
        let index = row * Constants.boardWidth + cappedX
        if index < 0 || index >= board.count {
            return false
        }
        return board[index] == "."
    }

    func energize() {
        for ghost in ghosts {
            ghost.requestControlSystem(.random, .scared)
        }

        scaredTimer = Constants.scaredTime
    }

    func isTunnelSpace(_ tile: (x: Int, y: Int)) -> Bool {
        return tile.y == Constants.tunnelY &&
            (tile.x <= 5 || tile.x >= Constants.boardWidth - 5)
    }

    func update() {
        stateMachine()

        if eatenWaitTimer > 0 {
            eatenWaitTimer -= 1
        }

        if state == .die2 {
            let _ = pacMan.update(game: self)
        } else {
            collisionDetection()
        }
        // Chase or scatter?
        if state == .play && scaredTimer == 0 && signalPacManHit == false  {
            let controlSystem = chaseScatterPattern[chaseScatterPatternIndex].0
            for ghost in ghosts {
                ghost.requestControlSystem(controlSystem, .alive)
            }
            chaseScatterTimer -= 1
            if chaseScatterTimer == 0 {
                if chaseScatterPatternIndex <= chaseScatterPattern.count {
                    chaseScatterPatternIndex += 1
                }
                chaseScatterTimer = chaseScatterPattern[chaseScatterPatternIndex].1
            }
        }
        
        pellets.update()

        if state == .ready || state == .play || state == .die || state == .die2 || state == .prepare {
            if lives.numberOfLives != Lives.lives {
                tick += 1
            }
            display.time = Int(Float(tick) / 50.0)
        }
    }

    func collisionDetection() {
        var hitGhosts = Set<Ghost>()
        var doRepeat = true
        if eatenWaitTimer == 0 {
            if scaredTimer > 0 && state == .play {
                scaredTimer -= 1
            }

            while doRepeat {
                pacMan.desiredDirection = desiredDirection
                doRepeat = pacMan.update(game: self)
                for ghost in ghosts { // Did Pac-Man collide with ghosts?
                    if distance(first: pacMan.position(),
                                second: ghost.position()) <= Constants.collisionDistance {
                        hitGhosts.insert(ghost)
                    }
                }
            }
        }

        collided:
        for ghost in ghosts {
            doRepeat = true
            while doRepeat {
                doRepeat = ghost.update(game: self)
                if distance(first: pacMan.position(),
                            second: ghost.position()) <= Constants.collisionDistance {
                    hitGhosts.insert(ghost)
                }
            }
        }

        if eatenWaitTimer == 0 {
            for ghost in hitGhosts {
                if ghost.controlSystem == .autopilotLeavingHome ||
                    ghost.controlSystem == .autopilotResurrect { // Hack
                    continue
                }
                if ghost.visual == .scared {
                    ghost.requestControlSystem(.headingHome, .eaten)
                    eatenWaitTimer = Constants.eatenWaitTime
                } else if ghost.visual == .alive {
                    signalPacManHit = true
                }
            }
        }
    }

    func distance(first: CGPoint, second: CGPoint) -> Float {
        hypotf(Float(second.x - first.x), Float(second.y - first.y))
    }

    func deterministicRandomNumber() -> Int {
        var randomNumber = randomNumberSeed
        randomNumberSeed += 1 // Each function call generates a unique random number
        for ghost in ghosts {
            randomNumber += ghost.tile.x * ghost.tile.y * ghost.tileDelta
        }
        return abs(randomNumber)
    }

    func handleButtonA(pressed: Bool) {
        switch pressed {
        case true:
            if buttonAWasReleased {  // Flip flop
                signalButtonAPressed = true
                buttonAWasReleased = false
            }
        case false:
            buttonAWasReleased = true
        }
    }
}
