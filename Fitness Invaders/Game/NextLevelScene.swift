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
    var previousState: GameState?
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    
    override func didMove(to view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
        }
    }
    
    func createContent() {
        
        let gameOverLabel = SKLabelNode(fontNamed: "Courier")
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.text = "On to Next Level!"
        gameOverLabel.position = CGPoint(x: self.size.width/2, y: 2.0 / 3.0 * self.size.height);
        
        self.addChild(gameOverLabel)
        
        let tapLabel = SKLabelNode(fontNamed: "Courier")
        tapLabel.fontSize = 25
        tapLabel.fontColor = SKColor.white
        tapLabel.text = "(Tap to Start Next Level)"
        tapLabel.position = CGPoint(x: self.size.width/2, y: gameOverLabel.frame.origin.y - gameOverLabel.frame.size.height - 40);
        
        self.addChild(tapLabel)
        
        // black space color
        self.backgroundColor = SKColor.black
        
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)  {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)  {
        
        let gameScene = GameScene(size: self.size, gameState: nil)
        gameScene.scaleMode = .aspectFill
        if let state = previousState{
            gameScene.gameState = state
        }
        
        self.view?.presentScene(gameScene, transition: SKTransition.doorsCloseHorizontal(withDuration: 1.0))
        
    }
}
