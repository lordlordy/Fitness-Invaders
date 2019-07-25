//
//  BulletSpriteNode.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 25/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SpriteKit

class BulletSpriteNode: SKSpriteNode{
    
    init(wallBitMask: UInt32){
        let texture = SKTexture(imageNamed: "shipBullet")
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.name = NodeNames.shipBulletName
        self.physicsBody = SKPhysicsBody(rectangleOf: shipBulletSize)
        self.physicsBody!.isDynamic = true
        self.physicsBody!.affectedByGravity = false
        self.physicsBody!.categoryBitMask = ContactMasks.shipBullet
        self.physicsBody!.contactTestBitMask = ContactMasks.invader + ContactMasks.bomb + ContactMasks.sceneEdge
        self.physicsBody!.collisionBitMask = wallBitMask
        self.physicsBody!.restitution = 1.0
        self.physicsBody!.linearDamping = 0.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
}
