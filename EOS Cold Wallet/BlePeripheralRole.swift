import Foundation
import CoreBluetooth

let DEFAULT_NOTIFY_MTU = 20
let TRANSFER_SERVICE_UUID = "de.wallet-sdk.eos"




let transferServiceUUID = "de.wallet-sdk.eos".cbuuid()
let accountCharacteristicUUID = TRANSFER_SERVICE_UUID.cbuuid(extend: Channel.account.rawValue)
let signatureCharacteristicUUID = TRANSFER_SERVICE_UUID.cbuuid(extend:Channel.signature.rawValue)
let digestCharacteristicUUID = TRANSFER_SERVICE_UUID.cbuuid(extend: Channel.digest.rawValue)


protocol SimpleBluetoothIODelegate: class {
    func simpleBluetoothIO(peripheral: BlePeripheralRole, didReceiveValue value: Data)
}


struct Chunk {
    var channel: Channel
    var data: Data
    init( channel: Channel, data: Data) {
        self.channel = channel
        self.data = data
    }
}

class BlePeripheralRole: NSObject {
    weak var delegate: SimpleBluetoothIODelegate?
    
    var mtu = 20
    var peripheralManager: CBPeripheralManager!
    var data : Data!
    var chunks : [Chunk] = []
    var chunkIndex = 0
    
    var accountCharacteristic  : CBMutableCharacteristic!
    var signatureCharacteristic : CBMutableCharacteristic!
    var digestCharacteristic : CBMutableCharacteristic!
    
    init( delegate: SimpleBluetoothIODelegate?) {
        self.delegate = delegate
        
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self,  queue: nil)
    }
    
    
    
    func writeValue(channel: Channel, data: Data) {
        chunkIndex = 0;
        chunks = []
        self.data = data
        if(chunks.count == 0) {
            
            for i in stride(from: 0, to: data.count, by: mtu) {
                let left = data.count - i
                //let range = NSMakeRange(i, left > mtu ? mtu : left)
                let end = (left > mtu ? mtu : left) - i
                let chunk = Chunk(channel: channel, data: data.subdata(in: i..<end))
                chunks.append(chunk)
            }
            chunks.append(Chunk(channel: channel, data: Data()))
        }
        writeChunk()
    }
}

extension BlePeripheralRole: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            return
        }
        accountCharacteristic = CBMutableCharacteristic(
            type: accountCharacteristicUUID,
            properties: .notify,
            value: nil,
            permissions: [.readable, .readEncryptionRequired]
        )
        
        signatureCharacteristic = CBMutableCharacteristic(
            type: signatureCharacteristicUUID,
            properties: .notify,
            value: nil,
            permissions: [.readable, .readEncryptionRequired]
        )
        
        digestCharacteristic = CBMutableCharacteristic(
            type: digestCharacteristicUUID,
            properties: CBCharacteristicProperties.write,
            value: nil,
            permissions: [.writeable, .writeEncryptionRequired]
        )
        
        
        
        // Then the service
        let transferService = CBMutableService(
            type: transferServiceUUID,
            primary: true
        )
        
        // Add the characteristic to the service
        transferService.characteristics = [accountCharacteristic!, signatureCharacteristic!, digestCharacteristic!]
        
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
        print("Central didSubscribeTo characteristic: " + getChannel(characteristic: characteristic).rawValue)
        chunkIndex = 0;
        mtu = central.maximumUpdateValueLength
        if characteristic.uuid.uuidString == accountCharacteristic.uuid.uuidString {
            writeChunk()
        } 
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic: " + getChannel(characteristic: characteristic).rawValue)
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
            if  let characteristic = chunks[chunkIndex].channel == .signature ? signatureCharacteristic : accountCharacteristic {
                while peripheralManager.updateValue(chunks[chunkIndex].data, for: characteristic, onSubscribedCentrals: nil) {
                    chunkIndex += 1;
                    if(chunkIndex == chunks.count) {
                        break
                    }
                    print(chunks[chunkIndex].channel.rawValue + ": Chunk \(chunkIndex): \(String(data:chunks[chunkIndex].data, encoding: .utf8) ?? "")")
                }
            }
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




