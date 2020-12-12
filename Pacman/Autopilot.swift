//
//  Autopilot.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

struct AutopilotPattern {
    var direction: Direction
    var stopDelta: Int
    var interruptable: Bool
    var setAliveShape: Bool = false
}

class Autopilot {
    var patterns = [[AutopilotPattern]]()

    var patternIndex: Int
    var innerPatternIndex: Int
    var delta: Int

    var active: Bool
    var accumulatedDelta: (x: Int, y: Int)
    var currentDelta: (x: Int, y: Int)

    var pattern: AutopilotPattern

    var setAliveAfterWait: Bool

    init(patterns: [[AutopilotPattern]]) {
        self.patterns = patterns

        patternIndex = 0
        innerPatternIndex = 0

        delta = 0
        active = true

        accumulatedDelta = (x: 0, y: 0)
        currentDelta = (x: 0, y: 0)

        pattern = patterns[patternIndex][innerPatternIndex]

        setAliveAfterWait = false
    }

    func assignPattern(ghost: Ghost) {
        pattern = patterns[patternIndex][innerPatternIndex]
        if pattern.setAliveShape {
            setAliveAfterWait = true
        }
    }

    func execute(interrupt: Bool, ghost: Ghost, wait: Bool) {
        guard active else {
            return
        }

        ghost.direction = pattern.direction // Facing direction

        if wait && ghost.visual != .eaten { // Eaten ghost may return to home/seat but must wait after ressurection
            return
        }
        if setAliveAfterWait {
            ghost.visual = .alive // Alive (shape) but still controlled by autopilot
            setAliveAfterWait = false
        }

        if pattern.interruptable && interrupt == true {
            accumulatedDelta.x += currentDelta.x
            accumulatedDelta.y += currentDelta.y

            patternIndex += 1
            if patternIndex >= patterns.count {
                active = false
                return
            }
            delta = 0
            innerPatternIndex = 0
            assignPattern(ghost: ghost)
        }

        let directionVector = Constants.directionVectors[pattern.direction]!
        currentDelta.x = delta * directionVector.x
        currentDelta.y = delta * directionVector.y

        if delta == pattern.stopDelta {
            accumulatedDelta.x += currentDelta.x
            accumulatedDelta.y += currentDelta.y

            innerPatternIndex += 1
            if innerPatternIndex >= patterns[patternIndex].count {
                innerPatternIndex = 0
                if !pattern.interruptable {
                    patternIndex += 1
                    if patternIndex >= patterns.count {
                        active = false
                    }
                }
            }
            if active {
                assignPattern(ghost: ghost)
            }
            currentDelta = (x: 0, y: 0)
            delta = 0
        } else {
            delta += 1
        }
    }

    func getDelta() -> (x: Int, y: Int) {
        return (x: accumulatedDelta.x + currentDelta.x,
                y: accumulatedDelta.y + currentDelta.y)
    }
}
