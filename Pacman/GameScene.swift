//
//  GameScene.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameController
import AVFoundation

class GameScene: SKScene {
    let game1 = Game()
    let game2 = Game()

    var controllerIndexToGameMapping = [Int: Game]()
    var audioPlayer: AVAudioPlayer? = nil

    override func didMove(to view: SKView) {
        observeForGameControllers()
        game1.view = view
        game2.view = view
    }

    // Game controllers
    func observeForGameControllers() {
        NotificationCenter.default.addObserver(self, selector: #selector(connectControllers),
                                               name: NSNotification.Name.GCControllerDidConnect,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnectControllers),
                                               name: NSNotification.Name.GCControllerDidDisconnect,
                                               object: nil)
    }

    @objc func connectControllers() {
        var indexNumber = 0 // Player index
        // Currently connected controllers
        for controller in GCController.controllers() {
            if controller.extendedGamepad != nil { // "Nimbus"?
                controller.playerIndex = GCControllerPlayerIndex.init(rawValue: indexNumber)!
                indexNumber += 1
                setupControllerControls(controller: controller)
            } else if controller.microGamepad != nil { // Siri remote?
                controller.playerIndex = GCControllerPlayerIndex.init(rawValue: indexNumber)!
                indexNumber += 1

                controller.microGamepad?.reportsAbsoluteDpadValues = true

                controller.microGamepad?.buttonA.valueChangedHandler = { [self] (buttonA: GCControllerButtonInput, value: Float, pressed: Bool) in

                    if let game = controllerIndexToGameMapping[controller.playerIndex.rawValue] {
                        game.handleButtonA(pressed: (controller.microGamepad?.buttonA.isPressed)!)
                    } else if controllerIndexToGameMapping.count < 2 { // Map the 2 controllers to the 2 games
                        let hadGame1 = controllerIndexToGameMapping.contains { element in
                            return element.value === game1
                        }
                        let game = hadGame1 ? game2 : game1
                        controllerIndexToGameMapping[controller.playerIndex.rawValue] = game
                        game.otherGame = otherGame(game)
                        game.handleButtonA(pressed: true)
                    }
                }

                controller.microGamepad?.dpad.valueChangedHandler = { (dpad, xValue, yValue) in
                    var directions = [Direction.left: Float(0.0), Direction.right: Float(0.0),
                                      Direction.up: Float(0.0), Direction.down: Float(0.0)]

                    if xValue < 0.0 {
                        directions[Direction.left] = -xValue
                    } else if xValue > 0.0 {
                        directions[Direction.right] = xValue
                    }

                    if yValue < 0.0 {
                        directions[Direction.down] = -yValue
                    } else if yValue > 0.0 {
                        directions[Direction.up] = yValue
                    }

                    var desiredDirection: Direction = .unknown
                    var maxValue: Float = 0.0
                    for (direction, value) in directions {
                        if value > 0.3 {
                            if value > maxValue {
                                maxValue = value
                                desiredDirection = direction
                            }
                        }
                    }

                    if desiredDirection != .unknown {
                        if let game = self.controllerIndexToGameMapping[controller.playerIndex.rawValue] {
                            game.desiredDirection = desiredDirection
                        }
                    }
                }
            }
        }
    }

    @objc func disconnectControllers() {
    }

    func setupControllerControls(controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = { [self]
            (gamepad: GCExtendedGamepad, element: GCControllerElement) in
            controllerInputDetected(gamepad: gamepad, element: element,
                                    index: controller.playerIndex.rawValue)
        }
    }

    func handleButtonA(gamepad: GCExtendedGamepad, element: GCControllerElement, index: Int) {
        if gamepad.buttonA == element {
            if let game = controllerIndexToGameMapping[index] {
                game.handleButtonA(pressed: gamepad.buttonA.isPressed)
            } else if controllerIndexToGameMapping.count < 2 { // Map the 2 controllers to the 2 games
                let hadGame1 = controllerIndexToGameMapping.contains { element in
                    return element.value === game1
                }
                let game = hadGame1 ? game2 : game1
                controllerIndexToGameMapping[index] = game
                game.otherGame = otherGame(game)
                game.handleButtonA(pressed: true)
            }
        }
    }

    func otherGame(_ game: Game) -> Game {
        return game === game1 ? game2 : game1
    }

    func controllerInputDetected(gamepad: GCExtendedGamepad, element: GCControllerElement, index: Int) {
        handleButtonA(gamepad: gamepad, element: element, index: index)
        if let game = controllerIndexToGameMapping[index] {
            if gamepad.dpad.up.isPressed {
                game.desiredDirection = .up
            } else if gamepad.dpad.down.isPressed {
                game.desiredDirection = .down
            } else if gamepad.dpad.left.isPressed {
                game.desiredDirection = .left
            } else if gamepad.dpad.right.isPressed {
                game.desiredDirection = .right
            }

            if gamepad.leftThumbstick == element {
                if gamepad.leftThumbstick.up.isPressed {
                    game.desiredDirection = .up
                } else if gamepad.leftThumbstick.down.isPressed {
                    game.desiredDirection = .down
                } else if gamepad.leftThumbstick.left.isPressed {
                    game.desiredDirection = .left
                } else if gamepad.leftThumbstick.right.isPressed {
                    game.desiredDirection = .right
                }
            }
        }
    }

    override func sceneDidLoad() {
        self.backgroundColor = .black

        game1.gameNode.position.x = game2.gameNode.position.x - 250
        self.addChild(game1.gameNode)

        game2.gameNode.position.x = game2.gameNode.position.x + 250
        self.addChild(game2.gameNode)

        if let audioData = NSDataAsset(name: "soundtrack")?.data {
            do {
                audioPlayer = try AVAudioPlayer(data: audioData)
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.enableRate = true
                audioPlayer?.rate = 1.0
                audioPlayer?.play()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }

        switch key.keyCode {
        case .keyboardA:
            game1.handleButtonA(pressed: true)
        case .keyboardLeftArrow:
            game1.desiredDirection = .left
        case .keyboardRightArrow:
            game1.desiredDirection = .right
        case .keyboardUpArrow:
            game1.desiredDirection = .up
        case .keyboardDownArrow:
            game1.desiredDirection = .down
        default:
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else { return }

        switch key.keyCode {
        case .keyboardA:
            game1.handleButtonA(pressed: false)
        default:
            super.pressesEnded(presses, with: event)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Speed up sound when in scared (energized) mode
        audioPlayer?.rate = game1.scaredTimer != 0 || game2.scaredTimer != 0 ? 1.2 : 1.0

        game1.update()
        game2.update()
    }
}
