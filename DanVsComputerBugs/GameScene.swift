//
//  GameScene.swift
//  DanVsComputerBugs
//
//  Created by Jeremy Millard on 4/16/19.
//  Copyright © 2019 Jeremy Millard. All rights reserved.
//

import SpriteKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene {
    
    let enemyProjectileTypes = [EnemyType.spider: "green_fireball", EnemyType.roach: "green_fireball"]
    
    var enemiesToSpawn = 10
    var gameTimer = 0
    var currentWave = 1
    var currentMaxSpawnTime = 7
    var nextPowerup = 5
    
    let player = SKSpriteNode(imageNamed: "dan")
    let healthBarPos = SKSpriteNode(color: .green, size: CGSize(width: 80, height: 5))
    let healthBarNeg = SKSpriteNode(color: .red, size: CGSize(width: 80, height: 5))
    
    var playerHP = 8
    
    var oskiTimer = -1
    
    // demo only
    var powerupID = 0
    
    let enemyScoreValues = [EnemyType.spider: 10, EnemyType.roach: 40, EnemyType.beetle: 50, EnemyType.boss: 1000]
    var score = 0
    let scoreLabel = SKLabelNode(fontNamed: "STHeitiTC-Medium")
    
    var bossSpawned = false
    
    var backgroundMusic = SKAudioNode(fileNamed: "Androids.wav")
    
    var bossVolleyCooldown = 10
    
    var enemies: [Enemy] = []
    
    var background = SKSpriteNode(imageNamed: "bg")
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.white
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        background.zPosition = 1
        addChild(background)
        player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.1)
        player.zPosition = 2
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width/3)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        healthBarPos.position = CGPoint(x: player.position.x - 40, y: player.position.y - 40)
        healthBarPos.zPosition = 200
        healthBarPos.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBarNeg.position = CGPoint(x: player.position.x - 40, y: player.position.y - 40)
        healthBarNeg.zPosition = 199
        healthBarNeg.anchorPoint = CGPoint(x: 0, y: 0.5)
        addChild(healthBarPos)
        addChild(healthBarNeg)
        
        scoreLabel.text = "Score: " + String(score)
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.red
        scoreLabel.position = CGPoint(x: frame.size.width - 100, y: frame.size.height - 50)
        scoreLabel.zPosition = 201
        addChild(scoreLabel)
        
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(playerFireProjectile),
                SKAction.run(addEnemy),
                SKAction.run(tickEnemies),
                SKAction.wait(forDuration: 0.25)
                ])
        ))
        backgroundMusic = SKAudioNode(fileNamed: "POL-galactic-trek-short.wav")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        displayWaveLabel()
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func displayWaveLabel() {
        let label = SKLabelNode(text: "Wave " + String(currentWave))
        if currentWave == 4 {
            label.text = "Final Wave"
        }
        label.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        label.alpha = CGFloat(1.0)
        label.fontName = "Chalkduster"
        label.fontSize = 45.0
        label.zPosition = 99
        addChild(label)
        label.run(SKAction.sequence([SKAction.wait(forDuration: 3), SKAction.fadeOut(withDuration: 2), SKAction.removeFromParent()]))
    }
    
    func tickEnemies() {
        var i = enemies.endIndex
        if i == 0 {
            if enemiesToSpawn == 0 {
                // next wave
                currentWave += 1
                switch currentWave {
                case 2:
                    enemiesToSpawn = 20
                    break
                case 3:
                    currentMaxSpawnTime = 5
                    enemiesToSpawn = 40
                    break
                default:
                    enemiesToSpawn = 10
                    break
                }
                displayWaveLabel()
            }
            return
        }
        while i > 0 {
            i -= 1
            if !enemies[i].tick() {
                enemies.remove(at: i)
            }
        }
    }
    
    func addEnemy() {
        if gameTimer > 0 {
            gameTimer -= 1
            return
        }
        if enemiesToSpawn == 0 {
            return
        }
        enemiesToSpawn -= 1
        
        gameTimer = Int(arc4random_uniform(UInt32(currentMaxSpawnTime)))
        
        var hp = 1
        var fireDelay = 9
        var speed = random(min: CGFloat(9.0), max: CGFloat(10.0))
        var imgName = "spider"
        var enemyType = EnemyType.spider
        if currentWave == 4 {
            if bossSpawned {
                return
            }
            spawnBoss()
            return
        }
        if currentWave >= 2 {
            if enemiesToSpawn % 4 == 0 {
                hp = 6
                imgName = "roach"
                speed = random(min: CGFloat(16.0), max: CGFloat(22.0))
                fireDelay = 10
                enemyType = EnemyType.roach
            }
            if currentWave >= 3 {
                if enemiesToSpawn % 5 == 0 {
                    hp = 3
                    imgName = "beetle"
                    speed = random(min: CGFloat(14.0), max: CGFloat(20.0))
                    fireDelay = 8
                    enemyType = EnemyType.beetle
                }
            }
        }
        
        let bug = SKSpriteNode(imageNamed: imgName)
        
        bug.name = "enemy"
        
        let actualX = random(min: bug.size.width/2, max: size.width - bug.size.width/2)
        
        bug.position = CGPoint(x: actualX, y: size.height + bug.size.height/2)
        bug.zPosition = 3
        
        addChild(bug)
        
        bug.physicsBody = SKPhysicsBody(rectangleOf: bug.size)
        bug.physicsBody?.isDynamic = true
        bug.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        bug.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        bug.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        let enemy = Enemy(scene: self, node: bug, enemyType: enemyType, fireDelay: fireDelay, hp: hp)
        
        enemies.append(enemy)
        
        
        let actualDuration = speed
        let actionMove = SKAction.move(to: CGPoint(x: actualX, y: -bug.size.width/2),
                                       duration: TimeInterval(actualDuration))
        
        
        let actionMoveDone = SKAction.removeFromParent()
        bug.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func spawnBoss() {
        // boss music
        backgroundMusic.run(SKAction.stop())
        backgroundMusic = SKAudioNode(fileNamed: "Fast Ace.wav")
        backgroundMusic.run(SKAction.changeVolume(to: 1.5, duration: 0))
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        let bug = SKSpriteNode(imageNamed: "mantis0")
        
        bug.name = "enemy"
        
        bug.position = CGPoint(x: frame.width / 2, y: frame.height - (bug.size.height / 2))
        bug.zPosition = 3
        
        addChild(bug)
        
        let bossHitboxSize = CGSize(width: bug.size.width * 0.5, height: bug.size.height * 0.4)
        bug.physicsBody = SKPhysicsBody(rectangleOf: bossHitboxSize)
        bug.physicsBody?.isDynamic = true
        bug.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        bug.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        bug.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        let enemy = Enemy(scene: self, node: bug, enemyType: .boss, fireDelay: 1, hp: 100)
        
        enemies.append(enemy)
        
        let f0 = SKTexture.init(imageNamed: "mantis0")
        let f1 = SKTexture.init(imageNamed: "mantis1")
        let f2 = SKTexture.init(imageNamed: "mantis2")
        let frames: [SKTexture] = [f0, f1, f2]
        let animation = SKAction.repeatForever(SKAction.animate(with: frames, timePerFrame: 0.2))
        let moveLeft = SKAction.moveTo(x: size.width / 4, duration: 5)
        let moveRight = SKAction.moveTo(x: 3 * size.width / 4, duration: 5)
        let flip = SKAction.scaleX(by: -1, y: 1, duration: 0)
        let move = SKAction.repeatForever(SKAction.sequence([moveLeft, flip, moveRight, flip]))
        let bossActions = SKAction.group([animation, move])
        bug.run(bossActions)
        
        bossSpawned = true
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLoc = touch.location(in: self)
        let dist = distance(player.position, touchLoc)
        let playerActionMove = SKAction.move(to: touchLoc, duration: 0.002 * Double(dist))
        let touchOffset = CGPoint(x: touchLoc.x - 40, y: touchLoc.y - 40)
        let healthBarActionMove = SKAction.move(to: touchOffset, duration: 0.002 * Double(dist))
        player.run(playerActionMove)
        healthBarPos.run(healthBarActionMove)
        healthBarNeg.run(healthBarActionMove)
    }
    
    func enemyFireProjectile(enemy: SKSpriteNode, enemyType: EnemyType) {
        let projectile = SKSpriteNode(imageNamed: enemyProjectileTypes[enemyType] ?? "green_fireball")
        projectile.position = enemy.position
        projectile.zPosition = 2
        
        
        setEnemyProjPhysics(projectile)
        
        addChild(projectile)
        
        if enemyType == .spider || enemyType == .beetle {
            let dur = Double(enemy.position.y) / 200
            
            var actionMove = SKAction.move(to: CGPoint(x: enemy.position.x, y: -100), duration: dur)
        
            if enemyType == .spider {
                let dest = CGPoint(x: enemy.position.x - 100 + random(min: CGFloat(0), max: CGFloat(200)), y: -100)
                actionMove = SKAction.move(to: dest, duration: dur)
            }
            let actionRotate = SKAction.rotate(byAngle: 100, duration: dur)
            let actionMoveDone = SKAction.removeFromParent()
            let actionMoveAndRotate = SKAction.group([actionMove, actionRotate])
            projectile.run(SKAction.sequence([actionMoveAndRotate, actionMoveDone]))
        }
        if enemyType == .roach {
            let offset = player.position - projectile.position
            
            
            let direction = offset.normalized()
            
            let shootAmount = direction * 1000
            
            let realDest = shootAmount + projectile.position
            
            let actionMove = SKAction.move(to: realDest, duration: 5)
            let actionRotate = SKAction.rotate(byAngle: 100, duration: 5)
            let actionMoveDone = SKAction.removeFromParent()
            let actionMoveAndRotate = SKAction.group([actionMove, actionRotate])
            projectile.run(SKAction.sequence([actionMoveAndRotate, actionMoveDone]))
        }
        if enemyType == .beetle {
            let dist = CGFloat(1000)
            let offX = CGFloat(10)
            let offY = CGFloat(25)
            let proj1 = SKSpriteNode(imageNamed: enemyProjectileTypes[enemyType] ?? "green_fireball")
            proj1.position = enemy.position
            proj1.zPosition = 2
            setEnemyProjPhysics(proj1)
            
            addChild(proj1)
            
            let offset = enemy.position - CGPoint(x: enemy.position.x - offX, y: enemy.position.y - offY)
            
            let dest = (offset.normalized() * -dist) + enemy.position
            let actionMove = SKAction.move(to: dest, duration: 5)
            let actionRotate = SKAction.rotate(byAngle: 100, duration: 5)
            let actionMoveDone = SKAction.removeFromParent()
            let actionMoveAndRotate = SKAction.group([actionMove, actionRotate])
            proj1.run(SKAction.sequence([actionMoveAndRotate, actionMoveDone]))
            
            
            let proj2 = SKSpriteNode(imageNamed: enemyProjectileTypes[enemyType] ?? "green_fireball")
            proj2.position = enemy.position
            proj2.zPosition = 2
            setEnemyProjPhysics(proj2)
            
            addChild(proj2)
            
            let offset2 = enemy.position - CGPoint(x: enemy.position.x + offX, y: enemy.position.y - offY)
            
            let dest2 = (offset2.normalized() * -dist) + enemy.position
            let actionMove2 = SKAction.move(to: dest2, duration: 5)
            let actionRotate2 = SKAction.rotate(byAngle: 100, duration: 5)
            let actionMoveDone2 = SKAction.removeFromParent()
            let actionMoveAndRotate2 = SKAction.group([actionMove2, actionRotate2])
            proj2.run(SKAction.sequence([actionMoveAndRotate2, actionMoveDone2]))
        }
        if enemyType == .boss {
            if bossVolleyCooldown < 0 {
                if bossVolleyCooldown == -5 {
                    bossVolleyCooldown = Int.random(in: 0...30)
                } else {
                    projectile.removeFromParent()
                    bossVolleyCooldown -= 1
                    return
                }
            }
            if bossVolleyCooldown == 0 {
                bossVolleyCooldown -= 1
                projectile.removeFromParent()
                bossFireVolley(enemy.position)
                return
            }
            if bossVolleyCooldown < 2 {
                projectile.removeFromParent()
                bossVolleyCooldown -= 1
                return
            }
            bossVolleyCooldown -= 1
            let offset = player.position - projectile.position
            
            
            let direction = offset.normalized()
            
            let shootAmount = direction * 1000
            
            let realDest = shootAmount + projectile.position
            
            let actionMove = SKAction.move(to: realDest, duration: 5)
            let actionRotate = SKAction.rotate(byAngle: 100, duration: 5)
            let actionMoveDone = SKAction.removeFromParent()
            let actionMoveAndRotate = SKAction.group([actionMove, actionRotate])
            projectile.run(SKAction.sequence([actionMoveAndRotate, actionMoveDone]))
        }
    }
    
    func bossFireVolley(_ pos: CGPoint) {
        let dist = CGFloat(1000)
        var offX = -20
        let offY = CGFloat(25)
        
        while offX < 20 {
            offX += 5
            let proj = SKSpriteNode(imageNamed: "green_fireball")
            proj.position = pos
            proj.zPosition = 2
            setEnemyProjPhysics(proj)
        
            addChild(proj)
        
            let offset = pos - CGPoint(x: pos.x + CGFloat(offX), y: pos.y - offY)
        
            let dest = (offset.normalized() * -dist) + pos
            let actionMove = SKAction.move(to: dest, duration: 5)
            let actionRotate = SKAction.rotate(byAngle: 100, duration: 5)
            let actionMoveDone = SKAction.removeFromParent()
            let actionMoveAndRotate = SKAction.group([actionMove, actionRotate])
            proj.run(SKAction.sequence([actionMoveAndRotate, actionMoveDone]))
        }
    }
    
    func playerFireProjectile() {
        if oskiTimer > -1 {
            if oskiTimer < 7 {
                if oskiTimer % 2 == 0 {
                    player.run(SKAction.setTexture(SKTexture(imageNamed: "dan")))
                } else {
                    player.run(SKAction.setTexture(SKTexture(imageNamed: "oski")))
                }
            }
            oskiTimer -= 1
        }
        
        
        let projectile = SKSpriteNode(imageNamed: "clash2")
        projectile.position = player.position
        projectile.zPosition = 2
        
        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(projectile)
        
        let actionMove = SKAction.move(to: CGPoint(x: player.position.x, y: size.height + 100), duration: 1.3)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func createExplosion(location: CGPoint) {
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = location
        explosion.zPosition = 100
        addChild(explosion)
        
        let actionFade = SKAction.fadeOut(withDuration: 0.5)
        let actionRemove = SKAction.removeFromParent()
        explosion.run(SKAction.sequence([actionFade, actionRemove]))
    }
}
