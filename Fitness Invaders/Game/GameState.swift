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
    var invaderRowCount: Int{ return 5 + level }
    var invaderColCount: Int{ return 5 + level }
    // how much health removed. Max value is 1
    var standardBombDamage: Float = -0.05
    var biggerBombDamage: Float = -0.1
    var biggestBombDamage: Float = -0.2
    // How many bullet hits to remove the bomb
    var standardBombHitsToKill: Int = 1
    var biggerBombHitsToKill: Int = 2
    var biggestBombHitsToKill: Int = 4
    // Used to decide what bombs are created.
    var standardBombWeighting: Double = 20
    var biggerBombWeighting: Double = 1
    var biggestBombWeighting: Double = 0.5
    var totalWeights: Double { return standardBombWeighting + biggerBombWeighting + biggerBombWeighting}
    var probabilityStandard: Double { return standardBombWeighting / totalWeights}
    var probabilityBigger: Double { return biggerBombWeighting / totalWeights }
    var probabilityBiggest: Double { return biggestBombWeighting / totalWeights }
    // Maximum bombs on screen at once
    var maxInvaderBombs = 1
    // speed of the invaders.
    var timePerMove: CFTimeInterval = 1.0
    // how long each invader takes to reload a bomb
    var bombReloadTime: CFTimeInterval = 2.0
    // this is a crude probability. I mutliply by number of invaders and if above 1 then definitely drop bomb.
    // really here to prevent a single invader just continually dropping a bomb.
    var probabilityOfBomb: Float = 0.5
    
    // MARK:- Defence variables.
    
    // whether ship bullets interact with invader bullets
    var shipBulletsKnockOutBombs: Bool{ return defence > 5}
    var shipHealth: Float = 1.0
    var shieldStrength: Float = 0.0
    var healthIncrementBetweenLevels: Float = 0.0
    var shieldIncrementBetweenLevels: Float = 0.0

    // MARK:- Attack variables
    
    // higher is better
    var maxShipBullets = 25
    // number of bullets fired at once
    var numberOfSimultaneousBullets = 7
    // force the ships gun applies to the bullet
    var bulletForce: Double = 10.0
    // length of time the force is applied for
    var bulletForceDuration: TimeInterval = 0.1
    // whether bullets go straight up or towards the screen tap
    var directionalBullets = true
    // When multiple bullets fired angle between adjacent bullets
    var bulletRadians: Double = Double.pi / 8
    // which walls bullets bounce off. 0x0 means none then have bitmasks:
    // ContactMasks.leftWall, ContactMasks.rightWall, ContactMasks.topWall, ContactMasks.bottomWall
    var wallsToBounceOff: UInt32 = ContactMasks.leftWall + ContactMasks.rightWall
    
    // MARK:- Score Variables
    var score: Int = 0
    var level: Int = 0
    
    private var userPowerUps: PowerUp = CoreDataStack.shared.getPowerUp()
    private var defence: Int16 { return userPowerUps.defence }
    private var attack: Int16 { return userPowerUps.attack }
    
    func advanceALevel(){
        level += 1
    }
}
