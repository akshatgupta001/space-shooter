//
//  GameScene.swift
//  SpaceShooter
//
//  Created by Akshat Gupta on 03/07/20.
//  Copyright © 2020 coded. All rights reserved.
//

import SpriteKit
import GameplayKit

enum collisionType : UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene {
    
    let player = SKSpriteNode(imageNamed: "player")
    
    let waves = Bundle.main.decode([Waves].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from : "enemy-types.json" )
    
    var isPlayerAlive = true
    var levelNumber = 0
    var waveNumber = 0
    
    let positions = Array(stride(from: -320, to: 400, by: 80))
   
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        
        if let particles = SKEmitterNode(fileNamed: "StarField"){
            particles.position = CGPoint(x: 1000, y: 0)
            particles.advanceSimulationTime(60)
            particles.zPosition = -1
            addChild(particles )
        }
        
        player.name = "player"
        player.position.x = frame.minX + 75
        player.position.y = frame.midY
        player.zPosition = 1
        addChild(player)
    
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture! .size())
        player.physicsBody?.categoryBitMask = collisionType.player.rawValue
        player.physicsBody?.collisionBitMask = collisionType.enemy.rawValue | collisionType.enemyWeapon.rawValue // only collide with these
        player.physicsBody?.contactTestBitMask = collisionType.enemy.rawValue | collisionType.enemyWeapon.rawValue //notify about these collisions
        
        player.physicsBody?.isDynamic = false
     
    
    }
    
    override func update(_ currentTime: TimeInterval) {
        for child in children {
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame){
                    child.removeFromParent()
                }
            }
        }
        let activeEnemies = children.compactMap{ $0 as? EnemyNode}
        if activeEnemies.isEmpty {
            createWave()
        }
    }
    
    func createWave() {
        guard  isPlayerAlive else { return }
        
        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }
        
        let currentWave = waves[waveNumber]
        waveNumber += 1
        
        let maximumEnemyType = min(enemyTypes.count, levelNumber+1)
        let enemyType = Int.random(in: 0..<maximumEnemyType)
        
        let enemyOffsetX : CGFloat = 100
        let enemyStartX = 700
        
        if currentWave.enemies.isEmpty {
            for (index,position) in positions.shuffled().enumerated(){
                let enemy = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: position), xOffset: enemyOffsetX * CGFloat(index * 3), moveStraight: true)
                addChild(enemy)
            }
        }else{
            for enemy in currentWave.enemies{
                let node = EnemyNode(type: enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: positions[enemy.position]), xOffset: enemyOffsetX * enemy.xOffset, moveStraight: enemy.moveStraight)
                addChild(node)
            }
        }
    }
}
