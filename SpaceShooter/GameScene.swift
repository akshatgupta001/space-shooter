//
//  GameScene.swift
//  SpaceShooter
//
//  Created by Akshat Gupta on 03/07/20.
//  Copyright © 2020 coded. All rights reserved.
//

import SpriteKit
import CoreMotion

enum collisionType : UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene , SKPhysicsContactDelegate{
    
    let motionManager = CMMotionManager()
    
    let player = SKSpriteNode(imageNamed: "player")
    
    let waves = Bundle.main.decode([Waves].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from : "enemy-types.json" )
    
    var isPlayerAlive = true
    var levelNumber = 0
    var waveNumber = 0
    var playerShields = 4
    
    let scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Thin")
    var score = 0 {
           didSet {
               let formatter = NumberFormatter()
               formatter.numberStyle = .decimal
               let formattedScore = formatter.string(from: score as NSNumber) ?? "0"
               scoreLabel.text = "Score : \(formattedScore)"
           }
       }
    
    let positions = Array(stride(from: -320, to: 400, by: 80))
   
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        if let particles = SKEmitterNode(fileNamed: "StarField"){
            particles.position = CGPoint(x: 1000, y: 0)
            particles.advanceSimulationTime(60)
            particles.zPosition = -1
            addChild(particles )
        }
        
        scoreLabel.fontSize = 64
        scoreLabel.position = CGPoint(x:frame.minX, y: frame.minY)
        scoreLabel.text = "Score : 0"
        scoreLabel.zPosition = 100
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
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
     
        motionManager.startAccelerometerUpdates()
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if let accelerometerData = motionManager.accelerometerData{
            player.position.y = CGFloat(accelerometerData.acceleration.x * 400)
            
            if player.position.y < frame.minY {
                player.position.y = frame.minY
            }else if player.position.y > frame.maxY{
                player.position.y = frame.maxY
            }
        }
        
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
        
        for enemy in activeEnemies{
            guard frame.intersects(enemy.frame) else {continue}
            if enemy.lastFireTime + 1 < currentTime{
                enemy.lastFireTime = currentTime
                
                if Int.random(in: 0...4) == 0 {
                    enemy.fire()
                }
            }
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
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlayerAlive else {return}
        
        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.name = "playerWeapon"
        shot.position = player.position
        
        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = collisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = collisionType.enemy.rawValue | collisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = collisionType.enemy.rawValue | collisionType.enemyWeapon.rawValue
        
        addChild(shot)
        
        let movement = SKAction.move(to: CGPoint(x: 1900, y: shot.position.y), duration: 5)
        let sequence = SKAction.sequence([movement,.removeFromParent()])
        shot.run(sequence )
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else {return }
        guard let nodeB = contact.bodyB.node else {return }
        
        let sortedNodes = [nodeA,nodeB].sorted { $0.name ?? "" < $1.name ?? ""}
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]
        
        if secondNode.name == "player"{
            guard isPlayerAlive else { return }
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion"){
                explosion.position = firstNode.position
                addChild(explosion)
            }
            
            playerShields -= 1
            
            if playerShields == 0 {
                gameover()
                secondNode.removeFromParent()
            }
            firstNode.removeFromParent()
        }else if let enemy = firstNode as? EnemyNode{
            score += Int( 50 * enemy.shields)
            enemy.shields -= 1
            
            if enemy.shields == 0 {
                if let explosion = SKEmitterNode(fileNamed: "Explosion"){
                    explosion.position = enemy.position
                    addChild(explosion)
                }
                enemy.removeFromParent()
            }
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion"){
                explosion.position = secondNode.position
                addChild(explosion)
            }
            secondNode.removeFromParent()
            
        }else {
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion"){
               explosion.position = secondNode.position
               addChild(explosion)
            }
            
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
    }
    
    func gameover() {
         isPlayerAlive = false
         
        if let explosion = SKEmitterNode(fileNamed: "Explosion"){
           explosion.position = player.position
           addChild(explosion)
        }
        
        let gameover = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameover)
    }
}
