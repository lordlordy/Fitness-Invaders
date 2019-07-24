//
//  BombSpriteNode.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 24/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SpriteKit

class BombSpriteNode: SKSpriteNode{
    
    var damage: Float = 0.0
    var hitsToKill: Int = 1
    
    init(imageNamed: String, damage: Float, strength: Int){
        let texture = SKTexture(imageNamed: imageNamed)
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.damage = damage
        self.hitsToKill = strength
        self.name = NodeNames.bomb
        self.physicsBody = SKPhysicsBody(rectangleOf: self.frame.size)
        self.physicsBody!.isDynamic = true
        self.physicsBody!.affectedByGravity = true
        self.physicsBody!.friction = 10
        self.physicsBody!.linearDamping = 3
        self.physicsBody!.categoryBitMask = ContactMasks.bomb
        self.physicsBody!.contactTestBitMask = ContactMasks.bombContacts()
        self.physicsBody!.collisionBitMask = 0x0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hit(){
        hitsToKill = hitsToKill - 1
        if hitsToKill <= 0{
            self.removeFromParent()
        }
    }
    
}
