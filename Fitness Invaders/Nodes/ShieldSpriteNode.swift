//
//  ShieldSpriteNode.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 25/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SpriteKit

class ShieldSpriteNode: SKSpriteNode{
    
    init(){
        let texture = SKTexture(imageNamed: "Shield")
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.name = NodeNames.shieldName
        self.physicsBody = SKPhysicsBody(rectangleOf: self.frame.size)
        self.physicsBody!.isDynamic = true
        self.physicsBody!.affectedByGravity = false
        self.physicsBody!.mass = 0.1
        self.physicsBody!.categoryBitMask = ContactMasks.shield
        self.physicsBody!.contactTestBitMask = 0x0
        self.physicsBody!.collisionBitMask = ContactMasks.sceneEdge
        self.size = CGSize(width: 60, height: 50)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
