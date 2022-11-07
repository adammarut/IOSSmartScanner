//
//  ShelfScanner.swift
//  Shop shelf scanner
//
//  Created by Adam Marut on 25/10/2022.
//

import Foundation
import CoreMotion
import UIKit
import CryptoKit
import CoreBluetooth

class AccelerometerHandler: NSObject{
    var manager = CMMotionManager()
    let recorder = CMSensorRecorder()
    let updateInterval: Double
    var accelData: [XYZValue] = []
    var gyroData: [XYZValue] = []
    var magnetometerData: [XYZValue] = []
    var attitudeData: [EulerValue] = []
    var startDate: Date?
    var queue = OperationQueue()
    var rawPhotoData: String?
    let device = UIDevice()
    var centralManager: CBCentralManager?
    var bleDevices = Array<CBPeripheral>()
    var bleDevicesData: [BleDevice] = []
    
    init(manager: CMMotionManager = CMMotionManager(), updateInterval: Double) {
        self.manager = manager
        self.updateInterval = updateInterval
    }
    struct PackedData:Codable{
        let sensors_data: SensorsData
        let image: String
        let UUID: String?
        let ble_devices: [BleDevice]
    }
    struct SensorsData: Codable{
        let acc_data: [XYZValue]
        let gyro_data: [XYZValue]
        let mag_data: [XYZValue]
        let att_data: [EulerValue]
    }
    
    struct BleDevice:Codable{
        let name:String
        let rssi: Int
    }
    struct EulerValue:Codable{
        let pitch:Double
        let roll:Double
        let yaw:Double
        let heading:Double
    }
    
    
    struct XYZValue:Codable{
        let x:Double
        let y:Double
        let z:Double
    }
    
    
    
    func startRecordingSensorsData(){
        self.getBLEDevices()
        
        //Get accelerometer data
        if manager.isAccelerometerAvailable{
            self.manager.accelerometerUpdateInterval = self.updateInterval
            self.manager.startAccelerometerUpdates(to: self.queue, withHandler: {(data,error) in
                if let validData = data{
                    let x = validData.acceleration.x
                    let y = validData.acceleration.y
                    let z = validData.acceleration.z
                    self.accelData.append(XYZValue(x: x,
                                                   y: y,
                                                   z: z))
                }
            })
        }
        //Get gyro data
        if manager.isGyroAvailable{
            self.manager.gyroUpdateInterval = self.updateInterval
            self.manager.startGyroUpdates(to: self.queue, withHandler: {(data,error) in
                if let validData = data{
                    let x = validData.rotationRate.x
                    let y = validData.rotationRate.y
                    let z = validData.rotationRate.z
                    self.gyroData.append(XYZValue(x: x,
                                                  y: y,
                                                  z: z))
                    
                }
            })
        }
        
        //Get magnetometer data
        if manager.isMagnetometerAvailable{
            self.manager.magnetometerUpdateInterval = self.updateInterval
            self.manager.startMagnetometerUpdates(to: self.queue, withHandler: {(data,error) in
                if let validData = data{
                    let x = validData.magneticField.x
                    let y = validData.magneticField.y
                    let z = validData.magneticField.z
                    self.magnetometerData.append(XYZValue(x: x,
                                                          y: y,
                                                          z: z))
                }
            })
            
        }
        
        //Get attitude data
        if manager.isDeviceMotionAvailable {
            self.manager.deviceMotionUpdateInterval = self.updateInterval
            self.manager.showsDeviceMovementDisplay = true
            self.manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                                  to: self.queue, withHandler: { (data, error) in
                // Make sure the data is valid before accessing it.
                if let validData = data {
                    // Get the attitude relative to the magnetic north reference frame.
                    let roll = validData.attitude.roll
                    let pitch = validData.attitude.pitch
                    let yaw = validData.attitude.yaw
                    let heading = validData.heading
                    self.attitudeData.append(EulerValue(pitch: pitch,
                                                        roll: roll,
                                                        yaw: yaw,
                                                        heading: heading))
                    
                }
            })
        }
    }
    
    func getBLEDevices(){
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func stopRecordingSensorData() -> String
    {
        self.manager.stopGyroUpdates()
        self.manager.stopMagnetometerUpdates()
        self.manager.stopAccelerometerUpdates()
        self.manager.stopDeviceMotionUpdates()
        self.centralManager?.stopScan()
        print("Finished with \(self.accelData.count) telemetry records.")
        
        return self.getJsonData()
    }
    func addRawData(rawData:String)
    {
        self.rawPhotoData = rawData
    }
    func getJsonData()-> String
    {
        let sensorsData = SensorsData(acc_data: self.accelData, gyro_data: self.gyroData, mag_data: self.magnetometerData, att_data: self.attitudeData)
        let allData = PackedData(sensors_data: sensorsData, image: self.rawPhotoData!, UUID: device.identifierForVendor?.uuidString, ble_devices: self.bleDevicesData)
        let encoder = JSONEncoder()
        let stringJSON = try! encoder.encode(allData)
        return  String(data:stringJSON, encoding: .utf8)!
    }
}
extension AccelerometerHandler: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.bleDevices.append(peripheral)
        
        if let name = peripheral.name{
            if self.bleDevicesData.isEmpty{
                self.bleDevicesData.append(BleDevice(name: name, rssi: Int(truncating: RSSI)))
            }
            else{
                var exist = false
                for device in self.bleDevicesData{
                    if device.name == name
                    {
                        exist = true
                    }
                }
                if !exist{
                    self.bleDevicesData.append(BleDevice(name: name, rssi: Int(truncating: RSSI)))
                }
            }
        }
    }
}

extension CMSensorDataList: Sequence {
    public typealias Iterator = NSFastEnumerationIterator
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

func getHash(data: String) -> String
{
    var hasher = Hasher()
    hasher.combine(data)
    let hashFromData = hasher.finalize()
    return hashFromData.formatted()
}
