//
//  LoginViewController.swift
//  Shop shelf scanner
//
//  Created by Adam Marut on 28/11/2022.
//

import Foundation
import UIKit

class LoginViewController: UIViewController{
    @IBOutlet weak var emailTxtBox: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "MainWindowSegue", sender: self)
    }
}
