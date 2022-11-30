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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        secondsStepper.minimumValue = 1
        secondsStepper.maximumValue = 120
        secondsLabel.text = String(Int(secondsStepper.value))

        // Do any additional setup after loading the view.
    }
    @IBAction func secondsChanged(_ sender: UIStepper) {
        print(secondsStepper.value)
        secondsLabel.text = String(Int(secondsStepper.value))

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
