//
//  Powerups.swift
//  DanVsComputerBugs
//
//  Created by Jeremy Millard on 5/1/19.
//  Copyright © 2019 Jeremy Millard. All rights reserved.
//

import Foundation
import SpriteKit

extension GameScene {
    
    func dropPowerup(position: CGPoint) {
        var name = "oski"
        if powerupID == 1 {
            name = "campanile"
        }
        if powerupID == 2 {
            name = "gauntlet"
            powerupID = -1
        }
        powerupID += 1
        let powerup = SKSpriteNode(imageNamed: name)
        powerup.name = name
        powerup.position = position
        powerup.zPosition = 15
        
        powerup.physicsBody = SKPhysicsBody(rectangleOf: powerup.size)
        powerup.physicsBody?.isDynamic = true
        powerup.physicsBody?.categoryBitMask = PhysicsCategory.powerup
        powerup.physicsBody?.contactTestBitMask = PhysicsCategory.player
        powerup.physicsBody?.collisionBitMask = PhysicsCategory.none
        powerup.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(powerup)
        
        let dur = position.y * 0.01
        
        let actionMove = SKAction.move(to: CGPoint(x: position.x, y: -100), duration: TimeInterval(dur))
        let actionMoveDone = SKAction.removeFromParent()
        powerup.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func killHalfEnemies() {
        let gauntlet = SKSpriteNode(imageNamed: "gauntlet")
        gauntlet.position = CGPoint(x: player.position.x + 50, y: player.position.y - 10)
        gauntlet.zPosition = 200
        addChild(gauntlet)
        
        let snap = SKSpriteNode(imageNamed: "Snap!")
        snap.position = CGPoint(x: gauntlet.position.x, y: gauntlet.position.y + 50)
        snap.zPosition = 200
        addChild(snap)
        
        let seq = SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.fadeOut(withDuration: 1.0),
                                     SKAction.removeFromParent()])
        gauntlet.run(seq)
        snap.run(seq)
        
        var i = enemies.endIndex
        while i > 0 {
            i -= 1
            if i % 2 == 0 {
                let enemy = enemies[i]
                enemy.node.removeAllActions()
                let grp = SKAction.group([SKAction.colorize(with: UIColor.black, colorBlendFactor: 0.7, duration: 2), SKAction.fadeOut(withDuration: 1)])
                let seq = SKAction.sequence([grp, SKAction.removeFromParent()])
                enemy.node.run(seq)
                score += enemyScoreValues[enemy.enemyType] ?? 10
                scoreLabel.text = "Score: " + String(score)
                enemies.remove(at: i)
            }
        }
    }
    
    func soundWave() {
        let campanile = SKSpriteNode(imageNamed: "campanile")
        campanile.position = CGPoint(x: player.position.x + 50, y: player.position.y - 10)
        campanile.zPosition = 200
        addChild(campanile)
        let seq = SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.fadeOut(withDuration: 1.0),
                                     SKAction.removeFromParent()])
        campanile.run(seq)
        
        // send shockwave that removes projectiles on collision
        let wave = SKSpriteNode(imageNamed: "music-notes")
        wave.position = CGPoint(x: frame.width / 2, y: -20)
        wave.zPosition = 99
        let actionMove = SKAction.move(to: CGPoint(x: frame.width / 2, y: frame.height + 100), duration: 0.5)
        let actionSeq = SKAction.sequence([actionMove, SKAction.removeFromParent()])
        wave.physicsBody = SKPhysicsBody(rectangleOf: wave.size)
        wave.physicsBody?.isDynamic = true
        wave.physicsBody?.categoryBitMask = PhysicsCategory.shockwave
        wave.physicsBody?.contactTestBitMask = PhysicsCategory.badproj
        wave.physicsBody?.collisionBitMask = PhysicsCategory.none
        wave.physicsBody?.usesPreciseCollisionDetection = true
        addChild(wave)
        wave.run(actionSeq)
        
        let bell = SKAudioNode(fileNamed: "bell.wav")
        bell.autoplayLooped = false
        addChild(bell)
        bell.run(SKAction.play())
    }
    
    func oski() {
        let snd = SKAudioNode(fileNamed: "Cal.mp3")
        snd.autoplayLooped = false
        addChild(snd)
        let seq = [SKAction.play(), SKAction.wait(forDuration: 10), SKAction.stop()]
        snd.run(SKAction.sequence(seq))
        player.run(SKAction.setTexture(SKTexture(imageNamed: "oski")))
        oskiTimer = 40
    }
    
}
