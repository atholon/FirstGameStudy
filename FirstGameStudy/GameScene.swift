//
//  GameScene.swift
//  FirstGameStudy
//
//  Created by 馮林 on 2018/2/24.
//  Copyright © 2018年 馮林. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    private var monsters:NSMutableArray
    private var projectiles:NSMutableArray
    private var projectileSoundEffectAction:SKAction
    private let bgMusicPlayer:AVAudioPlayer
    
    override init(size: CGSize) {
        monsters = NSMutableArray()
        projectiles = NSMutableArray()
        projectileSoundEffectAction = SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false)
        let bgMusicURL =  Bundle.main.url(forResource: "background-music-aac", withExtension: "caf")!
        try! bgMusicPlayer = AVAudioPlayer (contentsOf: bgMusicURL)
        super.init(size: size)
        
        bgMusicPlayer.numberOfLoops = -1
        bgMusicPlayer.play()
        self.backgroundColor = SKColor(red: 1, green: 1, blue: 1, alpha: 1)
        let player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x:player.size.width/2, y:size.height/2)
        self.addChild(player)
        
        let actionAddMonster = SKAction.run{
            self.addMonster()
        }
        let actionWaitNextMonster = SKAction.wait(forDuration: 1)
        self.run(SKAction.repeatForever(SKAction.sequence([actionAddMonster,actionWaitNextMonster])))
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addMonster(){
        let monster = SKSpriteNode(imageNamed: "monster")
        let winSize = self.size
        let minY = (monster.size.height) / 2
        let maxY = winSize.height - (monster.size.height)/2
        let rangeY = maxY - minY;
        let actualY = (arc4random() % UInt32(rangeY)) + UInt32(minY)
        
        //2 Create the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x:winSize.width + monster.size.width/2, y:CGFloat(actualY))
        self.addChild(monster)
        monsters.add(monster)
        
        //3 Determine speed of the monster
        let minDuration = 2.0
        let maxDuration = 4.0
        let rangeDuration = maxDuration - minDuration;
        let actualDuration = Double(arc4random() % UInt32(rangeDuration * 100)) / 100 + minDuration
        
        //4 Create the actions. Move monster sprite across the screen and remove it from scene after finished.
        let actionMove = SKAction.move(to:CGPoint(x:-monster.size.width/2, y:CGFloat(actualY)),
            duration:actualDuration)
        let actionMoveDone = SKAction.run {
            monster.removeFromParent()
            self.monsters.removeObject(identicalTo: monster)
        }
        monster.run(SKAction.sequence([actionMove,actionMoveDone]))
    }
    
    override func update(_ currentTime: TimeInterval){
        /* Called before each frame is rendered */
        let projectilesToDelete = NSMutableArray()
        for projectile in self.projectiles{
            
            let monstersToDelete = NSMutableArray()
            for monster in self.monsters {
                
                if (monster as! SKSpriteNode).frame.intersects((projectile as! SKSpriteNode).frame) {
                    monstersToDelete.add(monster)
                }
            }
            
            for monster in monstersToDelete {
                self.monsters.removeObject(identicalTo: monster)
                (monster as! SKSpriteNode).removeFromParent()
            }
            
            if monstersToDelete.count > 0 {
                projectilesToDelete.add(projectile)
            }
        }
        
        for projectile in projectilesToDelete {
            self.projectiles.removeObject(identicalTo: projectile)
            (projectile as! SKSpriteNode).removeFromParent()
        }
    }
    
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//
//        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
        for touch in touches {
            //1 Set up initial location of projectile
            let winSize = self.size
            let projectile = SKSpriteNode(imageNamed: "projectile.png")
            projectile.position = CGPoint(x:projectile.size.width/2, y:winSize.height/2)
            
            //2 Get the touch location tn the scene and calculate offset
            let location = touch.location(in: self)
            let offset = CGPoint(x:location.x - projectile.position.x, y:location.y - projectile.position.y)
            
            // Bail out if you are shooting down or backwards
            if (offset.x <= 0) {
                return
            }
            // Ok to add now - we've double checked position
            self.addChild(projectile)
            projectiles.add(projectile)
            
            let realX = winSize.width + (projectile.size.width/2)
            let ratio = offset.y / offset.x
            let realY = (realX * ratio) + projectile.position.y
            let realDest = CGPoint(x:realX, y:realY)
            
            //3 Determine the length of how far you're shooting
            let offRealX = realX - projectile.position.x
            let offRealY = realY - projectile.position.y
            let length = sqrtf(Float((offRealX * offRealX) + (offRealY * offRealY)))
            let velocity = self.size.width / 1  // projectile speed.
            let realMoveDuration = length / Float(velocity)
            
            //4 Move projectile to actual endpoint
            let moveAction = SKAction.move(to: realDest, duration: TimeInterval(realMoveDuration))
            let projectileCastAction = SKAction.group([moveAction,projectileSoundEffectAction])
            projectile.run(projectileCastAction, completion: {
                projectile.removeFromParent()
                self.projectiles.removeObject(identicalTo: projectile)
            })
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    

}
