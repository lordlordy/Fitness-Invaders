//
//  GameState.swift
//  Fitness Invaders
//
//  Created by Steven Lord on 24/07/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import UIKit

class GameState{
 
    // MARK:- variables that used to increase difficulty through the levels
    // if screen isn't wide enough for row count then the number of rows will be increased to
    // keep the number of invaders approximately correct
    var invaderRowCount: Int{ return min(35, 5 + level) }
    var invaderColCount: Int{ return min(15, 5 + level) }
    // if the number of invaders on the screen falls below this level they will move quicker till
    // this number if visible
    var minInvadersOnScreen: Int {return 30 + level * 2}
    // how much health removed. Max value is 1
    var standardBombDamage: Float = -0.05
    var biggerBombDamage: Float = -0.1
    var biggestBombDamage: Float = -0.2
    var ultimateBombDamage: Float = -1.0
    // How many bullet hits to remove the bomb - probably should be moved out
    var standardBombHitsToKill: Int = 1
    var biggerBombHitsToKill: Int = 2
    var biggestBombHitsToKill: Int = 4
    var ultimateBombHitsToKill: Int = 10
    // Used to decide what bombs are created. The fixed amount and increment have been chosen such that
    // at level ~50 all types of bomb are equally likely. After that point the bigger bombs get
    // increasingly likely
    var standardBombWeighting: Double {return 10000 + Double(level)}
    var biggerBombWeighting: Double {return 1000 + Double(level) * 180}
    var biggestBombWeighting: Double {return 100 + Double(level) * 190}
    var ultimateBombWeighting: Double {return 1 + Double(level) * 191}
    var totalWeights: Double { return standardBombWeighting + biggerBombWeighting + biggestBombWeighting + ultimateBombWeighting}
    var probabilityStandard: Double {return standardBombWeighting / totalWeights}
    var probabilityBigger: Double { return biggerBombWeighting / totalWeights }
    var probabilityBiggest: Double { return biggestBombWeighting / totalWeights }
    var probabilityUltimate: Double { return ultimateBombWeighting / totalWeights }
    // Maximum bombs on screen at once
    var maxInvaderBombs: Int { return 1 + level/2}
    // amount of time between looking to create a bomb
    var timeBetweenBombs: CFTimeInterval { return 2.0 - 2.0 * Double(level) / Double(level + 1)}
    // speed of the invaders.
    var timePerMove: CFTimeInterval { return 0.1 + 1.0 / Double(level + 1)}
    // how long each invader takes to reload a bomb
    var bombReloadTime: CFTimeInterval { return 0.1 + 200.0 / Double(level + 1)}
    // Probability that if an invader is selected to drop a bomb that it will drop it
    // This function is asymptotic to 1. So as levels increase it gets ever closer
    // to certainty
    var probabilityOfBomb: Float { return Float(level + 1) / Float(level + 2)}
    // represents how low the invaders start
    var invadersStartHeight: CGFloat {return max(150.0, 500 - CGFloat(level) * 10)}
    
    // MARK:- Defence variables.
    
    // whether ship bullets interact with invader bullets
    var shipBulletsKnockOutBombs: Bool = true
    var shipHealth: Float = 1.0
    var shieldStrength: Float = 1.0
    var healthIncrementBetweenLevels: Float = 0.0
    var shieldIncrementBetweenLevels: Float = 0.0

    // MARK:- Attack variables
    
    // higher is better
    var maxShipBullets = 2
    // number of bullets fired at once
    var numberOfSimultaneousBullets = 3
    // force the ships gun applies to the bullet
    var bulletForce: Double = 5.0
    // length of time the force is applied for
    var bulletForceDuration: TimeInterval = 0.1
    // whether bullets go straight up or towards the screen tap
    var directionalBullets = true
    // When multiple bullets fired angle between adjacent bullets
    var bulletRadians: Double = Double.pi / 100
    // which walls bullets bounce off. 0x0 means none then have bitmasks:
    // ContactMasks.leftWall, ContactMasks.rightWall, ContactMasks.topWall, ContactMasks.bottomWall
    var wallsToBounceOff: UInt32 = 0
    
    // MARK:- Score Variables
    var score: Int = 0
    var level: Int = 0
    var bonus: Int { return level * level * 100}
    
    private var powerUp: PowerUp

    
    init(powerUp: PowerUp){
        self.powerUp = powerUp
        populateDefence()
        populateAttack()
    }
    
    func advanceALevel(){
        level += 1
        score += bonus
        shipHealth += healthIncrementBetweenLevels
        shieldStrength += shieldIncrementBetweenLevels
        print("\(probabilityStandard) / \(probabilityBigger) / \(probabilityBiggest) / \(probabilityUltimate)")

    }
    
    private func populateDefence(){
        shipBulletsKnockOutBombs = powerUp.defence >= GameState.defenceToKnockOutBombs
        shipHealth = 1.0 + Float(powerUp.defence) * 0.1
        if powerUp.defence >= GameState.defenceToGetShield{
            shieldStrength = 1.0 + Float(powerUp.defence - GameState.defenceToGetShield) * 0.05
        }
        if powerUp.defence >= GameState.defenceToGetHealthIncrements{
            healthIncrementBetweenLevels = Float(powerUp.defence - GameState.defenceToGetHealthIncrements + 1) * 0.05
        }
        if powerUp.defence >= GameState.defenceToGetShieldIncrements{
            shieldIncrementBetweenLevels = Float(powerUp.defence - GameState.defenceToGetShieldIncrements + 1) * 0.05
        }
    }
    
    private func populateAttack(){
        print("Polulating Attack")
        maxShipBullets = 1 + Int(powerUp.attack)
        numberOfSimultaneousBullets = 1 + Int(powerUp.attack / GameState.attackToGetExtraSimultaneousBullet)
        // calculate the angle to use to spread out simultaneous bullets. Want spread to tend towards pi/2 radians
        let totalSpread: Double = (Double.pi / 2) * Double(numberOfSimultaneousBullets) / Double(30 + numberOfSimultaneousBullets)
        if numberOfSimultaneousBullets > 1{
            bulletRadians = totalSpread / (Double(numberOfSimultaneousBullets - 1))
        }
        bulletForce = 5.0 + (15 * Double(powerUp.attack) / (Double(15 + powerUp.attack)))
        directionalBullets = powerUp.attack >= GameState.attackForDirectionalBullets
        if powerUp.attack >= GameState.attackForBounceOffWalls{
            wallsToBounceOff = ContactMasks.leftWall + ContactMasks.rightWall
        }
        if powerUp.attack >= GameState.attackForBounceOffRoof{
            wallsToBounceOff += ContactMasks.topWall
        }
        if powerUp.attack >= GameState.attackForBounceOffFloor{
            wallsToBounceOff += ContactMasks.bottomWall
        }
    }
    
    static let attackToGetExtraSimultaneousBullet: Int16 = 3
    static let attackForDirectionalBullets: Int16 = 5
    static let attackForBounceOffWalls: Int16 = 10
    static let attackForBounceOffRoof: Int16 = 20
    static let attackForBounceOffFloor: Int16 = 30

    
    static let defenceToGetShield: Int16 = 3
    static let defenceToGetHealthIncrements: Int16 = 8
    static let defenceToKnockOutBombs: Int16 = 6
    static let defenceToGetShieldIncrements: Int16 = 10
    
}
