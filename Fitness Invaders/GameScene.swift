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

    private var contactQueue = [SKPhysicsContact]()
    private var tapQueue = [Int]()
    private var tapDirection: CGPoint = CGPoint(x:0,y:0)
    private let motionManager = CMMotionManager()

    enum InvaderMovementDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    
    // MARK:- Node sizing
    
    private let invaderSize = CGSize(width: 24, height: 16)
    private let invaderGridSpace = CGSize(width: 1, height: 1)
    private let shipSize = CGSize(width: 50, height: 30)
    private let shieldSize = CGSize(width: 60, height: 50)
    private let shipBulletSize = CGSize(width:4, height: 8)
    private let minInvaderBottomHeight: Float = 32.0
    private let shipBulletColour: SKColor = SKColor.white

    
    // MARK:- variables that used to increase difficulty through the levels
    // if screen isn't wide enough for row count then the number of rows will be increased to
    // keep the number of invaders approximately correct
    private var invaderRowCount = 12
    private var invaderColCount = 12
    // how much health removed. Max value is 1
    let standardBombDamage: Float = -0.05
    let biggerBombDamage: Float = -0.1
    let biggestBombDamage: Float = -0.2
    let standardBombHitsToKill: Int = 1
    let biggerBombHitsToKill: Int = 2
    let biggestBombHitsToKill: Int = 4
    // This is the percentage of bombs that iwll be 'bigger' of the remaining the chance of a
    // biggest bomb is this again. So overal chance of biggest == chanceOfBiggerBomb ^ 2
    let chanceOfBiggerBomb = 0.1
    // Maximum bombs on screen at once
    let maxInvaderBombs = 20
    
    // MARK:- Defence variables.
    var shipBulletsKnockOutBombs = true
    var shipHealth: Float = 1.0
    var shieldStrength: Float = 0.0
    
    // MARK:- Attack variables
    // higher is better
    let maxShipBullets = 300
    // number of bullets fired at once
    let numberOfSimultaneousBullets = 3
    // shorter is quicker
    let shipBulletDuration = 1.0
    // whether bullets go straight up or towards the screen tap
    let directionalBullets = true
    
    // MARK:- Node Names
    
    private let invaderName = "invader"
    private let shipName = "ship"
    private let shieldName = "shield"
    private let scoreHUDName = "scoreHUD"
    private let healthHUDName = "healthHUD"
    private let shieldHUDName = "shieldHUD"
    private let shipBulletName = "shipBullet"
    
    // MARK:- Score Variables
    var score: Int = 0
    var level: Int = 0
    private var gameEnding: Bool = false
    
    var contentCreated = false
    var invaderMovementDirection: InvaderMovementDirection = .right
    var timeOfLastMove: CFTimeInterval = 0.0
    let timePerMove: CFTimeInterval = 0.1
    
    private var powerUps = CoreDataStack.shared.getPowerUp()
    private var gameState: GameState
    
    // MARK:- Initialisers

    init(size: CGSize, gameState state: GameState?) {
        if let gs = state{
            gameState = gs
        }else{
            gameState = GameState()
        }
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
    

    
    // MARK:- Content Creation
    
    func createContent() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        physicsBody!.categoryBitMask = ContactMasks.sceneEdge
        setupInvaders()
        setupShip()
        setupHud()
    }
    
    func setupInvaders() {
        let invadersPerRow = min(invaderColCount, Int(frame.width / (invaderSize.width + invaderGridSpace.width)) - 1)
        var numberOfRows = invaderRowCount
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height * 0.62)
        
        // need to adjust number of rows if we can't get appropriate number per row
        if invadersPerRow < invaderColCount{
            let totalInvaders = invaderColCount * invaderRowCount
            numberOfRows = Int(Double(totalInvaders) / Double(invadersPerRow))
        }
        
        for row in 0..<numberOfRows {
            
            let invaderPositionY = CGFloat(row) * (invaderSize.height * 1.25) + baseOrigin.y
            
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            for _ in 0..<invadersPerRow {
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
        let shield = makeShield()
        
        ship.position = CGPoint(x: size.width / 2.0, y: shipSize.height / 2.0 + 20)
        ship.position = CGPoint(x: size.width / 2.0, y: shipSize.height / 2.0 + 20)
        addChild(ship)
        shield.position = CGPoint(x: size.width / 2.0, y: shieldSize.height / 2.0 + 20)
        addChild(shield)
    }
    
    
    func setupHud() {
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = scoreHUDName
        scoreLabel.fontSize = 25
        
        scoreLabel.fontColor = SKColor.black
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
        
        let shieldLabel = SKLabelNode(fontNamed: "Courier")
        shieldLabel.name = shieldHUDName
        shieldLabel.fontSize = 25
        
        shieldLabel.fontColor = SKColor.green
        shieldLabel.text = String(format: "Shield: %.1f%%", shieldStrength * 100.0)
        shieldLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (80 + shieldLabel.frame.size.height/2)
        )
        addChild(shieldLabel)
    }
    
    // MARK:- Scoring
    
    
    func adjustScore(by points: Int) {
        score += points
        if let score = childNode(withName: scoreHUDName) as? SKLabelNode {
            score.text = String(format: "Score: %04u", self.score)
        }
    }
    
    func adjustShipHealth(by healthAdjustment: Float) {
        shipHealth = max(shipHealth + healthAdjustment, 0)
        if let health = childNode(withName: healthHUDName) as? SKLabelNode {
            health.text = String(format: "Health: %.0f%%", self.shipHealth * 100)
        }
    }
    
    func adjustShieldStength(by healthAdjustment: Float) {
        shieldStrength = max(shieldStrength + healthAdjustment, 0)
        if let shield = childNode(withName: shieldHUDName) as? SKLabelNode {
            shield.text = String(format: "Shield: %.0f%%", self.shieldStrength * 100)
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
        
        if invaderTooLow || ship == nil{
            print("GAME OVER")
        }else if invader == nil{
            print("LEVEL FINISHED")
            nextLevel()
        }
        
        
        return invader == nil || invaderTooLow || ship == nil
    }
    
    func nextLevel(){
        level += 1
        
    }
    
    func endGame() {
        if !gameEnding {
            gameEnding = true
            motionManager.stopAccelerometerUpdates()
            let gameOverScene: GameOverScene = GameOverScene(size: size)
            view?.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontal(withDuration: 1.0))
        }
    }
    
    
    // MARK:-
    
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
        if let shield = childNode(withName: shieldName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    shield.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))
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
        invader.physicsBody!.categoryBitMask = ContactMasks.invader
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        return invader
    }
    
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(imageNamed: "Ship.png")
        ship.name = shipName
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        ship.physicsBody!.isDynamic = true
        ship.physicsBody!.affectedByGravity = false
        ship.physicsBody!.mass = 0.1
        ship.physicsBody!.categoryBitMask = ContactMasks.ship
        ship.physicsBody!.contactTestBitMask = 0x0
        ship.physicsBody!.collisionBitMask = ContactMasks.sceneEdge
        return ship
    }
    
    func makeShield() -> SKNode{
        let shield = SKSpriteNode(imageNamed: "Shield.png")
        shield.name = shieldName
        shield.physicsBody = SKPhysicsBody(rectangleOf: shield.frame.size)
        shield.physicsBody!.isDynamic = true
        shield.physicsBody!.affectedByGravity = false
        shield.physicsBody!.mass = 0.1
        shield.physicsBody!.categoryBitMask = ContactMasks.shield
        shield.physicsBody!.contactTestBitMask = 0x0
        shield.physicsBody!.collisionBitMask = ContactMasks.sceneEdge
        return shield
    }
    
    func makeBullet() -> SKNode {
        var bullet: SKSpriteNode
        bullet = SKSpriteNode(color: shipBulletColour, size: shipBulletSize)
        bullet.name = shipBulletName
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
        bullet.physicsBody!.isDynamic = true
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = ContactMasks.shipBullet
        bullet.physicsBody!.contactTestBitMask = ContactMasks.invader + ContactMasks.bomb
        bullet.physicsBody!.collisionBitMask = 0x0
        return bullet
    }

    func makeBomb() -> SKSpriteNode {
        if Double.random(in: 0...1) <= chanceOfBiggerBomb{
            return BombSpriteNode(imageNamed: "biggerBomb.png", damage: biggerBombDamage, strength: biggerBombHitsToKill)
        }else if Double.random(in: 0...1) <= chanceOfBiggerBomb{
            return BombSpriteNode(imageNamed: "biggestBomb.png", damage: biggestBombDamage, strength: biggestBombHitsToKill)
        }else{
            return BombSpriteNode(imageNamed: "StandardBomb", damage: standardBombDamage, strength: standardBombHitsToKill)
        }
    }

    
    // MARK:- Firing / Dropping
    
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String?) {
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
            ])
        
        if let sound = soundName{
            let soundAction = SKAction.playSoundFileNamed(sound, waitForCompletion: true)
            bullet.run(SKAction.group([bulletAction, soundAction]))
        }else{
            bullet.run(SKAction.group([bulletAction]))
        }
        
        addChild(bullet)
    }
    
    func fireShipBullets() {
        let currentBullets = children.filter({$0.name == shipBulletName}).count
        
        if currentBullets < maxShipBullets{
            if let ship = childNode(withName: shipName) {
                let middle: Int = numberOfSimultaneousBullets % 2
                let pairs: Int = numberOfSimultaneousBullets / 2
                let bulletStartPosition = CGPoint(
                    x: ship.position.x,
                    y: ship.position.y + ship.frame.size.height - shipBulletSize.height / 2
                )
                let bulletDestination = directionalBullets ? extendTapLocationToBounds(from: bulletStartPosition) : CGPoint(x: ship.position.x, y: frame.size.height + shipBulletSize.height / 2)
                
                if middle == 1{
                    let bullet = makeBullet()
                    bullet.position = bulletStartPosition
    //                fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: shipBulletDuration, andSoundFileName: "ShipBullet.wav")
                    fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: shipBulletDuration, andSoundFileName: nil)
                }
                
                if pairs > 0{
                    for i in 1...pairs{
                        let bulletRight = makeBullet()
                        bulletRight.position = CGPoint(
                            x: ship.position.x,
                            y: ship.position.y + ship.frame.size.height - bulletRight.frame.size.height / 2
                        )
                        fireBullet(bullet: bulletRight, toDestination: CGPoint(x: bulletDestination.x + (CGFloat(i) * frame.width) / 8, y:bulletDestination.y), withDuration: shipBulletDuration, andSoundFileName: nil)
                        let bulletLeft = makeBullet()
                        bulletLeft.position = CGPoint(
                            x: ship.position.x,
                            y: ship.position.y + ship.frame.size.height - bulletLeft.frame.size.height / 2
                        )
                        fireBullet(bullet: bulletLeft, toDestination: CGPoint(x: bulletDestination.x - (CGFloat(i) * frame.width) / 8, y:bulletDestination.y), withDuration: shipBulletDuration, andSoundFileName: nil)
                    }
                }

            }
        }
    }
    
    private func extendTapLocationToBounds(from: CGPoint) -> CGPoint{
        if tapDirection.x > from.x{
            // tapped to right of ship
            let sideIntercept = tapDirection.y * (frame.size.width - from.x) / (tapDirection.x - from.x)
            if sideIntercept <= frame.size.height{
                return CGPoint(x: frame.size.width, y: sideIntercept)
            }else{
                let topIntercept = (tapDirection.x - from.x) * (frame.size.height - from.y) / (tapDirection.y - from.y)
                return CGPoint(x: from.x + topIntercept, y: frame.size.height)
            }
        }else if tapDirection.x < from.x{
            // tappped to left of ship
            let sideIntercept = tapDirection.y * (from.x) / (from.x - tapDirection.x)
            if sideIntercept <= frame.size.height{
                return CGPoint(x: 0, y: sideIntercept)
            }else{
                let topIntercept = (from.x - tapDirection.x) * (frame.size.height - from.y) / (tapDirection.y - from.y)
                return CGPoint(x: from.x - topIntercept, y: frame.size.height)
            }
        }else{
            // amazing ... tapped directly above
            return CGPoint(x: from.x, y: frame.size.height)
        }
    }
    
    
    func dropInvaderBombs(forUpdate currentTime: CFTimeInterval) {
        let existingBomb = childNode(withName: NodeNames.bomb)
        let bombs = children.filter({$0.name == NodeNames.bomb}).count
        
        if (existingBomb != nil) && (existingBomb?.parent != nil) && !intersects(existingBomb!){
            existingBomb?.removeFromParent()
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
    
    // MARK:- Handling Contacts
    
    func processContacts(forUpdate currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handle(contact)
            
            if let index = contactQueue.firstIndex(of: contact) {
                contactQueue.remove(at: index)
            }
        }
    }
    
    /* Handling the various contacts:
     1. Bomb with ship
     2. Bullet with invador
     3. Bullet with bomb
     4. Bomb with shield
 
 */
    private func handle(_ contact: SKPhysicsContact) {
        // Ensure you haven't already handled this contact and removed its nodes
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        let nodeBitMasks = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]

        if nodeBitMasks.contains(ContactMasks.ship) && nodeBitMasks.contains(ContactMasks.bomb){
            // handle ship being hit by invader bomb

            if let bomb = contact.bodyA.node as? BombSpriteNode{
                adjustShipHealth(by: bomb.damage)
            }else if let bomb = contact.bodyB.node as? BombSpriteNode{
                adjustShipHealth(by: bomb.damage)
            }
            
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
        } else if nodeBitMasks.contains(ContactMasks.shield) && nodeBitMasks.contains(ContactMasks.bomb){
            // handle shield being hit

            if let bomb = contact.bodyA.node as? BombSpriteNode{
                adjustShieldStength(by: bomb.damage)
            }else if let bomb = contact.bodyB.node as? BombSpriteNode{
                adjustShieldStength(by: bomb.damage)
            }
            if shieldStrength <= 0.0 {
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                if let shield = childNode(withName: shieldName) {
                    shield.alpha = CGFloat(shieldStrength)
                    if contact.bodyA.node == shield {
                        contact.bodyB.node!.removeFromParent()
                    } else {
                        contact.bodyA.node!.removeFromParent()
                    }
                }
            }
        }else if nodeBitMasks.contains(ContactMasks.invader) && nodeBitMasks.contains(ContactMasks.shipBullet){
            // Ship bullet hit an invader
//            run(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            adjustScore(by: 100)
        }
        
        if shipBulletsKnockOutBombs{
            // check if any contacts are between ship bullets and bombs
            if nodeBitMasks.contains(ContactMasks.shipBullet) && nodeBitMasks.contains(ContactMasks.bomb){
                if let bomb = contact.bodyA.node as? BombSpriteNode{
                    bomb.hit()
                    contact.bodyB.node?.removeFromParent()
                }else if let bomb = contact.bodyB.node as? BombSpriteNode{
                    bomb.hit()
                    contact.bodyA.node?.removeFromParent()
                }else{
                    contact.bodyA.node?.removeFromParent()
                    contact.bodyB.node?.removeFromParent()
                }
            }
        }
        
    }
    
}
