//
//  Wave.swift
//  SpaceShooter
//
//  Created by Akshat Gupta on 04/07/20.
//  Copyright © 2020 coded. All rights reserved.
//

import SpriteKit

struct Waves : Codable {
    struct WaveEnemy : Codable {
        let position : Int
        let xOffset : CGFloat
        let moveStraight : Bool
    }
    
    let name : String
    let enemies : [WaveEnemy]
}
