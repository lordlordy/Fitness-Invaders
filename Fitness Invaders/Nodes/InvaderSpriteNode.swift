//
//  InvaderSpriteNode.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 25/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SpriteKit

class InvaderSpriteNode: SKSpriteNode{

    var timeBetweenBombs: CFTimeInterval
    var lastBombDropped:  CFTimeInterval = 0.0
    private var chanceOfBomb: Float = 1.0
    
    init(imageNamed: String, timeBetweenBombs: CFTimeInterval, chanceOfBomb prob: Float){
        let texture = SKTexture(imageNamed: imageNamed)
        self.timeBetweenBombs = timeBetweenBombs
        self.chanceOfBomb = prob
        super.init(texture: texture, color: UIColor.clear, size: texture.size())
        self.color = SKColor.white
        self.name = NodeNames.invaderName
        self.physicsBody = SKPhysicsBody(rectangleOf: self.frame.size)
        self.physicsBody!.isDynamic = false
        self.physicsBody!.categoryBitMask = ContactMasks.invader
        self.physicsBody!.contactTestBitMask = 0x0
        self.physicsBody!.collisionBitMask = 0x0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func canDropBomb(atTime time: CFTimeInterval) -> Bool{
        if time - lastBombDropped < timeBetweenBombs{
            return false
        }else{
            lastBombDropped = time
            return Float.random(in: 0...1) <= chanceOfBomb
        }
    }
    
    
}
