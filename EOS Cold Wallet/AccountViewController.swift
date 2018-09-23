//
//  AccountViewController.swift
//  EOS Cold Wallet
//

import UIKit

class AccountViewController: UIViewController{

    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var pubKeyLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var transcationLabel: UILabel!

    var dataObject: String = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
  

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataLabel.text = dataObject
        AppDelegate.peripheral.delegate = self
        let data = dataObject.data(using: .utf8, allowLossyConversion: true)!
        AppDelegate.peripheral.writeValue(data: data)
    }

    @IBAction func share(view: UIView) {
        // [String(format: "%@\n%@", dataLabel.text, pubKeyLabel.text)]
        let vc = UIActivityViewController(activityItems: [dataLabel.text ?? "", pubKeyLabel.text ?? ""], applicationActivities: [])
          present(vc, animated: true)
     
    }
    

}

extension AccountViewController: SimpleBluetoothIODelegate {
    func simpleBluetoothIO(peripheral: BlePeripheralRole, didReceiveValue value: Data)  {
        if let text = String(data: value, encoding: .utf8) {
            print(text)
            transcationLabel.text = text;
        }
    }
    
}
