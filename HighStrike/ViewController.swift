//
//  ViewController.swift
//  HighStrike
//
//  Created by Melinda Po and Deepa Krishnan on 11/18/15.
//  Copyright © 2015 Melinda Po and Deepa Krishnan. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation

class ViewController: UIViewController {
    
    //have all the properties at the top
    let motionManager = CMMotionManager()
    var velocity: Double = 0.0
    var player: AVAudioPlayer = AVAudioPlayer()
    
    var cuurentMaxAccelX : Double = 0.0
    var currentMaxAccelY : Double = 0.0
    var cuurentMaxAcceZ : Double = 0.0
    var prevroll: Double = 0.0
    
    //Notice that the slider is an OUTLET and not an action
    @IBOutlet weak var rollSlider: UISlider!{
        didSet{
            //turns the slider horizontal instead of its natural vertical
            rollSlider.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // we use this instead of viewDidLoad() because we don't want it to appear once
    override func viewWillAppear(animated: Bool) {
        rollSlider.minimumValue = -1.0
        rollSlider.maximumValue = 1.0
        
        if motionManager.deviceMotionAvailable {
            motionManager.startDeviceMotionUpdates()
            getAccelrationDataOnMotion()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if motionManager.deviceMotionAvailable {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    
    //Helper Function
    func roundToPlaces(value:Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }
    
   //Helper Function
    func updateSliderUsingRoll(acceleration: CMAcceleration) {
        let motion = motionManager.deviceMotion
        if motion != nil {
            let roll = motion!.attitude.roll * currentMaxAccelY
            
            //a callback that won't dispatch get_main_queue until we get 
            //a response from the user
            dispatch_async(dispatch_get_main_queue(), {
                var sliderValue = self.rollSlider.value
                
                if ( roll < self.prevroll ) {
                    sliderValue = sliderValue - 0.1;
                } else {
                    sliderValue = sliderValue + 0.1;
                }
                self.prevroll = roll
                self.rollSlider.setValue( sliderValue, animated: true )
            })
            
            currentMaxAccelY = acceleration.y
            velocity = sqrt( pow(acceleration.x, 2.0) + pow(acceleration.y, 2.0) + pow(acceleration.z, 2.0))
        } else {
            // Handles the nil case
        }
    }
    
    func getAccelrationDataOnMotion(){
        if motionManager.accelerometerAvailable{
            let queue = NSOperationQueue()
            motionManager.startAccelerometerUpdatesToQueue(queue, withHandler:
                {data, error in
                    
                    guard let data = data else{
                        return
                    }
                    dispatch_async(dispatch_get_main_queue(), {() -> Void in
                      
                        self.velocity = abs(data.acceleration.y)
                        
                        self.updateSliderUsingRoll(data.acceleration)
                    })
                    
                    // handle the error
                }
                
            )
        } else {
            print("Accelerometer is not available")
        }
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if event!.subtype == UIEventSubtype.MotionShake {
            let fileLocation = NSBundle.mainBundle().pathForResource("Metal", ofType: "mp3")
            do {
                player = try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: fileLocation!))
            } catch let error as NSError {
                // handle error
                print("The error is \(error)")
            }
            
            print(velocity)
            
            if velocity > 0.5 {
                velocity = 1.0
            }
            else {
                velocity = currentMaxAccelY
            }
            
            
            player.volume = Float(velocity)
            player.play()
            motionManager.stopDeviceMotionUpdates()
        }
        
        
    }

}

