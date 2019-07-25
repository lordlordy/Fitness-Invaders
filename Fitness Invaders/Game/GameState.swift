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
    var invaderRowCount = 15
    var invaderColCount = 15
    // how much health removed. Max value is 1
    var standardBombDamage: Float = -0.05
    var biggerBombDamage: Float = -0.1
    var biggestBombDamage: Float = -0.2
    var standardBombHitsToKill: Int = 1
    var biggerBombHitsToKill: Int = 2
    var biggestBombHitsToKill: Int = 4
    // This is the percentage of bombs that iwll be 'bigger' of the remaining the chance of a
    // biggest bomb is this again. So overal chance of biggest == chanceOfBiggerBomb ^ 2
    var chanceOfBiggerBomb = 0.6
    // Maximum bombs on screen at once
    var maxInvaderBombs = 1
    var timePerMove: CFTimeInterval = 1.0
    var timePerBomb: CFTimeInterval = 2.0
    // this is a crude probability. I mutliply by number of invaders and if above 1 then definitely drop bomb.
    // really here to prevent a single invader just continually dropping a bomb.
    var probabilityOfBomb: Float = 1.0
    
    // MARK:- Defence variables.
    
    var shipBulletsKnockOutBombs = true
    var shipHealth: Float = 1.0
    var shieldStrength: Float = 1.0
    
    // MARK:- Attack variables
    
    // higher is better
    var maxShipBullets = 12
    // number of bullets fired at once
    var numberOfSimultaneousBullets = 1
    // shorter is quicker
    var shipBulletDuration = 1.0
    var bulletForce = 10
    // whether bullets go straight up or towards the screen tap
    var directionalBullets = true
    // This is how many bullets across the screen. So bigger number means bullets closer together
    var bulletSpread: CGFloat = 16
    
    // MARK:- Score Variables
    var score: Int = 0
    var level: Int = 0
    
}
