//
//  GameScene.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 14/06/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    var contactQueue = [SKPhysicsContact]()
    
    enum BulletType {
        case shipFired
        case invaderFired
    }
    
    enum InvaderMovementDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    
    enum InvaderType {
        case a
        case b
        case c
        
        static var size: CGSize {
            return CGSize(width: 24, height: 16)
        }
        
        static var name: String {
            return "invader"
        }
    }
    
    var invaderColours = [SKColor.blue, SKColor.green, SKColor.red, SKColor.orange, SKColor.purple, SKColor.yellow, SKColor.magenta, SKColor.white, SKColor.cyan, SKColor.gray]
    
    var tapQueue = [Int]()
    var tapDirection: CGPoint = CGPoint(x:0,y:0)
    var score: Int = 0
    var shipHealth: Float = 1.0
    let motionManager = CMMotionManager()
    
    let minInvaderBottomHeight: Float = 32.0
    var gameEnding: Bool = false
    
    let invaderGridSpace = CGSize(width: 2, height: 2)
    let invadorRowCount = 40
    let invadorColCount = 12
    
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let invaderDroppedBombName = "invaderDroppedBomb"
    let kBulletSize = CGSize(width:4, height: 8)
    
    let invaderMask: UInt32 = 0x1 << 0
    let shipBulletMask: UInt32 = 0x1 << 1
    let shipMask: UInt32 = 0x1 << 2
    let sceneEdgeMask: UInt32 = 0x1 << 3
    let invaderBulletMask: UInt32 = 0x1 << 4
    
    var contentCreated = false
    var invaderMovementDirection: InvaderMovementDirection = .right
    var timeOfLastMove: CFTimeInterval = 0.0
    let timePerMove: CFTimeInterval = 0.5
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    override func didMove(to view: SKView) {
        
        if (!self.contentCreated) {
            self.createContent()
            self.contentCreated = true
            motionManager.startAccelerometerUpdates()
            physicsWorld.contactDelegate = self
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        contactQueue.append(contact)
    }
    
    
    
    func handle(_ contact: SKPhysicsContact) {
        // Ensure you haven't already handled this contact and removed its nodes
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        
        let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        if nodeNames.contains(kShipName) && nodeNames.contains(invaderDroppedBombName) {
            // Invader bullet hit a ship
            run(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            adjustShipHealth(by: -0.05  )
            if shipHealth <= 0.0 {
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                if let ship = childNode(withName: kShipName) {
                    ship.alpha = CGFloat(shipHealth)
                    
                    if contact.bodyA.node == ship {
                        contact.bodyB.node!.removeFromParent()
                        
                    } else {
                        contact.bodyA.node!.removeFromParent()
                    }
                }
            }
            
        } else if nodeNames.contains(InvaderType.name) && nodeNames.contains(kShipFiredBulletName) {
            // Ship bullet hit an invader
            run(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            adjustScore(by: 100)
        }else{
            print(contact)
        }
    }
    
    func isGameOver() -> Bool {
        let invader = childNode(withName: InvaderType.name)
    
        var invaderTooLow = false
        
        enumerateChildNodes(withName: InvaderType.name) { node, stop in
            if (Float(node.frame.minY) <= self.minInvaderBottomHeight)   {
                invaderTooLow = true
                stop.pointee = true
            }
        }
        let ship = childNode(withName: kShipName)
        
        return invader == nil || invaderTooLow || ship == nil
    }
    
    func endGame() {
        if !gameEnding {
            gameEnding = true
            motionManager.stopAccelerometerUpdates()
            let gameOverScene: GameOverScene = GameOverScene(size: size)
            view?.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontal(withDuration: 1.0))
        }
    }
    
    func createContent() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        physicsBody!.categoryBitMask = sceneEdgeMask
        setupInvaders()
        setupShip()
        setupHud()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isGameOver() {
            endGame()
        }
        
        processContacts(forUpdate: currentTime)
        processUserTaps(forUpdate: currentTime)
        processUserMotion(forUpdate: currentTime)
        moveInvaders(forUpdate: currentTime)
        dropInvaderBombs(forUpdate: currentTime)
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // processing like this ensures we process just one point at a time
            // this merely notes a tap has happened. The taps are processed in the
            // update method by a call to processUserTaps
            if (touch.tapCount == 1) {
                tapQueue.append(1)
                tapDirection = touch.location(in: self)
            }
            // if we just fire bullets from here they'll fire for every tap - ie rapidly
            // this can be a power up
            fireDirectionalShipBullets(touchLocation: touch.location(in: self))
        }
        
    }

    func makeInvader(ofType invaderType: InvaderType) -> SKNode {
        var invaderColor: SKColor
        
        switch(invaderType) {
        case .a:
            invaderColor = SKColor.orange
        case .b:
            invaderColor = SKColor.red
        case .c:
            invaderColor = SKColor.green
        }
        
        let randomInt: Int = Int.random(in: 0...9)
        invaderColor = invaderColours[randomInt]
//        let invader = SKSpriteNode(color: invaderColor, size: InvaderType.size)
//        let t = SKTexture(imageNamed: "dumbbell.png")
        let invader = SKSpriteNode(imageNamed: "dumbbell.png")
        invader.name = InvaderType.name
        invader.physicsBody = SKPhysicsBody(rectangleOf: invader.frame.size)
        invader.physicsBody!.isDynamic = false
        invader.physicsBody!.categoryBitMask = invaderMask
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        return invader
    }
    
    func setupInvaders() {
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height * 0.62)
        for row in 0..<invadorRowCount {
            var invaderType: InvaderType
            
            if row % 3 == 0 {
                invaderType = .a
            } else if row % 3 == 1 {
                invaderType = .b
            } else {
                invaderType = .c
            }
            
            let invaderPositionY = CGFloat(row) * (InvaderType.size.height * 1.25) + baseOrigin.y
            
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            for _ in 1..<invadorColCount {
                let invader = makeInvader(ofType: invaderType)
                invader.position = invaderPosition
                
                addChild(invader)
                
                invaderPosition = CGPoint(
                    x: invaderPosition.x + InvaderType.size.width + invaderGridSpace.width,
                    y: invaderPositionY
                )

            }
        }
    }
    
    func setupShip() {
        let ship = makeShip()
        
        ship.position = CGPoint(x: size.width / 2.0, y: kShipSize.height / 2.0 + 20)
        addChild(ship)
    }
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(color: SKColor.purple, size: kShipSize)
        ship.name = kShipName
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        ship.physicsBody!.isDynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.02
        ship.physicsBody!.categoryBitMask = shipMask
        ship.physicsBody!.contactTestBitMask = 0x0
        ship.physicsBody!.collisionBitMask = sceneEdgeMask
        return ship
    }
    
    func setupHud() {
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        scoreLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (40 + scoreLabel.frame.size.height/2)
        )
        addChild(scoreLabel)
        
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        healthLabel.fontColor = SKColor.red
        healthLabel.text = String(format: "Health: %.1f%%", shipHealth * 100.0)
        healthLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (60 + healthLabel.frame.size.height/2)
        )
        addChild(healthLabel)
    }
    
    func adjustScore(by points: Int) {
        score += points
        
        if let score = childNode(withName: kScoreHudName) as? SKLabelNode {
            score.text = String(format: "Score: %04u", self.score)
        }
    }
    
    func adjustShipHealth(by healthAdjustment: Float) {
        shipHealth = max(shipHealth + healthAdjustment, 0)
        
        if let health = childNode(withName: kHealthHudName) as? SKLabelNode {
            health.text = String(format: "Health: %.1f%%", self.shipHealth * 100)
        }
    }
    
    func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        determineInvaderMovementDirection()
        
        enumerateChildNodes(withName: InvaderType.name) { node, stop in
            switch self.invaderMovementDirection {
            case .right:
                node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
            case .left:
                node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
            case .downThenLeft, .downThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
            case .none:
                break
            }
            
            self.timeOfLastMove = currentTime
        }
    }
    
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        if let ship = childNode(withName: kShipName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    ship.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))
                }
            }
        }
    }
    
    func determineInvaderMovementDirection() {
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        enumerateChildNodes(withName: InvaderType.name) { node, stop in
            switch self.invaderMovementDirection {
            case .right:
                if (node.frame.maxX >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .downThenLeft
                    
                    stop.pointee = true
                }
            case .left:
                if (node.frame.minX <= 1.0) {
                    proposedMovementDirection = .downThenRight
                    
                    stop.pointee = true
                }
            case .downThenLeft:
                proposedMovementDirection = .left
                stop.pointee = true
            case .downThenRight:
                proposedMovementDirection = .right
                stop.pointee = true
            default:
                break
            }
            
        }
        
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
    
    func makeBullet(ofType bulletType: BulletType) -> SKNode {
        var bullet: SKSpriteNode
        
        switch bulletType {
        case .shipFired:
            bullet = SKSpriteNode(color: SKColor.green, size: kBulletSize)
            bullet.name = kShipFiredBulletName
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
            bullet.physicsBody!.isDynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = shipBulletMask
            bullet.physicsBody!.contactTestBitMask = invaderMask
            bullet.physicsBody!.collisionBitMask = 0x0
        case .invaderFired:
            bullet = SKSpriteNode(color: SKColor.magenta, size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
            bullet.physicsBody!.isDynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = invaderBulletMask
            bullet.physicsBody!.contactTestBitMask = shipMask
            bullet.physicsBody!.collisionBitMask = 0x0
            break
        }
        
        return bullet
    }

    func makeBomb() -> SKSpriteNode {
        let bomb: SKSpriteNode = SKSpriteNode(color: SKColor.magenta, size: kBulletSize)
        bomb.name = invaderDroppedBombName
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.frame.size)
        bomb.physicsBody!.isDynamic = true
        bomb.physicsBody!.affectedByGravity = true
        bomb.physicsBody!.friction = 10
        bomb.physicsBody!.linearDamping = 3
        bomb.physicsBody!.categoryBitMask = invaderBulletMask
        bomb.physicsBody!.contactTestBitMask = shipMask + sceneEdgeMask
        bomb.physicsBody!.collisionBitMask = 0x0
        return bomb
    }
    
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
            ])
        
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        bullet.run(SKAction.group([bulletAction, soundAction]))
        
        addChild(bullet)
    }
    
    func fireShipBullets() {
        let existingBullet = childNode(withName: kShipFiredBulletName)
        
        if existingBullet == nil {
            if let ship = childNode(withName: kShipName) {
                let bullet = makeBullet(ofType: .shipFired)
                bullet.position = CGPoint(
                    x: ship.position.x,
                    y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2
                )
                let bulletDestination = CGPoint(
                    x: ship.position.x,
                    y: frame.size.height + bullet.frame.size.height / 2
                )
                fireBullet(
                    bullet: bullet,
                    toDestination: bulletDestination,
                    withDuration: 1.0,
                    andSoundFileName: "ShipBullet.wav"
                )
            }
        }
    }
    
    func fireDirectionalShipBullets(touchLocation: CGPoint) {
        
        if let ship = childNode(withName: kShipName) {
            let bullet = makeBullet(ofType: .shipFired)
            bullet.position = CGPoint(
                x: ship.position.x,
                y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2
            )
            let bulletDestination = touchLocation
            fireBullet(
                bullet: bullet,
                toDestination: bulletDestination,
                withDuration: 1.0,
                andSoundFileName: "ShipBullet.wav"
            )
        }
    }

    func processUserTaps(forUpdate currentTime: CFTimeInterval) {
        for tapCount in tapQueue {
            if tapCount == 1 {
//                fireShipBullets()
                fireDirectionalShipBullets(touchLocation: tapDirection)
            }
            tapQueue.remove(at: 0)
        }
    }
    
    func dropInvaderBombs(forUpdate currentTime: CFTimeInterval) {
        let existingBomb = childNode(withName: invaderDroppedBombName)
        
        if (existingBomb != nil) && (existingBomb?.parent != nil) && !intersects(existingBomb!){
            existingBomb?.removeFromParent()
        }
        
        if existingBomb == nil {
            var allInvaders = [SKNode]()
            
            enumerateChildNodes(withName: InvaderType.name) { node, stop in
                allInvaders.append(node)
            }
            
            if allInvaders.count > 0 {
                let allInvadersIndex = Int(arc4random_uniform(UInt32(allInvaders.count)))
                let invader = allInvaders[allInvadersIndex]
                let bomb = makeBomb()
                bomb.position = CGPoint(
                    x: invader.position.x,
                    y: invader.position.y - invader.frame.size.height / 2 + bomb.frame.size.height / 2
                )
                
                addChild(bomb)
//                let bombDestination = CGPoint(x: invader.position.x, y: -(bomb.frame.size.height / 2))
//
//                fireBullet(
//                    bullet: bomb,
//                    toDestination: bombDestination,
//                    withDuration: 2.0,
//                    andSoundFileName: "InvaderBullet.wav"
//                )
            }
        }
    }
    
    func processContacts(forUpdate currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handle(contact)
            
            if let index = contactQueue.firstIndex(of: contact) {
                contactQueue.remove(at: index)
            }
        }
    }
    
}
