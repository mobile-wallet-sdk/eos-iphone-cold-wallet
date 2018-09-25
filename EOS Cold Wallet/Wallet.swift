//
//  Wallet.swift
//  EOS Cold Wallet
//
//  Created by Dieter Saken on 25.09.18.
//  Copyright © 2018 Dieter Saken. All rights reserved.
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
            closure("PUB_R1_blablabla")
        }
    }
    
    func sign(data: Data, closure: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            closure("SIG_R1_blablabla")
        }
    }
}
