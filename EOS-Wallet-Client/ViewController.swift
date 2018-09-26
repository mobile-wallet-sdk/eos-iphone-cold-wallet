//
//  ViewController.swift
//  EOS-Wallet-Client
//

import Cocoa
import CommonCrypto

class ViewController: NSViewController, SimpleBluetoothIODelegate {
    @IBOutlet weak var from: NSTextField!
    @IBOutlet weak var to: NSTextField!
    @IBOutlet weak var amount: NSTextField!
    @IBOutlet weak var memo: NSTextField!

    var central : BleCentralRole!
    override func viewDidLoad() {
        super.viewDidLoad()
        central = BleCentralRole(delegate: self)
        self.from.stringValue = "disconnected"

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func disconnect(central: BleCentralRole) {
         self.from.stringValue = "disconnected"
    }
    
    func simpleBluetoothIO(central: BleCentralRole, didReceiveValue value: Data, channel: Channel) {
        if let text = String(data: value, encoding: .utf8) {
            switch(channel) {
            case .account:
                print("Owner: " + text)
                self.from.stringValue = text
                break;
            case .signature:
                print("Signature: " + text)
                break
            case .digest:
                print("Digest: " + text)
                break
            }
            
    
          
        }

    }
    
    @IBAction func onSign(view: NSView) {
        let transaction = ["from" : from.stringValue, "to": to.stringValue, "amount" :  amount.stringValue, "memo" :  memo.stringValue]
        
        let data = try! JSONSerialization.data(withJSONObject: transaction, options: .prettyPrinted)
        
        let digest = data.sha256
        
        central.writeValue(data: digest)
    }
}


extension Data {
    public var sha256: Data {
        let bytes = [UInt8](self)
        return Data(bytes.sha256)
    }
}

extension Array where Element == UInt8 {
    public var sha256: [UInt8] {
        let bytes = self
        
        let mutablePointer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        
        CC_SHA256(bytes, CC_LONG(bytes.count), mutablePointer)
        
        let mutableBufferPointer = UnsafeMutableBufferPointer<UInt8>.init(start: mutablePointer, count: Int(CC_SHA256_DIGEST_LENGTH))
        let sha256Data = Data(buffer: mutableBufferPointer)
        
        mutablePointer.deallocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        return[UInt8](sha256Data)
        
    }
}

