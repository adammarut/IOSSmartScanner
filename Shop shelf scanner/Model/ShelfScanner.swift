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

class AccelerometerHandler{
    var manager = CMMotionManager()
    let recorder = CMSensorRecorder()
    let updateInterval: Double
    var accelDataPack:AccelerometerDataLog?
    var accelData: [XYZValue] = []
    var gyroData: [XYZValue] = []
    var magnetometerData: [XYZValue] = []
    var attitudeData: [EulerValue] = []
    var startDate: Date?
    var queue = OperationQueue()
    
    init(manager: CMMotionManager = CMMotionManager(), updateInterval: Double) {
        self.manager = manager
        self.updateInterval = updateInterval
    }
    
    struct EulerValue:Codable{
        var pitch:Double
        var roll:Double
        var yaw:Double
        var heading:Double
    }
    
    
    struct XYZValue:Codable{
        var x:Double
        var y:Double
        var z:Double
    }
    
    struct AccelerometerDataLog:Codable{
        var interval:Double
        var accelerometerData: [XYZValue]
        
        mutating func addAccelerometerValue(value:XYZValue){
            accelerometerData.append(value)
        }
    }
    
    struct GyroDataLog:Codable{
        var interval: Double
        var gyroData: [XYZValue]
    }
    
    func recordSensorsData(duration: Double){
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
    DispatchQueue.main.asyncAfter(deadline: .now()+duration) {
        self.manager.stopGyroUpdates()
        self.manager.stopMagnetometerUpdates()
        self.manager.stopAccelerometerUpdates()
        self.manager.stopDeviceMotionUpdates()
        print("Finished with \(self.accelData.count)")
    }

    }

    func initAccelerometer(){
        self.manager.accelerometerUpdateInterval = self.updateInterval
        self.manager.startAccelerometerUpdates()
    }
    
    
    
    func recordAccelerometerData(duration: Double) {
        self.accelData = []
        var timerFinished:Bool = false
        manager.accelerometerUpdateInterval = self.updateInterval
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            print("recorder started")
            DispatchQueue.global(qos: .background).async {
                self.recorder.recordAccelerometer(forDuration: duration)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                self.getData()
            }
        }
        
    }
    func recordGyroData(duration: Double) {
        self.accelData = []
        var timerFinished:Bool = false
        manager.gyroUpdateInterval = self.updateInterval
        if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            print("recorder started")
            DispatchQueue.global(qos: .background).async {
                //        self.recorder.rec(forDuration: duration)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                self.getData()
            }
        }
        
    }
    func getData(){
        print("getData started")
        if let list = recorder.accelerometerData(from: Date(timeIntervalSinceNow: -60), to: Date()) {
            print("listing data")
            for data in list{
                if let accData = data as? CMRecordedAccelerometerData{
                    self.accelData.append(XYZValue(x: accData.acceleration.x, y: accData.acceleration.y, z: accData.acceleration.z))
                }
            }
            print("Saved accelerometer data: \(self.accelData.count)")
        }
    }
    
    
    
    //
    //            self.accelDataPack = AccelerometerDataLog(interval: self.manager.accelerometerUpdateInterval, accelerometerData: accelData)
    //            let jsonAccelerometerRaw = try JSONEncoder().encode(accelDataPack)
    //            let jsonAccelerometerString = String(data: jsonAccelerometerRaw, encoding: .utf8)!
    //            print(jsonAccelerometerString)
    //            return jsonAccelerometerString
    //        } catch {
    ////            print(error)
    //            return ""
    //        }
    
    //    @objc func addRecord(){
    //        if let data = self.manager.accelerometerData
    //        {
    //            self.accelDataPack!.addAccelerometerValue(value: XYZValue(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z))
    //            print("x:\(data.acceleration.x) y:\(data.acceleration.y) z:\(data.acceleration.z)")
    //        }
    //    }
    
    //    func getAccelerometerData(durationInSeconds seconds: Double){
    //        if CMSensorRecorder.isAccelerometerRecordingAvailable(){
    //            let recorder = CMSensorRecorder()
    //            let start = NSDate()
    //            recorder.recordAccelerometer(forDuration:seconds)
    //            let now = NSDate()
    //            if   let list  =  recorder.accelerometerData(from: start as Date, to: now as Date)
    //            {
    //                for record in list
    //                {
    //                    let data = record as! CMRecordedAccelerometerData
    //                    print("x: \(data.acceleration.x) y: \(data.acceleration.y) z: \(data.acceleration.z) time :\(data.startDate.formatted())")
    //                }
    //            }
    //
    //        }
    //    }
    //
    func startQueuedUpdates() {
        if manager.isDeviceMotionAvailable {
            self.manager.deviceMotionUpdateInterval = 1.0 / 60.0
            self.manager.showsDeviceMovementDisplay = true
            self.manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                                  to: self.queue, withHandler: { (data, error) in
                // Make sure the data is valid before accessing it.
                if let validData = data {
                    // Get the attitude relative to the magnetic north reference frame.
                    let roll = validData.attitude.roll
                    let pitch = validData.attitude.pitch
                    let yaw = validData.attitude.yaw
                    self.accelData.append(XYZValue(x:roll, y: pitch, z: yaw))
                    // Use the motion data in your app.
                }
            })
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
