//
//  AddAccountViewController.swift
//  EOS Cold Wallet
//

import UIKit

class AddAccountViewController: UIViewController {
    @IBOutlet weak var accountTextField: UITextField!

    static var  aid = 0;
    override func viewDidLoad() {
        super.viewDidLoad()
        accountTextField.becomeFirstResponder()
    }

    @IBAction func dissmiss(view: UIView) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createAccunt(view: UIView) {
        if let nc = presentingViewController as? UINavigationController {
        if let pc = nc.viewControllers[0] as? PageViewController {
            AddAccountViewController.aid += 1
            pc.accounts.append(accountTextField.text!)
            pc.showAccounts()
        }
        }
        dismiss(animated: true, completion: nil)
    }

}
