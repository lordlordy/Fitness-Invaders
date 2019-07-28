//
//  GameOverScene.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 15/06/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {
    
    // Private GameScene Properties
    
    var contentCreated = false
    var score: Int?
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    
    override func didMove(to view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
        }
    }
    
    func createContent() {
        
        let gameOverLabel = SKLabelNode(fontNamed: "Menlo")
        gameOverLabel.fontSize = 50
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.text = "Game Over!"
        gameOverLabel.position = CGPoint(x: self.size.width/2, y: 2.0 / 3.0 * self.size.height);
        self.addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "Menlo")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: self.size.width/2, y: gameOverLabel.position.y - 50);
        let nf: NumberFormatter = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        if let s = score{
            if s >= CoreDataStack.shared.highestScore(){
                CoreDataStack.shared.updateHighestScore(with: Int64(s))
                scoreLabel.text = "New High Score: \(nf.string(from: NSNumber(value: s)) ?? "0")"
            }else{
                scoreLabel.text = "Score: \(nf.string(from: NSNumber(value: s)) ?? "0")"
            }
        }
        self.addChild(scoreLabel)
        
        let tapLabel = SKLabelNode(fontNamed: "Menlo")
        tapLabel.fontSize = 20
        tapLabel.fontColor = SKColor.white
        tapLabel.text = "(Tap to Play Again)"
        tapLabel.position = CGPoint(x: self.size.width/2, y: gameOverLabel.frame.origin.y - gameOverLabel.frame.size.height - 40);
        
        self.addChild(tapLabel)
        
        // black space color
        self.backgroundColor = SKColor.black
        
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)  {
        
        let gameScene = GameScene(size: self.size, gameState: nil)
        gameScene.scaleMode = .aspectFill
        
        self.view?.presentScene(gameScene, transition: SKTransition.doorsCloseHorizontal(withDuration: 1.0))
        
    }
}
