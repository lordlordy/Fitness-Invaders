//
//  Constants.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 23/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SpriteKit

let MAIN_BLUE: SKColor = SKColor(displayP3Red: 26.0/255.0, green: 120.0/255.0, blue: 184.0/255.0, alpha: 1.0)
let shipBulletSize = CGSize(width:5, height: 8)

struct NodeNames{
    static let bomb = "bomb"
    static let invaderName = "invader"
    static let shipName = "ship"
    static let shieldName = "shield"
    static let scoreHUDName = "scoreHUD"
    static let healthHUDName = "healthHUD"
    static let shieldHUDName = "shieldHUD"
    static let shipBulletName = "shipBullet"
}

struct BombMass{
    static let Standard: CGFloat = 1
    static let Bigger: CGFloat = 2
    static let Biggest: CGFloat = 4
}

struct ContactMasks{
    static let sceneEdge: UInt32 = 0x1 << 0
    static let invader: UInt32 = 0x1 << 1
    static let shipBullet: UInt32 = 0x1 << 2
    static let ship: UInt32 = 0x1 << 3
    static let bomb: UInt32 = 0x1 << 4
    static let shield: UInt32 = 0x1 << 5
    
}
