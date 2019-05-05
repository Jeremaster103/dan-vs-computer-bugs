import Foundation
import SpriteKit

class Enemy {
    var scene: GameScene
    var node: SKSpriteNode
    var enemyType = EnemyType.spider
    var maxTicksUntilFire = 6
    var ticksUntilFire = 6
    var hp = 1
  
  
    init (scene: GameScene, node: SKSpriteNode) {
        self.scene = scene
        self.node = node
    }
    
    init (scene: GameScene, node: SKSpriteNode, enemyType: EnemyType, fireDelay: Int, hp: Int) {
        self.scene = scene
        self.node = node
        self.maxTicksUntilFire = fireDelay
        self.hp = hp
        self.enemyType = enemyType
    }
  
    func tick() -> Bool {
        if node.parent == nil {
            return false
        }
        if ticksUntilFire == 0 {
            scene.enemyFireProjectile(enemy: node, enemyType: enemyType)
            ticksUntilFire = maxTicksUntilFire
        } else {
            ticksUntilFire -= 1
        }
    
        return true
    }
}

enum EnemyType {
    case spider
    case roach
    case beetle
    case boss
}
