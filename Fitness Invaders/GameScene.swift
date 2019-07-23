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
    
    enum InvaderMovementDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    
    private let invaderSize = CGSize(width: 24, height: 16)
    private let invaderName = "invader"
    
    var tapQueue = [Int]()
    var tapDirection: CGPoint = CGPoint(x:0,y:0)
    var score: Int = 0
    var shipHealth: Float = 1.0
    let motionManager = CMMotionManager()
    
    let minInvaderBottomHeight: Float = 32.0
    var gameEnding: Bool = false
    
    let invaderGridSpace = CGSize(width: 2, height: 2)
    let invadorRowCount = 12
    let invadorColCount = 12

    let shipSize = CGSize(width: 30, height: 16)
    let shipName = "ship"
    let shipColour: SKColor = SKColor.white
    let shipBulletColour: SKColor = SKColor.white
    let maxShipBullets = 100
    // shorter is quicker
    let shipBulletDuration = 10.0
    let directionalBullets = true

    let scoreHUDName = "scoreHud"
    let healthHUDName = "healthHud"
    
    let shipBulletName = "shipBullet"
    let standardBombName = "standardBomb"
    let biggerBombName = "biggerBomb"
    let chanceOfBiggerBomb = 0.5
    let standardBombSize = CGSize(width:4, height: 8)
    let biggerBombSize = CGSize(width:8, height: 8)
    let standardBombColour = SKColor.black
    let biggerBombColour = SKColor.red
    let maxInvaderBombs = 1

    let invaderMask: UInt32 = 0x1 << 0
    let shipBulletMask: UInt32 = 0x1 << 1
    let shipMask: UInt32 = 0x1 << 2
    let sceneEdgeMask: UInt32 = 0x1 << 3
    let invaderBulletMask: UInt32 = 0x1 << 4
    
    var contentCreated = false
    var invaderMovementDirection: InvaderMovementDirection = .right
    var timeOfLastMove: CFTimeInterval = 0.0
    let timePerMove: CFTimeInterval = 0.25
    
    private var powerUps = CoreDataStack.shared.getPowerUp()
    
    override init(size: CGSize) {
        super.init(size: size)
        self.backgroundColor = MAIN_BLUE
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        if nodeNames.contains(shipName) && nodeNames.contains(standardBombName) {
            // Invader bullet hit a ship
            run(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            adjustShipHealth(by: -0.05  )
            if shipHealth <= 0.0 {
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                if let ship = childNode(withName: shipName) {
                    ship.alpha = CGFloat(shipHealth)
                    
                    if contact.bodyA.node == ship {
                        contact.bodyB.node!.removeFromParent()
                        
                    } else {
                        contact.bodyA.node!.removeFromParent()
                    }
                }
            }
            
        } else if nodeNames.contains(invaderName) && nodeNames.contains(shipBulletName) {
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
        let invader = childNode(withName: invaderName)
    
        var invaderTooLow = false
        
        enumerateChildNodes(withName: invaderName) { node, stop in
            if (Float(node.frame.minY) <= self.minInvaderBottomHeight)   {
                invaderTooLow = true
                stop.pointee = true
            }
        }
        let ship = childNode(withName: shipName)
        
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
                tapQueue.append(1)
                tapDirection = touch.location(in: self)
        }
    }


    
    func setupInvaders() {
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height * 0.62)
        for row in 0..<invadorRowCount {

            let invaderPositionY = CGFloat(row) * (invaderSize.height * 1.25) + baseOrigin.y
            
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            for _ in 1..<invadorColCount {
                let invader = makeInvader()
                invader.position = invaderPosition
                
                addChild(invader)
                
                invaderPosition = CGPoint(
                    x: invaderPosition.x + invaderSize.width + invaderGridSpace.width,
                    y: invaderPositionY
                )

            }
        }
    }
    
    func setupShip() {
        let ship = makeShip()
        
        ship.position = CGPoint(x: size.width / 2.0, y: shipSize.height / 2.0 + 20)
        addChild(ship)
    }

    
    func setupHud() {
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = scoreHUDName
        scoreLabel.fontSize = 25
        
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        scoreLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (40 + scoreLabel.frame.size.height/2)
        )
        addChild(scoreLabel)
        
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = healthHUDName
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
        
        if let score = childNode(withName: scoreHUDName) as? SKLabelNode {
            score.text = String(format: "Score: %04u", self.score)
        }
    }
    
    func adjustShipHealth(by healthAdjustment: Float) {
        shipHealth = max(shipHealth + healthAdjustment, 0)
        
        if let health = childNode(withName: healthHUDName) as? SKLabelNode {
            health.text = String(format: "Health: %.1f%%", self.shipHealth * 100)
        }
    }
    
    func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        determineInvaderMovementDirection()
        
        enumerateChildNodes(withName: invaderName) { node, stop in
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
        if let ship = childNode(withName: shipName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    ship.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))
                }
            }
        }
    }
    
    func determineInvaderMovementDirection() {
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        enumerateChildNodes(withName: invaderName) { node, stop in
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
    
    // MARK:- Node Creation
    
    func makeInvader() -> SKNode {
        let invader = SKSpriteNode(imageNamed: "dumbbell.png")
        invader.color = SKColor.white
        invader.name = invaderName
        invader.physicsBody = SKPhysicsBody(rectangleOf: invader.frame.size)
        invader.physicsBody!.isDynamic = false
        invader.physicsBody!.categoryBitMask = invaderMask
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        return invader
    }
    
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(color: shipColour, size: shipSize)
        ship.name = shipName
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        ship.physicsBody!.isDynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.1
        ship.physicsBody!.categoryBitMask = shipMask
        ship.physicsBody!.contactTestBitMask = 0x0
        ship.physicsBody!.collisionBitMask = sceneEdgeMask
        return ship
    }
    
    func makeBullet() -> SKNode {
        var bullet: SKSpriteNode
        bullet = SKSpriteNode(color: shipBulletColour, size: standardBombSize)
        bullet.name = shipBulletName
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
        bullet.physicsBody!.isDynamic = true
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = shipBulletMask
        bullet.physicsBody!.contactTestBitMask = invaderMask
        bullet.physicsBody!.collisionBitMask = 0x0
        return bullet
    }

    func makeBomb() -> SKSpriteNode {
        if Double.random(in: 0...1) <= chanceOfBiggerBomb{
            return makeBiggerBomb()
        }else{
            return makeStandardBomb()
        }
    }
   
    private func makeStandardBomb() -> SKSpriteNode {
        let bomb: SKSpriteNode = SKSpriteNode(color: standardBombColour, size: standardBombSize)
        bomb.name = standardBombName
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

    private func makeBiggerBomb() -> SKSpriteNode {
        let bomb: SKSpriteNode = SKSpriteNode(color: biggerBombColour, size: biggerBombSize)
        bomb.name = biggerBombName
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.frame.size)
        bomb.physicsBody!.isDynamic = true
        bomb.physicsBody!.affectedByGravity = true
        bomb.physicsBody!.friction = 5
        bomb.physicsBody!.linearDamping = 3
        bomb.physicsBody!.categoryBitMask = invaderBulletMask
        bomb.physicsBody!.contactTestBitMask = shipMask + sceneEdgeMask
        bomb.physicsBody!.collisionBitMask = 0x0
        return bomb
    }
    
    // MARK:- Firing / Dropping
    
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
        let currentBullets = children.filter({$0.name == shipBulletName}).count
        
        if currentBullets < maxShipBullets{
            if let ship = childNode(withName: shipName) {
                let bullet = makeBullet()
                bullet.position = CGPoint(
                    x: ship.position.x,
                    y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2
                )
//                let bulletDestination = directionalBullets ? tapDirection : CGPoint(x: ship.position.x, y: frame.size.height + bullet.frame.size.height / 2)
                let bulletDestination = directionalBullets ? extendTapLocationToBounds(from: bullet.position) : CGPoint(x: ship.position.x, y: frame.size.height + bullet.frame.size.height / 2)
                fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: shipBulletDuration, andSoundFileName: "ShipBullet.wav")
            }
        }
    }
    
    private func extendTapLocationToBounds(from: CGPoint) -> CGPoint{
        if let ship = childNode(withName: shipName){
            let y = frame.size.height
            let x = frame.size.width
            if tapDirection.x > ship.position.x{
                // tapped to right of ship
                let sideIntercept = tapDirection.y * (frame.size.width - ship.position.x) / (tapDirection.x - ship.position.x)
                if sideIntercept <= frame.size.height{
                    return CGPoint(x: frame.size.width, y: sideIntercept)
                }else{
                    let topIntercept = (tapDirection.x - ship.position.x) * (frame.size.height - ship.position.y) / (tapDirection.y - ship.position.y)
                    return CGPoint(x: topIntercept, y: frame.size.height)
                }
            }else if tapDirection.x < ship.position.x{
                // tappped to left of ship
                let sideIntercept = tapDirection.y * (ship.position.x) / (tapDirection.x - ship.position.x)
                if sideIntercept <= frame.size.height{
                    return CGPoint(x: 0, y: sideIntercept)
                }else{
                    let topIntercept = (ship.position.x - tapDirection.x) * (frame.size.height - ship.position.y) / (tapDirection.y - ship.position.y)
                    return CGPoint(x: topIntercept, y: frame.size.height)
                }
            }else{
                // amazing ... tapped directly above
                return CGPoint(x: ship.position.x, y: frame.size.height)
            }
        }else{
            return CGPoint(x: 0, y: 0)
        }
    }
    
    
    func dropInvaderBombs(forUpdate currentTime: CFTimeInterval) {
        let existingStandardBomb = childNode(withName: standardBombName)
        let existingBiggerBomb = childNode(withName: biggerBombName)
        let bombs = children.filter({$0.name == standardBombName || $0.name == biggerBombName}).count
        
        if (existingStandardBomb != nil) && (existingStandardBomb?.parent != nil) && !intersects(existingStandardBomb!){
            existingStandardBomb?.removeFromParent()
        }
        if (existingBiggerBomb != nil) && (existingBiggerBomb?.parent != nil) && !intersects(existingBiggerBomb!){
            existingBiggerBomb?.removeFromParent()
        }
        
        if bombs < maxInvaderBombs {
            var allInvaders = [SKNode]()
            
            enumerateChildNodes(withName: invaderName) { node, stop in
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
            }
        }
    }
    
    // MARK:-

    func processUserTaps(forUpdate currentTime: CFTimeInterval) {
        for tapCount in tapQueue {
            if tapCount == 1 {
                    fireShipBullets()
            }
            tapQueue.remove(at: 0)
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
