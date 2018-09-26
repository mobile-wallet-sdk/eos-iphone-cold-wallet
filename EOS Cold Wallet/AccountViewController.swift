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
    
    var account: String = ""
    let wallet : Wallet = TestWallet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataLabel.text = account
        AppDelegate.peripheral.delegate = self
        let data = account.data(using: .utf8, allowLossyConversion: true)!
        
        AppDelegate.peripheral.writeValue(channel: .account, data: data)
        
        wallet.getPublicKey(account:account) { publicKey in
            self.pubKeyLabel.text = publicKey
        }
        
        
    }
    
    @IBAction func share(view: UIView) {
        // [String(format: "%@\n%@", dataLabel.text, pubKeyLabel.text)]
        let vc = UIActivityViewController(activityItems: [dataLabel.text ?? "", pubKeyLabel.text ?? ""], applicationActivities: [])
        present(vc, animated: true)
        
    }
    
    
}

extension AccountViewController: SimpleBluetoothIODelegate {
    func simpleBluetoothIO(peripheral: BlePeripheralRole, didReceiveValue value: Data)  {
        let text = value.hexString
        print(text)
        transcationLabel.text = text;
        
        wallet.sign(data: value) { signature in
            print("Signature " + signature)
            peripheral.writeValue(channel: .signature, data: signature.data(using: .utf8)!)
            
        }
        
    }
    
}

extension Data {
    public var hexString: String {
        return self.map { return String(format: "%x", $0) }.joined()
    }
    
}
