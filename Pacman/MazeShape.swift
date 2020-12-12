//
//  MazeShape.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class MazeShape {
    let shape: SKNode = SKNode()

    init() {
        shape.addChild(createGhostHouseDoor())
        shape.addChild(createWalls())
    }

    func createGhostHouseDoor() -> SKNode {
        let path = CGMutablePath()
        path.addRect(CGRect(x: 13 * Constants.tileSize, y: 20 * Constants.tileSize,
                            width: 2 * Constants.tileSize, height: 2 * Constants.tileSize / 8))
        let door = SKShapeNode(path: path)
        let color = UIColor(red: 0xff / 0xff, green: 0xb8 / 0xff, blue: 0xff / 0xff, alpha: 1.0)
        door.fillColor = color
        door.strokeColor = .clear
        door.lineWidth = 1

        return door
    }

/*
     Spaces are ignored (except for start position)

     n = Start x
     n = Fine x (n/8 of tile size)
     n = Start y
     n = Fine y (n/8 of tile size)

     R = Turn right
     L = Turn left
     d(d) = Steps forward, 0 = special case for ghost house
     C r = Curve followed by radius r (fine)
     E = End of path
     S = Subpath
*/

    func createWalls() -> SKNode {
        let plan =
            // Upper double frame
            "0 0 20 0 5L3L4RC8 8RC8 26RC8 8RC8 4L3L5E" +
            "0 0 19 5 5LC3 3LC3 4RC5 8RC5 12RC5 3 LC3 LC3 3 RC5 12  RC5 8RC5 4LC3 3LC3 5E" +

            // Lower double frame
            "0 0 17 0 5R3R4LC810LC8 26LC8 10LC84R3R5E" +
            "0 0 17 3 5RC3 3RC3 4LC5 4LC51RC3RC31LC54LC526 LC54LC51RC3RC31LC54LC54RC3 3RC3 5E" +

            "3 0 30 3  2RC3 1RC3 2RC3 1RC3 E" + // 1st quad
            "8 0 30 3  3RC3 1RC3 3RC3 1RC3 E" + // 2nd quad
            "17 0 30 3 3RC3 1RC3 3RC3 1RC3 E" + // 3rd quad
            "23 0 30 3 2RC3 1RC3 2RC3 1RC3 E" + // 4th qurd

            "3 0 26 3  2RC3 RC3 2RC3 RC3 E" + // - left
            "23 0 26 3 2RC3 RC3 2RC3 RC3 E" + // - right

            "8 0 11 3  3RC3 RC3 3RC3 RC3 E" + // -- left
            "17 0 11 3 3RC3 RC3 3RC3 RC3 E" + // -- right

            "8 3 17 0  R3RC3 RC3 3RC3 RC3 E" + // | left
            "20 3 17 0 R3RC3 RC3 3RC3 RC3 E" + // | right

            "14 0 26 3 3RC3 RC3 2LC5 2 RC3 RC3 2 LC5 2 RC3 RC3 S E" + // T
            "14 0 14 3 3RC3 RC3 2LC5 2 RC3 RC3 2 LC5 2 RC3 RC3 S E" + // T
            "14 0 8 3  3RC3 RC3 2LC5 2 RC3 RC3 2 LC5 2 RC3 RC3 S E" + // T

            "8 0 26 3  RC3 2LC5 2RC3 RC3 2LC5 2 RC3 RC3 6 RC3 E" + // T 90° counterclockwise
            "20 0 26 3 RC3 6RC3 RC32 LC5 2RC3 RC3 2 LC5 2 RC3 E" + // T 90° clockwise

            "3 0 11 3  2RC3 3RC3 RC3 2LC5 1 RC3 RC3 E" + // "L" left
            "23 0 11 3 2RC3 RC31 LC5 2RC3 RC3 3 RC3 E" + // "L" right

            "3 0 5 3  4LC5 2 RC3 RC3 2 LC5 2 RC3 RC3 8 RC3 RC3 E" + // __|_ left
            "17 0 5 3 2LC5 2 RC3 RC3 2 LC5 4 RC3 RC3 8 RC3 RC3 E" + // _|__ right

            "11 0 20 0 2L0L2 LC3 3 LC3 6 LC3 3 LC3 2 L0L2R3R6R3 S E" // Ghost house

        var previousDirection: Direction = .unknown // Curves need this information
        var direction: Direction = .right
        var expectingPosition = true
        var position = (x: 0, y: 0)
        let path = CGMutablePath()

        var index = 0
        while index < plan.count {
            let command = plan[index]
            switch command {
            case "R": // Turn right
                previousDirection = direction
                let nextDirections = [
                    Direction.left: Direction.up,
                    Direction.right: Direction.down,
                    Direction.up: Direction.right,
                    Direction.down: Direction.left]
                direction = nextDirections[direction]!

            case "L": // Turn left
                previousDirection = direction
                let nextDirections = [
                    Direction.left: Direction.down,
                    Direction.right: Direction.up,
                    Direction.up: Direction.left,
                    Direction.down: Direction.right]
                direction = nextDirections[direction]!

            case "E": // End of path
                direction = .right // Reset to default direction
                expectingPosition = true

            case "S": // Close path
                path.closeSubpath()

            case " ":
                break // Ignore space

            case "C": // Curve
                index += 1
                let fine = Int(String(plan[index]))!
                let delta = fine * Constants.tileSize / 8

                let previousDirectionVector = Constants.directionVectors[previousDirection]!
                let control = (x: position.x + delta * previousDirectionVector.x,
                               y: position.y + delta * previousDirectionVector.y)

                let directionVector = Constants.directionVectors[direction]!
                position = (x: control.x + delta * directionVector.x,
                            y: control.y + delta * directionVector.y)

                path.addQuadCurve(to: CGPoint(x: position.x, y: position.y),
                                  control: CGPoint(x: control.x, y: control.y))

            default:
                if expectingPosition {
                    do {
                        var x = 0, xFine = 0, y = 0, yFine = 0

                        let range = NSRange(location: index, length: plan.count - index)
                        let regex = try NSRegularExpression(pattern: "(\\d+) (\\d+) (\\d+) (\\d+) ")
                        if let match = regex.firstMatch(in: plan, options: [], range: range) {
                            if let range = Range(match.range(at: 1), in: plan) {
                                x = Int(plan[range])!
                            }
                            if let range = Range(match.range(at: 2), in: plan) {
                                xFine = Int(plan[range])!
                            }
                            if let range = Range(match.range(at: 3), in: plan) {
                                y = Int(plan[range])!
                            }
                            if let range = Range(match.range(at: 4), in: plan) {
                                yFine = Int(plan[range])!
                            }

                            index += match.range(at: 0).length - 1
                        } else {
                            fatalError("Plan for maze is invalid")
                        }

                        position = (x: x * Constants.tileSize + xFine * Constants.tileSize / 8,
                                    y: y * Constants.tileSize + yFine * Constants.tileSize / 8)
                        path.move(to: CGPoint(x: position.x, y: position.y))
                    }
                    catch {
                        fatalError("Plan for maze is invalid")
                    }
                    expectingPosition = false
                } else {
                    var steps = Int(String(command))!
                    let nextCommand = plan[index + 1] // Second digit?
                    if nextCommand.isNumber {
                        steps = steps * 10 + Int(String(nextCommand))!
                        index += 1
                    }

                    let directionVector = Constants.directionVectors[direction]!
                    if steps == 0 { // Special case (step = 0) draws 3/8 of tile size only (ghost house)
                        position = (x: position.x + 3 * Constants.tileSize / 8 * directionVector.x,
                                    y: position.y + 3 * Constants.tileSize / 8 * directionVector.y)
                    } else {
                        position = (x: position.x + steps * Constants.tileSize * directionVector.x,
                                    y: position.y + steps * Constants.tileSize * directionVector.y)
                    }
                    path.addLine(to: CGPoint(x: position.x, y: position.y))
                }
            }

            index += 1
        }

        let maze = SKShapeNode(path: path)
        maze.strokeColor = UIColor(red: 0x21 / 0xff, green: 0x21 / 0xff, blue: 0xff / 0xff, alpha: 1.0)
        maze.lineWidth = 1

        return maze
   }
}
