import Foundation
import CoreBluetooth

let NOTIFY_MTU = 20
let TRANSFER_SERVICE_UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD666661"
let WRITE_CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6F66666D4"
let READ_CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6F66666D5"

let transferServiceUUID = CBUUID(string: TRANSFER_SERVICE_UUID)
let writeCharacteristicUUID = CBUUID(string: WRITE_CHARACTERISTIC_UUID)
let readCharacteristicUUID = CBUUID(string: READ_CHARACTERISTIC_UUID)

protocol SimpleBluetoothIODelegate: class {
    func simpleBluetoothIO(central: BleCentralRole, didReceiveValue value: Data)
}


class BleCentralRole: NSObject {
    weak var delegate: SimpleBluetoothIODelegate?
    
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetService: CBService?
    var writableCharacteristic: CBCharacteristic?
    var readableCharacteristic: CBCharacteristic?
    var receivedData = Data()

    init(delegate: SimpleBluetoothIODelegate?) {
        self.delegate = delegate
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func writeValue(data: Data) {
        guard let peripheral = connectedPeripheral, let characteristic = writableCharacteristic else {
            return
        }
        
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
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        print("didDiscoverCharacteristicsFor")

        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
                print("writableCharacteristic: \(characteristic.uuid.uuidString)")

            } else if characteristic.properties.contains(.notify) {
                print("readableCharacteristic \(characteristic.uuid)")
                readableCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValue")

        guard let data = characteristic.value, let delegate = delegate else {
            return
        }
        // print("didUpdateValueFor \(characteristic.uuid.uuidString): \( String(data: data, encoding: .utf8) ?? "")" )

        if(data.count > 0) {
            receivedData.append(data)
        } else {
            print("Message was:  \( String(data: receivedData, encoding: .utf8) ?? "")" )
            // let max = peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse)
            //let ok = Data(bytes: String(format: "OK %d", max).bytes)
            delegate.simpleBluetoothIO(central: self, didReceiveValue: receivedData)
            receivedData = Data()
            //peripheral.writeValue(ok, for: writableCharacteristic!, type: .withResponse)
        }


    }
    

}





