//
//  Display.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Display {
    enum State {
        case reset, ready, start, waitOrPlay, play, die, prepare, gameOver, done, doneWithBestTime
    }

    let node = SKNode()

    var topLabel = SKLabelNode(fontNamed:"Arcade Rounded")
    var centerLabel = SKLabelNode(fontNamed:"Arcade Rounded")
    var time: Int = 0 { // Game will set time
        didSet {
            topLabel.text = "TIME \(time)"
        }
    }
    var bestTime: Int = 0 { // Game will set bestTime
        didSet {
            topLabel.text = "TIME TO BEAT \(bestTime)"
        }
    }

    var state: State = .reset {
        didSet {
            switch state {
            case .reset:
                centerLabel.isHidden = true
                topLabel.isHidden = true
            case .start:
                centerLabel.text = "PRESS THE A BUTTON"
                centerLabel.fontColor = .yellow
                centerLabel.isHidden = false
                topLabel.isHidden = false
            case .waitOrPlay:
                centerLabel.text = "  WAIT FOR OPPONENT\nOR PRESS THE A BUTTON"
                centerLabel.fontColor = .green
            case .ready:
                centerLabel.text = "READY"
                centerLabel.fontColor = .yellow
                centerLabel.isHidden = false
            case .play, .die:
                centerLabel.isHidden = true
            case .gameOver:
                centerLabel.text = "GAME OVER"
                centerLabel.fontColor = .red
                centerLabel.isHidden = false
            case .done:
                centerLabel.text = "YOU DID IT"
                centerLabel.fontColor = .yellow
                centerLabel.isHidden = false
            case .doneWithBestTime:
                centerLabel.text = "NEW BEST TIME"
                centerLabel.fontColor = .cyan
                centerLabel.isHidden = false
            case .prepare:
                break
            }
        }
    }

    init() {
        time = 0

        topLabel.fontSize = 16
        topLabel.horizontalAlignmentMode = .center
        topLabel.position = CGPoint(x: topLabel.position.x,
                                       y: CGFloat((Constants.boardHeight - 2) * Constants.tileSize +
                                                    Int(Constants.center.y)))
        topLabel.fontColor = .white
        node.addChild(topLabel)

        centerLabel.fontSize = 16
        centerLabel.horizontalAlignmentMode = .center
        centerLabel.position = CGPoint(x: centerLabel.position.x,
                                       y: CGFloat((Constants.tunnelY - 3) * Constants.tileSize +
                                                    Int(Constants.center.y)))
        centerLabel.numberOfLines = 2

        node.addChild(centerLabel)
    }
}
