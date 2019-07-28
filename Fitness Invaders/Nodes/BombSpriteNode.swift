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
    private var timeOfLastBomb: CFTimeInterval = 0.0
    private var health: Int = 1
    
    init(imageNamed: String, damage: Float, strength: Int, mass: CGFloat){
        let texture = SKTexture(imageNamed: imageNamed)
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.damage = damage
        self.hitsToKill = strength
        self.health = strength
        self.name = NodeNames.bomb
        self.physicsBody = SKPhysicsBody(rectangleOf: self.frame.size)
        self.physicsBody?.mass = mass
        self.physicsBody!.isDynamic = true
        self.physicsBody!.affectedByGravity = true
        self.physicsBody!.friction = 0
        self.physicsBody!.linearDamping = 1.0
        self.physicsBody!.categoryBitMask = ContactMasks.bomb
        self.physicsBody!.contactTestBitMask = ContactMasks.ship + ContactMasks.sceneEdge + ContactMasks.shipBullet + ContactMasks.shield
        self.physicsBody!.collisionBitMask = 0x0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hit() -> Int{
        health = health - 1
        damage = damage * 0.75
        self.alpha = self.alpha * 0.75
        if health <= 0{
            self.removeFromParent()
            return hitsToKill
        }
        return 0
    }

    
}
