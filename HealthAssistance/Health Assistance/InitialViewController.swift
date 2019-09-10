//
//  InitialViewController.swift
//  Health Assistance
//
//  Created by Seemo S on 2018-09-12.
//  Copyright © 2018 Daniella & Tasnim. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {

    //create timer for when the pet will 'blink'
    var blinkTimer: Timer!
    
    //create the animations for the images on screen
    var animation: CAKeyframeAnimation!
    var messageAnimation: CAKeyframeAnimation!
    
    //images from the screen
    @IBOutlet weak var petBodyImage: UIImageView!
    @IBOutlet weak var petEyesOpen: UIImageView!
    @IBOutlet weak var petEyesClosed: UIImageView!
    @IBOutlet weak var petMessageLabel: UILabel!
    @IBOutlet weak var petMessageBox: UIImageView!
    
    //create tap recognizers for the pet images
    let tapRecPetBody = UITapGestureRecognizer()
    let tapRecPetEyesOpen = UITapGestureRecognizer()
    let tapRecPetEyesClosed = UITapGestureRecognizer()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //create freeform path for message box
        let miniRecPath = UIBezierPath()
        miniRecPath.move(to: CGPoint(x: 200, y: 220))
        miniRecPath.addLine(to: CGPoint(x: 250, y: 220))
        miniRecPath.addLine(to: CGPoint(x: 250, y: 230))
        miniRecPath.addLine(to: CGPoint(x: 200, y: 230))
        miniRecPath.addLine(to: CGPoint(x: 200, y: 220))
        
        //set the freefrom path to the message animation
        messageAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        messageAnimation.duration = 5
        messageAnimation.repeatCount = MAXFLOAT
        messageAnimation.path = miniRecPath.cgPath
        
        //create circle path for the pet images
        let circlePath = UIBezierPath(arcCenter: view.center, radius: 80, startAngle: 0, endAngle: .pi*2, clockwise: true)
        
        //set the circle path to the pet animation
        animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        animation.duration = 8
        animation.repeatCount = MAXFLOAT
        animation.path = circlePath.cgPath
        
        //set the animations for the image layers
        petEyesClosed.layer.add(animation, forKey: nil)
        petEyesOpen.layer.add(animation, forKey: nil)
        petBodyImage.layer.add(animation, forKey: nil)
        petMessageLabel.layer.add(messageAnimation, forKey: nil)
        petMessageBox.layer.add(messageAnimation, forKey: nil)
        
    }
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true //added

        //hide the message box at first 
        self.petMessageLabel.isHidden = true
        self.petMessageBox.isHidden = true
        
        //set blink timer
        blinkTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(switchImage), userInfo: nil, repeats: true)
        
        //set user interactions to true for all images
        petBodyImage.isUserInteractionEnabled = true;
        petEyesOpen.isUserInteractionEnabled = true;
        petEyesClosed.isUserInteractionEnabled = true;
        
        //set the function for the tap gestures to call
        tapRecPetBody.addTarget(self, action: #selector(InitialViewController.tapImage))
        tapRecPetEyesOpen.addTarget(self, action: #selector(InitialViewController.tapImage))
        tapRecPetEyesClosed.addTarget(self, action: #selector(InitialViewController.tapImage))

        //give each pet image a tap gesture
        petEyesOpen.addGestureRecognizer(tapRecPetEyesOpen)
        petEyesClosed.addGestureRecognizer(tapRecPetEyesClosed)
        petBodyImage.addGestureRecognizer(tapRecPetBody)
        
        //moves the pet on screen, side to side, only shows on phone
        self.addParallaxToView(vw: petBodyImage)
        self.addParallaxToView(vw: petEyesOpen)
        self.addParallaxToView(vw: petEyesClosed)
        
    }
    
    //function to call to make image blink
    @objc func switchImage() {
        
        if (petEyesClosed.isHidden){
            petEyesClosed.isHidden = false
            petEyesOpen.isHidden = true
        } else {
            petEyesClosed.isHidden = true
            petEyesOpen.isHidden = false
            
        }
    }
    
    //creates the movement of the images when the phone is tilted
    func addParallaxToView(vw: UIView) {
        let amount = 100
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        blinkTimer.invalidate() //end timer when switching to another view controller
    }
    
    //called when images are tapped
    @objc func tapImage() {
        
        //make pet blink when image is tapped
        if (petEyesClosed.isHidden){
            petEyesClosed.isHidden = false
            petEyesOpen.isHidden = true
        } else {
            petEyesClosed.isHidden = true
            petEyesOpen.isHidden = false
        }
        
        //create pet label messages
        let welcomeMessages: NSMutableArray = NSMutableArray()
        welcomeMessages.add("Welcome Friend")
        welcomeMessages.add("Hello Friend")
        welcomeMessages.add("Happy to see you here")
        welcomeMessages.add("Hello :)")
        welcomeMessages.add("You are important")
        
        //chose label message randomly
        let ranNum = Int(arc4random_uniform(UInt32(welcomeMessages.count)))
        
        self.petMessageLabel.text = welcomeMessages[ranNum] as? String
        
        //set message bubble to visible
        self.petMessageLabel.isHidden = false
        self.petMessageBox.isHidden = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
             //set message bubble to invisible after 5 secs
            self.petMessageLabel.isHidden = true
            self.petMessageBox.isHidden = true
        }
    
    }

}

