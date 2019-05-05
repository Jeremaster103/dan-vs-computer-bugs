//
//  GameOverScene.swift
//  DanVsComputerBugs
//
//  Created by Jeremy Millard on 4/16/19.
//  Copyright © 2019 Jeremy Millard. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    init(size: CGSize, won:Bool) {
        super.init(size: size)
        
        backgroundColor = SKColor.white
        
        let message = won ? "Victory!" : "Defeat."
        let img = won ? "dan_win" : "dan_sad"
        let c = won ? CGFloat(1.5) : CGFloat(1)
        
        let dan = SKSpriteNode(imageNamed: img)
        dan.position = CGPoint(x: size.width / 2, y: size.height / 4)
        dan.zPosition = 1
        addChild(dan)
        
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.zPosition = 2
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: c * size.height/2)
        addChild(label)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 9.0),
            SKAction.run() { [weak self] in
                guard let `self` = self else { return }
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = MenuScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
