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
    private let minInvaderBottomHeight: CGFloat = 40.0
    private let scoreFontSize: CGFloat = 16
    private let labelPadding: CGFloat = 5

    
    private var gameEnding: Bool = false
    private var levelEnding: Bool = false
    private var gameEnded: Bool = false
    private var levelEnded: Bool = false

    var contentCreated = false
    var invaderMovementDirection: InvaderMovementDirection = .right
    var timeOfLastMove: CFTimeInterval = 0.0
    var timeOfLastBomb: CFTimeInterval = 0.0

    
    private var powerUps = CoreDataStack.shared.getPowerUp()
    var gameState: GameState
    
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
        print(frame)
        physicsBody?.friction = 0.0
        
        physicsBody!.categoryBitMask = ContactMasks.sceneEdge
        setupInvaders()
        setupShip()
        setupHud()
    }
    
    func setupInvaders() {
        let invadersPerRow = min(gameState.invaderColCount, Int(frame.width / (invaderSize.width + invaderGridSpace.width)) - 1)
        var numberOfRows = gameState.invaderRowCount
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height * 0.62)
        
        // need to adjust number of rows if we can't get appropriate number per row
        if invadersPerRow < gameState.invaderColCount{
            let totalInvaders = gameState.invaderColCount * gameState.invaderRowCount
            numberOfRows = Int(Double(totalInvaders) / Double(invadersPerRow))
        }
        
        for row in 0..<numberOfRows {
            
            let invaderPositionY = CGFloat(row) * (invaderSize.height * 1.25) + baseOrigin.y
            
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            for _ in 0..<invadersPerRow {
                let invader = InvaderSpriteNode(imageNamed: "dumbbell.png", timeBetweenBombs: gameState.timePerBomb, chanceOfBomb: gameState.probabilityOfBomb)

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
        let ship = ShipSpriteNode()
        ship.position = CGPoint(x: size.width / 2.0, y: ship.size.height / 2.0 + minInvaderBottomHeight)
        addChild(ship)
        
        if gameState.shieldStrength > 0.0{
            let shield = ShieldSpriteNode()
            shield.position = CGPoint(x: size.width / 2.0, y: shield.size.height / 2.0 + minInvaderBottomHeight + 20)
            addChild(shield)
        }
    }
    
    
    func setupHud() {
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = NodeNames.scoreHUDName
        scoreLabel.fontSize = scoreFontSize
        
        scoreLabel.fontColor = SKColor.black
        scoreLabel.text = String(format: "%04u", gameState.score)
        
        scoreLabel.position = CGPoint(
            x: frame.size.width/2,
            y: scoreLabel.frame.height + labelPadding
        )
        addChild(scoreLabel)
        
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = NodeNames.healthHUDName
        healthLabel.fontSize = scoreFontSize
        
        healthLabel.fontColor = SKColor.blue
        healthLabel.text = String(format: "Health:%.0f%", gameState.shipHealth * 100.0)
        healthLabel.position = CGPoint(
            x: healthLabel.frame.size.width / 2,
            y: healthLabel.frame.size.height + labelPadding
        )
        addChild(healthLabel)
        
        let shieldLabel = SKLabelNode(fontNamed: "Courier")
        shieldLabel.name = NodeNames.shieldHUDName
        shieldLabel.fontSize = scoreFontSize
        
        shieldLabel.fontColor = SKColor.green
        shieldLabel.text = String(format: "Shield:%.0f%", gameState.shieldStrength * 100.0)
        shieldLabel.position = CGPoint(
            x: frame.size.width - shieldLabel.frame.size.width / 2 - labelPadding,
            y: shieldLabel.frame.size.height + labelPadding
        )
        addChild(shieldLabel)
    }
    
    // MARK:- Scoring
    
    
    func adjustScore(by points: Int) {
        gameState.score += points
        if let score = childNode(withName: NodeNames.scoreHUDName) as? SKLabelNode {
            score.text = String(format: "%04u", gameState.score)
        }
    }
    
    func adjustShipHealth(by healthAdjustment: Float) {
        gameState.shipHealth = max(gameState.shipHealth + healthAdjustment, 0)
        if let health = childNode(withName: NodeNames.healthHUDName) as? SKLabelNode {
            health.text = String(format: "Health:%.0f%", gameState.shipHealth * 100)
        }
    }
    
    func adjustShieldStength(by healthAdjustment: Float) {
        gameState.shieldStrength = max(gameState.shieldStrength + healthAdjustment, 0)
        if let shield = childNode(withName: NodeNames.shieldHUDName) as? SKLabelNode {
            shield.text = String(format: "Shield:%.0f%", gameState.shieldStrength * 100)
        }
    }
    
    private func hasLevelEnded() -> Bool {
        
        // no invaders left
        if childNode(withName: NodeNames.invaderName) == nil{
            print("Level Finished")
            gameEnded = false
            levelEnded = true
            return true
        }
        
        // no ship.
        if childNode(withName: NodeNames.shipName) == nil{
            print("GAME OVER")
            gameEnded = true
            levelEnded = false
            return true
        }
        
        var invaderTooLow = false
        // check whether any are too low
        enumerateChildNodes(withName: NodeNames.invaderName) { node, stop in
            if (node.frame.minY <= self.minInvaderBottomHeight)   {
                invaderTooLow = true
                stop.pointee = true
            }
        }
        
        // invaders reached the bottom
        if invaderTooLow{
            print("GAME OVER")
            gameEnded = true
            levelEnded = false
            return true
        }
        return false
        
    }
    
    func nextLevel(){
        if !levelEnding {
            levelEnding = true
            motionManager.stopAccelerometerUpdates()
            let nextLevelScene: NextLevelScene = NextLevelScene(size: size)
            nextLevelScene.previousState = self.gameState
            view?.presentScene(nextLevelScene, transition: SKTransition.doorsOpenHorizontal(withDuration: 1.0))
        }
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
        if hasLevelEnded() {
            if gameEnded{
                endGame()
            }else{
                nextLevel()
            }
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
        if (currentTime - timeOfLastMove < gameState.timePerMove) {
            return
        }
        
        determineInvaderMovementDirection()
        
        enumerateChildNodes(withName: NodeNames.invaderName) { node, stop in
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
        if let ship = childNode(withName: NodeNames.shipName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    ship.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))
                }
            }
        }
        if let shield = childNode(withName: NodeNames.shieldName) as? SKSpriteNode {
            if let data = motionManager.accelerometerData {
                if fabs(data.acceleration.x) > 0.2 {
                    shield.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))
                }
            }
        }
    }
    
    func determineInvaderMovementDirection() {
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        enumerateChildNodes(withName: NodeNames.invaderName) { node, stop in
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
    
    // MARK:- Bomb Creation
    

    func makeBomb() -> SKSpriteNode {
        if Double.random(in: 0...1) <= gameState.chanceOfBiggerBomb{
            return BombSpriteNode(imageNamed: "biggerBomb.png", damage: gameState.biggerBombDamage, strength: gameState.biggerBombHitsToKill, mass: BombMass.Bigger)
        }else if Double.random(in: 0...1) <= gameState.chanceOfBiggerBomb{
            return BombSpriteNode(imageNamed: "biggestBomb.png", damage: gameState.biggestBombDamage, strength: gameState.biggestBombHitsToKill, mass: BombMass.Biggest)
        }else{
            return BombSpriteNode(imageNamed: "StandardBomb", damage: gameState.standardBombDamage, strength: gameState.standardBombHitsToKill, mass: BombMass.Standard)
        }
    }

    
    // MARK:- Firing / Dropping
    
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String?) {
        

        
//        let bulletAction = SKAction.sequence([
//            SKAction.move(to: destination, duration: duration),
//            SKAction.wait(forDuration: 3.0 / 60.0),
//            SKAction.removeFromParent()
//            ])
//
//        if let sound = soundName{
//            let soundAction = SKAction.playSoundFileNamed(sound, waitForCompletion: true)
//            bullet.run(SKAction.group([bulletAction, soundAction]))
//        }else{
//            bullet.run(SKAction.group([bulletAction]))
//        }
        
        addChild(bullet)
        let force = SKAction.applyForce(CGVector(dx: 0, dy: gameState.bulletForce) , duration: 0.1)
        bullet.run(force)
    }
    
    func fireShipBullets() {
        
        // TO DO
        // Shouldn't need to do this. Instead should detect contact between bullet and screen edge and then
        // remove
        let existingBullet = childNode(withName: NodeNames.shipBulletName)
        // remove bullets that have left the screen
        if existingBullet != nil && existingBullet!.parent != nil && !intersects(existingBullet!){
            existingBullet?.removeFromParent()
        }
        
        let currentBullets = children.filter({$0.name == NodeNames.shipBulletName}).count
        
        if currentBullets < gameState.maxShipBullets{
            if let ship = childNode(withName: NodeNames.shipName) {
                let middle: Int = gameState.numberOfSimultaneousBullets % 2
                let pairs: Int = gameState.numberOfSimultaneousBullets / 2
                let bulletStartPosition = CGPoint(
                    x: ship.position.x,
                    y: ship.position.y + ship.frame.size.height - shipBulletSize.height / 2
                )
                let bulletDestination = gameState.directionalBullets ? extendTapLocationToBounds(from: bulletStartPosition) : CGPoint(x: ship.position.x, y: frame.size.height + shipBulletSize.height / 2)
                
                if middle == 1{
                    let bullet = BulletSpriteNode()
                    bullet.position = bulletStartPosition
    //                fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: shipBulletDuration, andSoundFileName: "ShipBullet.wav")
                    fireBullet(bullet: bullet, toDestination: bulletDestination, withDuration: gameState.shipBulletDuration, andSoundFileName: nil)
                }
                
                if pairs > 0{
                    for i in 1...pairs{
                        let bulletRight = BulletSpriteNode()
                        bulletRight.position = CGPoint(
                            x: ship.position.x,
                            y: ship.position.y + ship.frame.size.height - bulletRight.frame.size.height / 2
                        )
                        fireBullet(bullet: bulletRight, toDestination: CGPoint(x: bulletDestination.x + (CGFloat(i) * frame.width) / gameState.bulletSpread, y:bulletDestination.y), withDuration: gameState.shipBulletDuration, andSoundFileName: nil)
                        let bulletLeft = BulletSpriteNode()
                        bulletLeft.position = CGPoint(
                            x: ship.position.x,
                            y: ship.position.y + ship.frame.size.height - bulletLeft.frame.size.height / 2
                        )
                        fireBullet(bullet: bulletLeft, toDestination: CGPoint(x: bulletDestination.x - (CGFloat(i) * frame.width) / gameState.bulletSpread, y:bulletDestination.y), withDuration: gameState.shipBulletDuration, andSoundFileName: nil)
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
        
        // this removes the bomb if it is outside the frame
        if (existingBomb != nil) && (existingBomb?.parent != nil) && !intersects(existingBomb!){
            existingBomb?.removeFromParent()
        }
        
        if bombs < gameState.maxInvaderBombs {
            var allInvaders = [SKNode]()
            
            enumerateChildNodes(withName: NodeNames.invaderName) { node, stop in
                allInvaders.append(node)
            }
            
            if allInvaders.count > 0 {
                let allInvadersIndex = Int(arc4random_uniform(UInt32(allInvaders.count)))
                let invader = allInvaders[allInvadersIndex]
                
                if let i = invader as? InvaderSpriteNode{
                    if i.canDropBomb(atTime: currentTime){
                        let bomb = makeBomb()
                        bomb.position = CGPoint(
                            x: invader.position.x,
                            y: invader.position.y - invader.frame.size.height / 2 + bomb.frame.size.height / 2
                        )
                        addChild(bomb)
                    }
                }
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
     5. Bullet with edge of screen
     6. Bomb with edge of screen
 
 */
    private func handle(_ contact: SKPhysicsContact) {
        // Ensure you haven't already handled this contact and removed its nodes
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        let nodeBitMasks = [contact.bodyA.categoryBitMask, contact.bodyB.categoryBitMask]
        print(nodeBitMasks)
        if nodeBitMasks.contains(ContactMasks.ship) && nodeBitMasks.contains(ContactMasks.bomb){
            // handle ship being hit by invader bomb

            if let bomb = contact.bodyA.node as? BombSpriteNode{
                adjustShipHealth(by: bomb.damage)
            }else if let bomb = contact.bodyB.node as? BombSpriteNode{
                adjustShipHealth(by: bomb.damage)
            }
            
            if gameState.shipHealth <= 0.0 {
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                if let ship = childNode(withName: NodeNames.shipName) {
                    ship.alpha = CGFloat(0.15 + gameState.shipHealth)
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
            if gameState.shieldStrength <= 0.0 {
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                if let shield = childNode(withName: NodeNames.shieldName) {
                    shield.alpha = CGFloat(gameState.shieldStrength)
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
        }else if nodeBitMasks.contains(ContactMasks.sceneEdge) && nodeBitMasks.contains(ContactMasks.shipBullet){
            // bullet hits edge of sreen - remov it
            print("bullet contacts edge:")
            if let n = contact.bodyA.node as? BulletSpriteNode{
                n.removeFromParent()
            }else if let n = contact.bodyB.node as? BulletSpriteNode{
                n.removeFromParent()
            }
            
        }
        
        if gameState.shipBulletsKnockOutBombs{
            // check if any contacts are between ship bullets and bombs
            if nodeBitMasks.contains(ContactMasks.shipBullet) && nodeBitMasks.contains(ContactMasks.bomb){
                if let bomb = contact.bodyA.node as? BombSpriteNode{
                    gameState.score += bomb.hit()
                    contact.bodyB.node?.removeFromParent()
                }else if let bomb = contact.bodyB.node as? BombSpriteNode{
                    gameState.score += bomb.hit()
                    contact.bodyA.node?.removeFromParent()
                }else{
                    contact.bodyA.node?.removeFromParent()
                    contact.bodyB.node?.removeFromParent()
                }
            }
        }
        
    }
    
}
