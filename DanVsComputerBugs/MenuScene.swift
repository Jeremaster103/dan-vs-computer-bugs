//
//  MenuScene.swift
//  DanVsComputerBugs
//
//  Created by Jeremy Millard on 5/1/19.
//  Copyright © 2019 Jeremy Millard. All rights reserved.
//

import Foundation
import SpriteKit

class MenuScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        
        backgroundColor = SKColor.white
        
        let logo = SKSpriteNode(imageNamed: "logo")
        logo.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(logo)
        
        let label = SKLabelNode(fontNamed: "STHeitiTC-Medium")
        label.position = CGPoint(x: size.width/2, y: size.height/4)
        label.fontColor = SKColor.black
        label.fontSize = 20
        label.text = "TOUCH ANYWHERE TO BEGIN"
        addChild(label)
        
        let seq = SKAction.sequence([SKAction.fadeAlpha(to: 0.4, duration: 0.7), SKAction.fadeAlpha(to: 1.0, duration: 0.7)])
        label.run(SKAction.repeatForever(seq))
        
        let music = SKAudioNode(fileNamed: "Androids.wav")
        music.autoplayLooped = true
        addChild(music)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let reveal = SKTransition.doorsOpenHorizontal(withDuration: 1.0)
        let gameScene = GameScene(size: self.size)
        view?.presentScene(gameScene, transition: reveal)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
