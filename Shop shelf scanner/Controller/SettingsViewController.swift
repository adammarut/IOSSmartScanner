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
    
    @IBOutlet weak var frequencyControl: UISegmentedControl!
    @IBOutlet weak var stitchingConfSlider: UISlider!
    @IBOutlet weak var stitchingConfTextBox: UITextField!
    @IBOutlet weak var opacitySlider: UISlider!
    weak var delegate: SettingsDelegate?
    @IBOutlet weak var isPanoramicSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard

        secondsStepper.minimumValue = 1
        secondsStepper.maximumValue = 120
        if  (defaults.object(forKey: "sensorsDuration") != nil){
            secondsStepper.value = defaults.double(forKey: "sensorsDuration")
        }
        else{
            secondsStepper.value = 3.0
        }
        secondsLabel.text = String(Int(secondsStepper.value))
        var overlayOpacity: Float
        if  (defaults.object(forKey: "overlayOpacity") != nil){
             overlayOpacity = defaults.float(forKey: "overlayOpacity")
        }
        else{
            overlayOpacity = 0.5
        }
        opacitySlider.setValue(overlayOpacity, animated: true)

        if  (defaults.object(forKey: "sensorsFrequencyIndex") != nil){
            frequencyControl.selectedSegmentIndex = defaults.integer(forKey: "sensorsFrequencyIndex")
        }
        else{
            frequencyControl.selectedSegmentIndex = 3
        }
        if  (defaults.object(forKey: "isPanoramic") != nil){
            isPanoramicSwitch.isOn = defaults.bool(forKey: "isPanoramic")
        }
        else{
            defaults.set(isPanoramicSwitch.isOn, forKey: "isPanoramic")
        }
        if  (defaults.object(forKey: "stitchingConf") != nil){
            stitchingConfSlider.value = defaults.float(forKey: "stitchingConf")
            self.stitchingConfidenceThreshChanged(stitchingConfSlider)
        }
        
    }
    
    @IBAction func stitchingConfidenceThreshChanged(_ sender: UISlider) {
        let stitchingConfidence = sender.value
        let stitchingConfidencePercent = Int(stitchingConfidence*100)
        self.stitchingConfTextBox.text = String(stitchingConfidencePercent) + " %"
        let defaults = UserDefaults.standard
        defaults.set(sender.value, forKey: "stitchingConf")
        let infoDict:[String:Float] = ["stitchingConf": Float(sender.value)]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stitchingConfChanged"), object: nil, userInfo: infoDict)
    }
    
    @IBAction func secondsChanged(_ sender: UIStepper) {
        print(secondsStepper.value)
        secondsLabel.text = String(Int(secondsStepper.value))
        let defaults = UserDefaults.standard
        defaults.set(sender.value, forKey: "sensorsDuration")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sensorsDurationChanged"), object: nil)
    }
    
    @IBAction func panoramicModeChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard

        defaults.set(sender.isOn, forKey: "isPanoramic")
        let panoDict:[String:Bool] = ["isPanoramic": Bool(sender.isOn)]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "panoramicStitchingChanged"), object: nil, userInfo: panoDict)

    }
    @IBAction func consecutiveStitchingChanged(_ sender: UISwitch) {
        let defaults = UserDefaults.standard

        defaults.set(sender.isOn, forKey: "isConsecutive")
        let consDict:[String:Bool] = ["consecutive": Bool(sender.isOn)]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "consecutiveStitchingChanged"), object: nil, userInfo: consDict)
    }
    @IBAction func overlayOpacityChanged(_ sender: UISlider) {
        delegate?.opacityChanged(opacity:Double(sender.value))
        let defaults = UserDefaults.standard
        defaults.set(sender.value, forKey: "overlayOpacity")
        let opacityDict:[String:Double] = ["opacity": Double(sender.value)]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "overlayOpacityChanged"), object: nil, userInfo: opacityDict)


    }
    
    @IBAction func frequencyChanged(_ sender: UISegmentedControl) {
        let defaults = UserDefaults.standard
        switch sender.selectedSegmentIndex {
        case 0:
            defaults.set(10.0, forKey: "sensorsFrequency")
            defaults.set(0, forKey: "sensorsFrequencyIndex")
        case 1:
            defaults.set(20.0, forKey: "sensorsFrequency")
            defaults.set(1, forKey: "sensorsFrequencyIndex")

        case 2:
            defaults.set(30.0, forKey: "sensorsFrequency")
            defaults.set(2, forKey: "sensorsFrequencyIndex")

        case 3:
            defaults.set(40.0, forKey: "sensorsFrequency")
            defaults.set(3, forKey: "sensorsFrequencyIndex")

        case 4:
            defaults.set(50.0, forKey: "sensorsFrequency")
            defaults.set(4, forKey: "sensorsFrequencyIndex")

        case 5:
            defaults.set(60.0, forKey: "sensorsFrequency")
            defaults.set(5, forKey: "sensorsFrequencyIndex")

        default:
            print("Frequency not choosen")
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "sensorsFrequencyChanged"), object: nil)

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
