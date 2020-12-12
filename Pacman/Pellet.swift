//
//  Pellet.swift
//  Pacman
//
//  Copyright © 2020 Roger Wetzel. All rights reserved.
//

import SpriteKit

class Pellet {
    var isEaten = false
    var framesToWaitWhenAte = 0
    var shape = SKEffectNode()

    init(_ x: Int, _ y: Int) {
        isEaten = false
        shape.shouldRasterize = true
    }

    func reset() {
        isEaten = false
        shape.isHidden = false
    }
}
