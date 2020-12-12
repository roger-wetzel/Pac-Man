//
//  GhostShape.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class GhostShape {
    let shape: SKNode = SKNode()

    // Used for state normal
    init(_ state: ShapeType, _ color: UIColor, _ direction: Direction, _ frame: Int) {
        shape.addChild(createShape(state, color, direction, frame))
    }

    // Used for states scared and state scaredHighlighted
    init(_ state: ShapeType, _ frame: Int) {
        let color = state == .scared ? UIColor.blue : UIColor.white
        shape.addChild(createShape(state, color, .unknown, frame))
    }

    // Used for state eaten
    init(_ state: ShapeType, _ direction: Direction) {
        shape.addChild(createShape(state, .clear, direction, -1))
    }

    func createShape(_ state: ShapeType, _ color: UIColor, _ direction: Direction, _ frame: Int) -> SKNode {
        let ghost = SKShapeNode()

        if state != .eaten {
            let path = CGMutablePath()

            // Head
            path.move(to: CGPoint(x: 0.0 + 0.5, y: 6.0))
            path.addQuadCurve(to: CGPoint(x: 6.5 + 0.5, y: 0.0), control: CGPoint(x: 1.5 + 0.5, y: 0.0))
            path.addQuadCurve(to: CGPoint(x: 13.0 + 0.5, y: 6.0), control: CGPoint(x: 11.5 + 0.5, y: 0.0))

            // Feet for 1st frame (frame 0)
            let feetFrame0 = [
                13, 13,     11, 11,     9, 13,     8, 13,     8, 11,
                5, 11,      5, 13,      4, 13,     2, 11,     0, 13]

            // Feet for 2nd frame (frame 1)
            let feetFrame1 = [
                13, 12,     12, 13,     11, 13,    9, 11,     7, 13,
                6, 13,      4, 11,      2, 13,     1, 13,     0, 12]

            let points = frame == 0 ? feetFrame0 : feetFrame1

            for i in stride(from: 0, to: points.count - 1, by: 2) {
                path.addLine(to: CGPoint(x: CGFloat(points[i]) + 0.5, y: CGFloat(points[i + 1]) + 0.5))
            }

            ghost.path = path
            ghost.strokeColor = .clear
            ghost.fillColor = color
            ghost.isAntialiased = false
        }

        if state != .scared && state != .scaredHighlighted { // Normal eyes
            let leftEye: SKNode = eye(direction: direction)
            leftEye.position = CGPoint(x: 2, y: 3)
            ghost.addChild(leftEye)

            let rightEye: SKNode = eye(direction: direction)
            rightEye.position = CGPoint(x: 8, y: 3)
            ghost.addChild(rightEye)
        } else { // Scared eyes (and mouth)
            let leftEye = SKShapeNode(rect: CGRect(x: 4, y: 5, width: 2, height: 2))
            leftEye.strokeColor = .clear
            leftEye.fillColor = state == .scared ? .yellow : .red
            ghost.addChild(leftEye)

            let rightEye = SKShapeNode(rect: CGRect(x: 8, y: 5, width: 2, height: 2))
            rightEye.strokeColor = .clear
            rightEye.fillColor = state == .scared ? .yellow : .red
            ghost.addChild(rightEye)

            // Mouth
            let points = [
                1, 10,    2, 9,     3, 9,     4, 10,     5, 10,    6, 9,
                7, 9,    8, 10,     9, 10,    10, 9,     11, 9,    12, 10]
            let path = CGMutablePath()
            for i in stride(from: 0, to: points.count - 1, by: 2) {
                if i == 0 {
                    path.move(to: CGPoint(x: CGFloat(points[i]) + 0.5, y: CGFloat(points[i + 1]) + 0.5))
                } else {
                    path.addLine(to: CGPoint(x: CGFloat(points[i]) + 0.5, y: CGFloat(points[i + 1]) + 0.5))
                }
            }
            let mouth = SKShapeNode(path: path)
            mouth.strokeColor = state == .scared ? .yellow : .red
            mouth.lineWidth = 1.0
            mouth.isAntialiased = false

            ghost.addChild(mouth)
        }

        return ghost
    }

    func eye(direction: Direction) -> SKShapeNode {
        let eyeballTranslation = [
            Direction.left: CGPoint(x: -1, y: 0),
            Direction.right: CGPoint(x: 1, y: 0),
            Direction.up: CGPoint(x: 0, y: -1),
            Direction.down: CGPoint(x: 0, y: 1)]
        let eyeballTranslationForDirection = eyeballTranslation[direction]
        let eX: CGFloat = eyeballTranslationForDirection!.x
        let eY: CGFloat = eyeballTranslationForDirection!.y

        let eyeballPath = CGMutablePath()
        eyeballPath.addEllipse(in: CGRect(x: 0.5, y: 0.5, width: 3, height: 4), transform: CGAffineTransform(translationX: eX, y: eY))
        let eyeball = SKShapeNode(path: eyeballPath)
        eyeball.strokeColor = .clear
        eyeball.fillColor = .white
        eyeball.strokeColor = .white
        eyeball.isAntialiased = false

        let pupilTranslation = [
            Direction.left: CGPoint(x: 0, y: 2),
            Direction.right: CGPoint(x: 2, y: 2),
            Direction.up: CGPoint(x: 1, y: 0),
            Direction.down: CGPoint(x: 1, y: 3)]
        let pupilTranslationForDirection = pupilTranslation[direction]
        let pX: CGFloat = pupilTranslationForDirection!.x
        let pY: CGFloat = pupilTranslationForDirection!.y

        let pupilPath = CGMutablePath()
        pupilPath.addRect(CGRect(x: 0, y: 0, width: 2, height: 2),
                          transform: CGAffineTransform(translationX: pX + eX, y: pY + eY))
        let pupil = SKShapeNode(path: pupilPath)
        pupil.strokeColor = .clear
        pupil.fillColor = .blue
        eyeball.addChild(pupil)

        return eyeball
    }
}
