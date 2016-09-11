//
//  GameScene.swift
//  SpriteKitIntro
//
//  Created by Kevin Li on 6/18/16.
//  Copyright (c) 2016 Kevin Li. All rights reserved.
//

import SpriteKit
import AVFoundation

struct Physics {
    static let Ghost: UInt32 = 0x1 << 1
    static let Ground: UInt32 = 0x1 << 2
    static let Wall: UInt32 = 0x1 << 3
    static let Score: UInt32 = 0x1 << 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var Ground = SKSpriteNode()
    var Ghost = SKSpriteNode()
    
    var wallPair = SKNode()
    
    var moveAndRemove = SKAction()
    
    var gameStarted = Bool()
    
    var score = Int()
    let scoreLabel = SKLabelNode()
    
    var highScore = Int()
    let highScoreLabel = SKLabelNode()
    
    var died = Bool()
    
    var restartButton = SKSpriteNode()
    
    var jumpSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Jump", ofType: "mp3")!)
    var jumpAudioPlayer = AVAudioPlayer()
    
    var hitSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Hit", ofType: "mp3")!)
    var hitAudioPlayer = AVAudioPlayer()
    
    var coinSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Coin", ofType: "wav")!)
    var coinAudioPlayer = AVAudioPlayer()
    
    func restartScene() {
        
        self.removeAllActions()
        self.removeAllChildren()
        died = false
        gameStarted = false
        score = 0
        createScene()
        
    }
    
    func createScene() {
        self.physicsWorld.contactDelegate = self
        
        for image in 0..<2 {
            let background = SKSpriteNode(imageNamed: "Background")
            background.anchorPoint = CGPointZero
            background.position = CGPointMake(CGFloat(image) * self.frame.width, 0)
            background.name = "background"
            background.size = (self.view?.bounds.size)!
            self.addChild(background)
        }
        
        scoreLabel.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2 + self.frame.height / 2.5)
        scoreLabel.text = "\(score)"
        scoreLabel.fontName = "04b_19"
        scoreLabel.zPosition = 4
        scoreLabel.fontSize = 60
        
        self.addChild(scoreLabel)
        
        
        highScoreLabel.position = CGPoint(x: self.frame.width / 7, y: self.frame.height / 2 + self.frame.height / 2.4)
        highScoreLabel.text = "\(highScore)"
        highScoreLabel.fontName = "04b_19"
        highScoreLabel.zPosition = 4
        highScoreLabel.fontSize = 25
        
        self.addChild(highScoreLabel)
        
        
        var highScoreDefault = NSUserDefaults.standardUserDefaults()
        
        if (highScoreDefault.valueForKey("High Score") != nil) {
            highScore = highScoreDefault.valueForKey("High Score") as! NSInteger
            highScoreLabel.text = NSString(format: "HS: %i", highScore) as String
        }
        
        
        Ground = SKSpriteNode(imageNamed: "Ground")
        Ground.setScale(0.5)
        Ground.position = CGPoint(x: self.frame.width / 2, y: 0 + Ground.frame.height/2)
        
        Ground.physicsBody = SKPhysicsBody(rectangleOfSize: Ground.size)
        Ground.physicsBody?.categoryBitMask = Physics.Ground
        Ground.physicsBody?.collisionBitMask = Physics.Ghost
        Ground.physicsBody?.contactTestBitMask = Physics.Ghost
        Ground.physicsBody?.affectedByGravity = false
        Ground.physicsBody?.dynamic = false
        
        Ground.zPosition = 3
        
        self.addChild(Ground)
        
        
        Ghost = SKSpriteNode(imageNamed: "Ghost")
        Ghost.size = CGSize(width: 60, height: 70)
        Ghost.position = CGPoint(x: self.frame.width / 2 - Ghost.frame.width, y: self.frame.height/2)
        
        Ghost.physicsBody = SKPhysicsBody(circleOfRadius: Ghost.frame.height / 2)
        Ghost.physicsBody?.categoryBitMask = Physics.Ghost
        Ghost.physicsBody?.collisionBitMask = Physics.Ground | Physics.Wall
        Ghost.physicsBody?.contactTestBitMask = Physics.Ground | Physics.Wall | Physics.Score
        Ghost.physicsBody?.affectedByGravity = false
        Ghost.physicsBody?.dynamic = true
        
        Ghost.zPosition = 2
        
        self.addChild(Ghost)
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        jumpAudioPlayer = try! AVAudioPlayer(contentsOfURL: jumpSound, fileTypeHint: nil)
        hitAudioPlayer = try! AVAudioPlayer(contentsOfURL: hitSound, fileTypeHint: nil)
        coinAudioPlayer = try! AVAudioPlayer(contentsOfURL: coinSound, fileTypeHint: nil)
        
        createScene()
        
    }
    
    func createButton() {
        restartButton = SKSpriteNode(imageNamed: "RestartBtn")
        restartButton.size = CGSizeMake(200, 100)
        restartButton.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        restartButton.zPosition = 5
        restartButton.setScale(0.0)
        self.addChild(restartButton)
        
        restartButton.runAction(SKAction.scaleTo(1.0, duration: 0.3))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if firstBody.categoryBitMask == Physics.Ghost && secondBody.categoryBitMask == Physics.Score || firstBody.categoryBitMask == Physics.Score && secondBody.categoryBitMask == Physics.Ghost {
            
            coinAudioPlayer.play()
            
            score += 1
            scoreLabel.text = "\(score)"
            
            if (score > highScore) {
                highScore = score
                highScoreLabel.text = "HS: \(highScore)"
                
                var highScoreDefault = NSUserDefaults.standardUserDefaults()
                highScoreDefault.setValue(highScore, forKey: "High Score")
                highScoreDefault.synchronize()
            }
        }
        
        if firstBody.categoryBitMask == Physics.Ghost && secondBody.categoryBitMask == Physics.Wall || firstBody.categoryBitMask == Physics.Wall && secondBody.categoryBitMask == Physics.Ghost {
            
            hitAudioPlayer.play()
            
            if died == false {
                died = true
                createButton()
            }
            
            enumerateChildNodesWithName("wallPair", usingBlock: ({
                (node, error) in
                
                node.speed = 0
                self.removeAllActions()
                
            }))
            
        }
        
        if firstBody.categoryBitMask == Physics.Ghost && secondBody.categoryBitMask == Physics.Ground || firstBody.categoryBitMask == Physics.Ground && secondBody.categoryBitMask == Physics.Ghost {
            
            hitAudioPlayer.play()
            
            if died == false {
                died = true
                createButton()
            }
            
            enumerateChildNodesWithName("wallPair", usingBlock: ({
                (node, error) in
                
                node.speed = 0
                self.removeAllActions()
                
            }))
            
        }
        
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        
        if gameStarted == false {
            
            gameStarted = true
            
            Ghost.physicsBody?.affectedByGravity = true
            
            let spawn = SKAction.runBlock({
                () in
                
                self.createWalls()
            })
            
            let delay = SKAction.waitForDuration(2.0)
            let SpawnDelay = SKAction.sequence([spawn, delay])
            let SpawnDelayForever = SKAction.repeatActionForever(SpawnDelay)
            self.runAction(SpawnDelayForever)
            
            let distance = CGFloat(self.frame.width + wallPair.frame.width)
            let movePipes = SKAction.moveByX(-distance - 50, y: 0, duration: NSTimeInterval(0.008*distance))
            let removePipes = SKAction.removeFromParent()
            moveAndRemove = SKAction.sequence([movePipes, removePipes])
            
            Ghost.physicsBody?.velocity = CGVectorMake(0, 0)
            Ghost.physicsBody?.applyImpulse(CGVectorMake(0, 60))
            
            jumpAudioPlayer.stop()
            jumpAudioPlayer.currentTime = 0
            jumpAudioPlayer.play()
        }
        
        else {
            if died == true {
                
            }
            else {
                
                Ghost.physicsBody?.velocity = CGVectorMake(0, 0)
                Ghost.physicsBody?.applyImpulse(CGVectorMake(0, 90))
                
                jumpAudioPlayer.stop()
                jumpAudioPlayer.currentTime = 0
                jumpAudioPlayer.play()
            }
        }
        
        for touch in touches {
            let location = touch.locationInNode(self)
            if died == true {
                if restartButton.containsPoint(location) {
                    restartScene()
                }
            }
        }
        
    }
    
    func createWalls() {
        
        let scoreNode = SKSpriteNode()
        
        scoreNode.size = CGSize(width: 1, height: 200)
        scoreNode.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.dynamic = false
        scoreNode.physicsBody?.categoryBitMask = Physics.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = Physics.Ghost
        
        
        wallPair = SKNode()
        wallPair.name = "wallPair"
        
        let topWall = SKSpriteNode(imageNamed: "Wall")
        let bottomWall = SKSpriteNode(imageNamed: "Wall")
        
        topWall.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 + 350)
        bottomWall.position = CGPoint(x: self.frame.width + 25, y: self.frame.height / 2 - 350)
        
        topWall.setScale(0.5)
        bottomWall.setScale(0.5)
        
        
        topWall.physicsBody = SKPhysicsBody(rectangleOfSize: topWall.size)
        topWall.physicsBody?.categoryBitMask = Physics.Wall
        topWall.physicsBody?.collisionBitMask = Physics.Ghost
        topWall.physicsBody?.contactTestBitMask = Physics.Ghost
        topWall.physicsBody?.affectedByGravity = false
        topWall.physicsBody?.dynamic = false
        
        bottomWall.physicsBody = SKPhysicsBody(rectangleOfSize: bottomWall.size)
        bottomWall.physicsBody?.categoryBitMask = Physics.Wall
        bottomWall.physicsBody?.collisionBitMask = Physics.Ghost
        bottomWall.physicsBody?.contactTestBitMask = Physics.Ghost
        bottomWall.physicsBody?.affectedByGravity = false
        bottomWall.physicsBody?.dynamic = false
        
        topWall.zRotation = CGFloat(M_PI)
        
        wallPair.addChild(topWall)
        wallPair.addChild(bottomWall)
        
        wallPair.zPosition = 1
        
        let randomPosition : CGFloat = CGFloat(arc4random_uniform(UInt32(300))) - 150
        wallPair.position.y = wallPair.position.y + randomPosition
        
        wallPair.addChild(scoreNode)
        
        wallPair.runAction(moveAndRemove)
        
        self.addChild(wallPair)
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        
        if gameStarted == true {
            if died == false {
                enumerateChildNodesWithName("background", usingBlock: ({
                    (node, error) in
                    
                    let bg = node as! SKSpriteNode
                    
                    bg.position = CGPoint(x: bg.position.x - 3, y: bg.position.y)
                    
                    if bg.position.x <= -bg.size.width {
                        bg.position = CGPointMake(bg.position.x + 2 * bg.frame.width, bg.position.y)
                    }
                    
                }))
            }
        }
        
        
    }
}
