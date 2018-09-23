//
//  ViewController.swift
//  EOS-Wallet-Client
//

import Cocoa

class ViewController: NSViewController, SimpleBluetoothIODelegate {
    @IBOutlet weak var from: NSTextField!
    @IBOutlet weak var to: NSTextField!
    @IBOutlet weak var amount: NSTextField!
    @IBOutlet weak var memo: NSTextField!

    var central : BleCentralRole!
    override func viewDidLoad() {
        super.viewDidLoad()
        central = BleCentralRole(delegate: self)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func simpleBluetoothIO(central: BleCentralRole, didReceiveValue value: Data) {
        if let text = String(data: value, encoding: .utf8) {
            print("Owner: " + text)
            self.from.stringValue = text
            onSign(view: self.view)
        }

    }
    
    @IBAction func onSign(view: NSView) {
        let transaction = ["from" : from.stringValue, "to": to.stringValue, "amount" :  amount.stringValue, "memo" :  memo.stringValue]
        
        let data = try! JSONSerialization.data(withJSONObject: transaction, options: .prettyPrinted)
        
        central.writeValue(data: data)
    }
}

