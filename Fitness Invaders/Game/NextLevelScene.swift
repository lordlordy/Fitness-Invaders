//
//  NextLevelScene.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 24/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//


import UIKit
import SpriteKit

class NextLevelScene: SKScene {
    
    // Private GameScene Properties
    
    var contentCreated = false
    var state: GameState?
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    
    override func didMove(to view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
        }
    }
    
    func createContent() {
        
        let nextLevelLabel = SKLabelNode(fontNamed: "Menlo")
        nextLevelLabel.fontSize = 30
        nextLevelLabel.fontColor = SKColor.white
        nextLevelLabel.text = "L\(state!.level - 1) Completed"
        nextLevelLabel.position = CGPoint(x: self.size.width/2, y: (2.0 / 3.0) * self.size.height);
        
        self.addChild(nextLevelLabel)
        
        let bonusLabel = SKLabelNode(fontNamed: "Menlo")
        bonusLabel.fontSize = 20
        bonusLabel.fontColor = SKColor.white
        bonusLabel.text = "Level Bonus: \(state!.bonus)"
        bonusLabel.position = CGPoint(x: self.size.width/2, y: nextLevelLabel.frame.origin.y - bonusLabel.frame.size.height);
        
        self.addChild(bonusLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "Menlo")
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.white
        scoreLabel.text = "Score: \(state!.score)"
        scoreLabel.position = CGPoint(x: self.size.width/2, y: bonusLabel.frame.origin.y - scoreLabel.frame.size.height - 20.0);
        
        self.addChild(scoreLabel)
        
        let tapLabel = SKLabelNode(fontNamed: "Menlo")
        tapLabel.fontSize = 20
        tapLabel.fontColor = SKColor.white
        tapLabel.text = "(Tap for Next Level)"
        tapLabel.position = CGPoint(x: self.size.width/2, y: frame.origin.y + 40);
        
        self.addChild(tapLabel)
        
        // black space color
        self.backgroundColor = SKColor.black
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)  {
        
        let gameScene = GameScene(size: self.size, gameState: nil)
        gameScene.scaleMode = .aspectFill
        if let state = state{
            gameScene.gameState = state
        }
        
        self.view?.presentScene(gameScene, transition: SKTransition.doorsCloseHorizontal(withDuration: 1.0))
        
    }
}
