 //
//  EnemyType.swift
//  SpaceShooter
//
//  Created by Akshat Gupta on 04/07/20.
//  Copyright © 2020 coded. All rights reserved.
//

import SpriteKit
 
 struct EnemyType : Codable {
    let name : String
    let shields : Int
    let speed : CGFloat
    let powerUpChance : Int
 }
