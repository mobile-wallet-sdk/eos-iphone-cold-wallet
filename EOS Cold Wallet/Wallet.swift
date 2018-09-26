//
//  Wallet.swift
//  EOS Cold Wallet
//

import Foundation


public protocol Wallet {
     func getAccounts(closure: @escaping (_ : [String]) -> Void)
     func getPublicKey(account: String, closure: @escaping (_ : String) -> Void)
     func sign(data: Data, closure: @escaping (_ : String) -> Void)
    
}

struct TestWallet: Wallet {
    func getAccounts(closure: @escaping ([String]) -> Void) {
        DispatchQueue.main.async {
            closure(["eosmobilesdk", "testwalletr1", "testwalletnr3"]);
        }
    }
    

    
    
    func getPublicKey(account: String, closure: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            closure("PUB_R1_6ngCQQk317Kegy6MFEsxBjdn2stdeTsRTtZ9F6PVfpMbvjy3vC")
        }
    }
    
    func sign(data: Data, closure: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            closure("SIG_R1_Kq8hC5cAxCaAqS1gG311LgkP5cEoG2y3wsfrtmVvrZZxgJ4pAmF2torUQCVxktRdh3hQUcaMjKHLMj26wTu73Q6DTZHJhK")
        }
    }
}
