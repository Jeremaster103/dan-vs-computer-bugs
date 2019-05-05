//
//  GamePhysics.swift
//  DanVsComputerBugs
//
//  Created by Jeremy Millard on 5/1/19.
//  Copyright © 2019 Jeremy Millard. All rights reserved.
//

import Foundation
import SpriteKit

struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let enemy   : UInt32 = 0b1
    static let projectile: UInt32 = 0b10
    static let badproj: UInt32 = 0b1000
    static let player: UInt32 = 0b100
    static let powerup: UInt32 = 0b10000
    static let shockwave: UInt32 = 0b110
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if secondBody.categoryBitMask == PhysicsCategory.shockwave {
            return
        }
        
        if (firstBody.categoryBitMask == PhysicsCategory.shockwave) &&
            (secondBody.categoryBitMask & PhysicsCategory.badproj != 0) {
            if let projectile = secondBody.node as? SKSpriteNode {
                projectile.removeFromParent()
            }
            return
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.enemy != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
            if let enemy = firstBody.node as? SKSpriteNode,
                let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithEnemy(projectile: projectile, enemy: enemy)
            }
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.player != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.badproj != 0)) {
            if let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithPlayer(projectile: projectile)
            }
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.player != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.powerup != 0)) {
            if let powerup = secondBody.node as? SKSpriteNode {
                playerCollectedPowerup(powerup: powerup)
            }
        }
    }
    
    func playerCollectedPowerup(powerup: SKSpriteNode) {
        powerup.removeFromParent()
        if powerup.name == "gauntlet" {
            killHalfEnemies()
        }
        if powerup.name == "campanile" {
            soundWave()
        }
        if powerup.name == "oski" {
            oski()
        }
    }
    
    func projectileDidCollideWithPlayer(projectile: SKSpriteNode) {
        projectile.removeFromParent()
        if oskiTimer > 0 {
            return
        }
        
        let seq = [SKAction.colorize(with: UIColor.red, colorBlendFactor: 0.5, duration: 0.25), SKAction.colorize(with: UIColor.red, colorBlendFactor: 0, duration: 0.25)]
        player.run(SKAction.sequence(seq))
        
        playerHP -= 1
        
        if playerHP == 0 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        healthBarPos.scale(to: CGSize(width: playerHP * 10, height: 5))
    }
    
    func projectileDidCollideWithEnemy(projectile: SKSpriteNode, enemy: SKSpriteNode) {
        projectile.removeFromParent()
        createExplosion(location: CGPoint(x: projectile.position.x, y: projectile.position.y + (projectile.size.height / 2)))
        var win = false
        for e in enemies {
            if e.node == enemy {
                e.hp -= 1
                if e.hp == 0 {
                    score += enemyScoreValues[e.enemyType] ?? 10
                    scoreLabel.text = "Score: " + String(score)
                    enemy.removeFromParent()
                    if e.enemyType == .boss {
                        win = true
                    } else {
                        if nextPowerup == 0 {
                            dropPowerup(position: enemy.position)
                            nextPowerup = Int(random(min: 8, max: 16))
                        } else {
                            nextPowerup -= 1
                        }
                    }
                }
                break
            }
        }
        
        if win {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func setEnemyProjPhysics(_ projectile: SKSpriteNode) {
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.badproj
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.player
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true
    }
}


