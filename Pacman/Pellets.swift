//
//  Pellets.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Pellets {
    let dotsAndEnergizers = // . = dot   o = energizer
        "____________________________" +
        "____________________________" +
        "____________________________" +
        "||||||||||||||||||||||||||||" +
        "|............||............|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|o||||.|||||.||.|||||.||||o|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|..........................|" +
        "|.||||.||.||||||||.||.||||.|" +
        "|.||||.||.||||||||.||.||||.|" +
        "|......||....||....||......|" +
        "||||||.||||| || |||||.||||||" +
        "_____|.||||| || |||||.|_____" +
        "_____|.||          ||.|_____" +
        "_____|.|| |||--||| ||.|_____" +
        "||||||.|| |______| ||.||||||" +
        "      .   |______|   .      " +
        "||||||.|| |______| ||.||||||" +
        "_____|.|| |||||||| ||.|_____" +
        "_____|.||          ||.|_____" +
        "_____|.|| |||||||| ||.|_____" +
        "||||||.|| |||||||| ||.||||||" +
        "|............||............|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|.||||.|||||.||.|||||.||||.|" +
        "|o..||.......  .......||..o|" +
        "|||.||.||.||||||||.||.||.|||" +
        "|||.||.||.||||||||.||.||.|||" +
        "|......||....||....||......|" +
        "|.||||||||||.||.||||||||||.|" +
        "|.||||||||||.||.||||||||||.|" +
        "|..........................|" +
        "||||||||||||||||||||||||||||" +
        "____________________________" +
        "____________________________"

    enum State {
        case reset, hide, show
    }
    
    var pellets = [[Pellet?]]()
    let node = SKEffectNode()
    var energizers = [Energizer]() // In order to make them blink
    var tick = 0

    var state: State = .reset {
        didSet {
            switch state {
            case .show:
                node.isHidden = false
            case .hide:
                node.isHidden = true
            case .reset:
                for y in 0..<Constants.boardHeight {
                    for x in 0..<Constants.boardWidth {
                        pellets[y][x]?.reset()
                    }
                }
                tick = 0
            }
        }
    }

    init() {
        initPellets()
    }

    func initPellets() {
        for y in 0..<Constants.boardHeight {
            var row = [Pellet?]()
            for x in 0..<Constants.boardWidth {
                if let pellet = createPellet(x, y) {
                    node.addChild(pellet.shape)
                    row.append(pellet)
                    if let energizer = pellet as? Energizer {
                        energizers.append(energizer)
                    }
                } else {
                    row.append(nil)
                }
            }
            pellets.append(row)
        }
        node.shouldRasterize = true
    }

    func createPellet(_ x: Int, _ y: Int) -> Pellet? {
        var pellet: Pellet? = nil

        let row = Constants.boardHeight - 1 - y
        let index = row * Constants.boardWidth + x
        if index >= 0 && index < dotsAndEnergizers.count {
            if dotsAndEnergizers[index] == "." {
                pellet = Dot(x, y)
            } else if dotsAndEnergizers[index] == "o" {
                pellet = Energizer(x, y)
            }
        }

        return pellet
    }

    func blinkEnergizers() {
        if tick % 10 == 0 {
            for energizer in energizers {
                energizer.blink()
            }
        }
    }

    func update() {
        blinkEnergizers()
        tick += 1
    }
}
