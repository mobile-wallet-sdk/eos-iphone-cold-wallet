import Foundation
import CoreBluetooth

let NOTIFY_MTU = 20
let TRANSFER_SERVICE_UUID = "de.wallet-sdk.eos"
let WRITE_CHARACTERISTIC_UUID = "write"
let READ_CHARACTERISTIC_UUID = "read"


let transferServiceUUID = "de.wallet-sdk.eos".cbuuid()
let signatureCharacteristicUUID = TRANSFER_SERVICE_UUID.cbuuid(extend: Channel.signature.rawValue)
let accountCharacteristicUUID = TRANSFER_SERVICE_UUID.cbuuid(extend: Channel.account.rawValue )
let digestCharacteristicUUID = TRANSFER_SERVICE_UUID.cbuuid(extend: Channel.digest.rawValue)



protocol SimpleBluetoothIODelegate: class {
    func simpleBluetoothIO(central: BleCentralRole, didReceiveValue value: Data, channel: Channel)
    func disconnect(central: BleCentralRole)

}


class BleCentralRole: NSObject {
    weak var delegate: SimpleBluetoothIODelegate?
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetService: CBService?
    var digestCharacteristic: CBCharacteristic?

    var receivedData = Data()

    init(delegate: SimpleBluetoothIODelegate?) {
        self.delegate = delegate
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        print("account: " + accountCharacteristicUUID.uuidString)
        print("signature: " + signatureCharacteristicUUID.uuidString)
        print("digest: " + digestCharacteristicUUID.uuidString)

    }
    
    func writeValue(data: Data) {
        guard let peripheral = connectedPeripheral, let characteristic = digestCharacteristic else {
            return
        }
        print("write: " + getChannel(characteristic: characteristic).rawValue)

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
}

extension BleCentralRole: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        connectedPeripheral = peripheral
        
        if let connectedPeripheral = connectedPeripheral {
            connectedPeripheral.delegate = self
            centralManager.connect(connectedPeripheral, options: nil)
            print("connect")

        }
        centralManager.stopScan()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [transferServiceUUID], options: nil)
            print("scanForPeripherals")
        }
    }
}

extension BleCentralRole: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            if service.uuid == transferServiceUUID {
                print("didDiscoverServices \(service.uuid.uuidString)")

                targetService = service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        

    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("didModifyServices")
        delegate?.disconnect(central: self)
        centralManager.cancelPeripheralConnection(peripheral)
        centralManager.scanForPeripherals(withServices: [transferServiceUUID], options: nil)
        

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {
            print("didDiscoverCharacteristicsFor " + getChannel(characteristic: characteristic).rawValue)
            if Channel.digest == getChannel(characteristic: characteristic) {
                digestCharacteristic = characteristic
            }
            if characteristic.properties.contains(.notify) {
                print("subscribe: " + getChannel(characteristic: characteristic).rawValue)
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor: " + getChannel(characteristic: characteristic).rawValue)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard let data = characteristic.value, let delegate = delegate else {
            return
        }
        let channel = getChannel(characteristic: characteristic)
        print("didUpdateValue: " +  channel.rawValue)

        if(data.count > 0) {
            receivedData.append(data)
        } else {
            print("Message was:  \( String(data: receivedData, encoding: .utf8) ?? "") " )
            delegate.simpleBluetoothIO(central: self, didReceiveValue: receivedData, channel: channel)
            receivedData = Data()
        }


    }
    
    private func getChannel(characteristic: CBCharacteristic) -> Channel {
        let key =  characteristic.uuid.uuidString;
        var response : Channel = .account
        
        if key == accountCharacteristicUUID.uuidString {
            response = .account
        } else if key == signatureCharacteristicUUID.uuidString {
            response = .signature
        } else if key == digestCharacteristicUUID.uuidString {
            response = .digest
        }
        return response
    }
    

}





