//
//  ShipSpriteNode.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 25/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SpriteKit

class ShipSpriteNode: SKSpriteNode{
    
    init(){
        let texture = SKTexture(imageNamed: "Ship")
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.name = NodeNames.shipName
        self.physicsBody = SKPhysicsBody(rectangleOf: self.frame.size)
        self.physicsBody!.isDynamic = true
        self.physicsBody!.affectedByGravity = false
        self.physicsBody!.mass = 0.1
        self.physicsBody!.categoryBitMask = ContactMasks.ship
        self.physicsBody!.contactTestBitMask = 0x0
        self.physicsBody!.collisionBitMask = ContactMasks.sceneEdge
        self.size = CGSize(width: 50, height: 30)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
