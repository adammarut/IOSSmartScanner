//
//  SettingsViewController.swift
//  Shop shelf scanner
//
//  Created by Adam Marut on 28/11/2022.
//

import UIKit

class SettingsViewController: UIViewController {

    

    
    @IBOutlet weak var secondsStepper: UIStepper!
    @IBOutlet weak var secondsLabel: UITextField!
    
    @IBOutlet weak var opacitySlider: UISlider!
    weak var delegate: SettingsDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        secondsStepper.minimumValue = 1
        secondsStepper.maximumValue = 120
        secondsLabel.text = String(Int(secondsStepper.value))
        let defaults = UserDefaults.standard
        var overlayOpacity: Float
        if  (defaults.object(forKey: "overlayOpacity") != nil){
             overlayOpacity = defaults.float(forKey: "overlayOpacity")
        }
        else{
            overlayOpacity = 0.5
        }
            opacitySlider.setValue(overlayOpacity, animated: true)
        // Do any additional setup after loading the view.
    }
    @IBAction func secondsChanged(_ sender: UIStepper) {
        print(secondsStepper.value)
        secondsLabel.text = String(Int(secondsStepper.value))
    }
    
    @IBAction func overlayOpacityChanged(_ sender: UISlider) {
        delegate?.opacityChanged(opacity:Double(sender.value))
        let defaults = UserDefaults.standard
        defaults.set(sender.value, forKey: "overlayOpacity")//Float:opacitySlider.value forKey:@"overlayOpacity"];
        let opacityDict:[String:Double] = ["opacity": Double(sender.value)]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "overlayOpacityChanged"), object: nil, userInfo: opacityDict)


    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


    }

protocol SettingsDelegate: AnyObject {
    func opacityChanged(opacity: Double)

}
