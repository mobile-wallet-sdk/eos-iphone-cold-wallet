//
//  BleUuid.swift
//  EOS Cold Wallet
//
//  Created by Dieter Saken on 25.09.18.
//  Copyright © 2018 Dieter Saken. All rights reserved.
//

import Foundation
import CoreBluetooth

extension String {

    
    func cbuuid() -> CBUUID{
       return CBUUID(data: data())
    }
    
    func cbuuid(extend: String) -> CBUUID{
        let int64 = Int64(extend.hash)
        var data1 = data()

        for i in 0..<7 {
            data1[i+8] = UInt8((int64 >> i) & 0xff)
        }
        return CBUUID(data: data1)
    }
    
    private func data() -> Data {
        let int64 = Int64(hash)
        var data = Data(count: 16)
        for i in 0..<7 {
            data[i] = UInt8((int64 >> i) & 0xff)
        }
        return data
    }
}
