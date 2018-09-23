import Foundation
import CoreBluetooth

let DEFAULT_NOTIFY_MTU = 20
let TRANSFER_SERVICE_UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD666661"
let WRITE_CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6F66666D4"
let READ_CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6F66666D5"


let transferServiceUUID = CBUUID(string: TRANSFER_SERVICE_UUID)
let writeCharacteristicUUID = CBUUID(string: WRITE_CHARACTERISTIC_UUID)
let readCharacteristicUUID = CBUUID(string: READ_CHARACTERISTIC_UUID)


protocol SimpleBluetoothIODelegate: class {
    func simpleBluetoothIO(peripheral: BlePeripheralRole, didReceiveValue value: Data)
}


class BlePeripheralRole: NSObject {
    weak var delegate: SimpleBluetoothIODelegate?
    
    var mtu = 20
    var peripheralManager: CBPeripheralManager!
    var data : Data!
    var chunks : [Data] = []
    var chunkIndex = 0
    
    var writeCharacteristic : CBMutableCharacteristic!
    var readCharacteristic : CBMutableCharacteristic!
    init( delegate: SimpleBluetoothIODelegate?) {
        self.delegate = delegate
        
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self,  queue: nil)
    }
    
    
    func writeValue(data: Data) {
        chunkIndex = 0;
        chunks = []
        self.data = data
            if(chunks.count == 0) {
                
                for i in stride(from: 0, to: data.count, by: mtu) {
                    let left = data.count - i
                    //let range = NSMakeRange(i, left > mtu ? mtu : left)
                    let end = (left > mtu ? mtu : left) - i
                    let chunk = data.subdata(in: i..<end)
                    chunks.append(chunk)
                }
                chunks.append(Data())
            }
        writeChunk()
    }
}

extension BlePeripheralRole: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            return
        }
        
        readCharacteristic = CBMutableCharacteristic(
            type: readCharacteristicUUID,
            properties: CBCharacteristicProperties.notify,
            value: nil,
            permissions: CBAttributePermissions.readable
        )
        
        writeCharacteristic = CBMutableCharacteristic(
            type: writeCharacteristicUUID,
            properties: CBCharacteristicProperties.write,
            value: nil,
            permissions: CBAttributePermissions.writeable
        )
        
        // Then the service
        let transferService = CBMutableService(
            type: transferServiceUUID,
            primary: true
        )
        
        // Add the characteristic to the service
        transferService.characteristics = [readCharacteristic!, writeCharacteristic!]
        
        // And add it to the peripheral manager
        peripheralManager!.add(transferService)
        
        peripheralManager!.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey : [transferServiceUUID]
            ])
        
        
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print ("peripheralManagerDidStartAdvertising")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Central didSubscribeTo characteristic \(characteristic.uuid.uuidString) len: \(central.maximumUpdateValueLength)")
        chunkIndex = 0;
        mtu = central.maximumUpdateValueLength

        writeChunk()
 
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic")
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("didReceiveWrite")
        for request in requests  {
            print("request: \(String(data: request.value!, encoding: .utf8) ?? "")")
            if delegate != nil {
                delegate!.simpleBluetoothIO(peripheral: self, didReceiveValue: request.value!)
            }

        }
        peripheralManager.respond(to: requests.first!, withResult: .success)
     
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("didReceiveRead")
        
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("peripheralManagerIsReady")
        writeChunk()
    }
    
    private func writeChunk() {

        if(chunkIndex < chunks.count) {
            print("\(chunkIndex): \(String(data:chunks[chunkIndex], encoding: .utf8) ?? "")")
            while peripheralManager.updateValue(chunks[chunkIndex], for: readCharacteristic, onSubscribedCentrals: nil) {
                chunkIndex += 1;
                if(chunkIndex == chunks.count) {
                    break
                }
            }
        }

    }
    
}




