////
////  BLEManager.swift
////  CadenceTest
////
////  Created by SeongKook on 7/31/24.
////
//
//import UIKit
//import CoreBluetooth
//
//protocol BLEManagerDelegate: AnyObject {
//    func didUpdateCadence(_ cadence: Double)
//    func didUpdateSpeed(_ speed: Double)
//    func didUpdateCalories(_ calories: Double)
//    func didDiscoverPeripheral(_ peripheral: CBPeripheral)
//}
//
//class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
//    var centralManager: CBCentralManager!
//    var connectedPeripheral: CBPeripheral?
//    
//    var cadenceCharacteristic: CBCharacteristic?
//    var speedCharacteristic: CBCharacteristic?
//    var caloriesCharacteristic: CBCharacteristic?
//    
//    weak var delegate: BLEManagerDelegate?
//    
//    override init() {
//        super.init()
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//    }
//    
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        switch central.state {
//        case .poweredOn:
//            centralManager.scanForPeripherals(withServices: nil, options: nil)
//        case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
//            print("BLE is not available: \(central.state.rawValue)")
//        @unknown default:
//            fatalError("A new state has been introduced that is not handled")
//        }
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        delegate?.didDiscoverPeripheral(peripheral)
//    }
//    
//    func connect(to peripheral: CBPeripheral) {
//        centralManager.stopScan()
//        connectedPeripheral = peripheral
//        peripheral.delegate = self
//        centralManager.connect(peripheral, options: nil)
//    }
//    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        peripheral.discoverServices(nil)
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        if let services = peripheral.services {
//            for service in services {
//                peripheral.discoverCharacteristics(nil, for: service)
//            }
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        if let characteristics = service.characteristics {
//            for characteristic in characteristics {
//                if characteristic.uuid == CBUUID(string: "YOUR_CADENCE_CHARACTERISTIC_UUID") {
//                    cadenceCharacteristic = characteristic
//                } else if characteristic.uuid == CBUUID(string: "YOUR_SPEED_CHARACTERISTIC_UUID") {
//                    speedCharacteristic = characteristic
//                } else if characteristic.uuid == CBUUID(string: "YOUR_CALORIES_CHARACTERISTIC_UUID") {
//                    caloriesCharacteristic = characteristic
//                }
//                
//                if let char = cadenceCharacteristic ?? speedCharacteristic ?? caloriesCharacteristic {
//                    peripheral.setNotifyValue(true, for: char)
//                }
//            }
//        }
//    }
//    
//    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        if let value = characteristic.value {
//            if characteristic == cadenceCharacteristic {
//                let cadence = parseCadenceData(value)
//                delegate?.didUpdateCadence(cadence)
//            } else if characteristic == speedCharacteristic {
//                let speed = parseSpeedData(value)
//                delegate?.didUpdateSpeed(speed)
//            } else if characteristic == caloriesCharacteristic {
//                let calories = parseCaloriesData(value)
//                delegate?.didUpdateCalories(calories)
//            }
//        }
//    }
//    
//    private func parseCadenceData(_ data: Data) -> Double {
//        // Parse cadence data from characteristic value
//        return 0.0 // Replace with actual parsing logic
//    }
//    
//    private func parseSpeedData(_ data: Data) -> Double {
//        // Parse speed data from characteristic value
//        return 0.0 // Replace with actual parsing logic
//    }
//    
//    private func parseCaloriesData(_ data: Data) -> Double {
//        // Parse calories data from characteristic value
//        return 0.0 // Replace with actual parsing logic
//    }
//}
