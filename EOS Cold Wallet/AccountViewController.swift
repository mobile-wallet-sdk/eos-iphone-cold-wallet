//
//  AccountViewController.swift
//  EOS Cold Wallet
//

import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var pubKeyLabel: UILabel!
    
    var dataObject: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataLabel.text = dataObject
    }

    @IBAction func share(view: UIView) {
        // [String(format: "%@\n%@", dataLabel.text, pubKeyLabel.text)]
        let vc = UIActivityViewController(activityItems: [dataLabel.text ?? "", pubKeyLabel.text ?? ""], applicationActivities: [])
          present(vc, animated: true)
     
    }
    

}
