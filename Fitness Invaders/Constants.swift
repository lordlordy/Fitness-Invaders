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


struct NodeNames{
    static let bomb = "bomb"
}

struct ContactMasks{
    static let invader: UInt32 = 0x1 << 0
    static let shipBullet: UInt32 = 0x1 << 1
    static let ship: UInt32 = 0x1 << 2
    static let sceneEdge: UInt32 = 0x1 << 3
    static let bomb: UInt32 = 0x1 << 4
    static let shield: UInt32 = 0x1 << 5
    
    static func bombContacts() -> UInt32{
        return ship + sceneEdge + shipBullet + shield
    }
}
