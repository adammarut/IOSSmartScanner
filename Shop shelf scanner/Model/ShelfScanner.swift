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
import AVFoundation

class AccelerometerHandler: NSObject{
    var manager = CMMotionManager()
    let recorder = CMSensorRecorder()
    var updateInterval: Double
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
    var duration: Double
    
    init(manager: CMMotionManager = CMMotionManager(), updateInterval: Double, duration: Double) {
        self.manager = manager
        self.updateInterval = updateInterval
        self.duration = duration
        
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
    func setFrequency(frequency:Double)
    {
        self.updateInterval = 1.0/frequency
    }
    func startRecordingSensorsData(){
        self.accelData = []
        self.getBLEDevices()
        
        //Get accelerometer data
        if manager.isAccelerometerAvailable{
            self.accelData = []
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
            self.gyroData = []
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
            self.magnetometerData=[]
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
            self.attitudeData=[]
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
        startRecordingSensorsData()
    }
    func getJsonData()-> String
    {
        let sensorsData = SensorsData(acc_data: self.accelData, gyro_data: self.gyroData, mag_data: self.magnetometerData, att_data: self.attitudeData)
        let allData = PackedData(sensors_data: sensorsData, image: self.rawPhotoData!, UUID: device.identifierForVendor?.uuidString, ble_devices: self.bleDevicesData)
        let encoder = JSONEncoder()
        let stringJSON = try! encoder.encode(allData)
        print(stringJSON.count)
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
        self.bleDevices.removeAll()
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

class CameraHandler: NSObject, UIImagePickerControllerDelegate,  AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    let cameraType: AVCaptureDevice.DeviceType
    let cameraPreset:AVCaptureSession.Preset
    var newPhoto: UIImage?
    var currentStitched: UIImage?
    private var photosArray: NSMutableArray = NSMutableArray()
    private var arrayOfPhotosArray: NSMutableArray = NSMutableArray()
    var isPanoramic: Bool = false
    
    private var acc: AccelerometerHandler?
    let defaults = UserDefaults.standard
    var sensorsDuration: Double
    var frequency: Double
    var currentData: String?
    var isConsecutive: Bool = false
    
    
    init(cameraType:AVCaptureDevice.DeviceType, cameraPreset:AVCaptureSession.Preset) {
        self.cameraType = cameraType
        self.cameraPreset = cameraPreset
        if (defaults.object(forKey: "sensorsFrequency") != nil){
            self.frequency = defaults.double(forKey: "sensorsFrequency")
        }
        else{
            self.frequency = 30.0
        }
        
        if (defaults.object(forKey: "sensorsDuration") != nil){
            self.sensorsDuration = defaults.double(forKey: "sensorsDuration")

        }
        else{
            self.sensorsDuration = 3
        }
        if (defaults.object(forKey: "isPanoramic") != nil){
            self.isPanoramic = defaults.bool(forKey: "isPanoramic")
        }
        if (defaults.object(forKey: "isConsecutive") != nil){
            self.isConsecutive = defaults.bool(forKey: "isConsecutive")
        }
        
        self.acc = AccelerometerHandler(updateInterval: 1.0/Double(frequency), duration: self.sensorsDuration )

    }
    
    func changeStitchingMode(isConsecutive: Bool)
    {
        self.isConsecutive = isConsecutive
        print("Is consecutive: \(self.isConsecutive)")

    }
    
    func changeStitchingMode(isPanoramic: Bool)
    {
        self.isPanoramic = isPanoramic
        print("Is panoramic: \(self.isPanoramic)")
    }
    func checkCameraPermissions(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .notDetermined:
            //Request camera accesss
            AVCaptureDevice.requestAccess(for: .video){ [weak self] granted in
                guard granted else{
                    return
                }
                DispatchQueue.main.async {
                    self?.setupAVCapture()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            self.setupAVCapture()
        @unknown default:
            break
        }
    }
    
    func setupAVCapture(){
        session.sessionPreset = self.cameraPreset
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                     for: .video,
                     position: AVCaptureDevice.Position.back) else {
            return
        }
        captureDevice = device
        beginSession()
    }
    
    func takePhoto(){
        handleTakePhoto()
        
    }
    
    func changeDuration(newDuration: Double)
    {
        self.sensorsDuration = newDuration
        self.acc = AccelerometerHandler(updateInterval: 1.0/Double(frequency), duration: self.sensorsDuration )

    }
    
    func changeFrequency(newFrequency: Double)
    {
        self.frequency = newFrequency
        print("Frequency changed \(self.frequency)")
        self.acc!.setFrequency(frequency: newFrequency)

    }
    
    func endStitching(){
        //self.arrayOfPhotosArray.add(self.photosArray)
        if (self.currentStitched != nil){
            UIImageWriteToSavedPhotosAlbum(self.currentStitched!, self, nil, nil)
        }
        self.photosArray.removeAllObjects()
        self.newPhoto = nil
        self.currentStitched = nil
    }
    
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            
            if session.canAddOutput(self.photoOutput){
                session.addOutput(self.photoOutput)
            }
            
            
            videoDataOutput.connection(with: .video)?.isEnabled = true
            photoOutput.connection(with: .video)?.isEnabled = true
            session.startRunning()
        }
        catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // do stuff here
    }

    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
    }
    
    func getImage(imageViewIsOnTheLeft:Bool) -> UIImage? {
        if let photo = self.newPhoto{
            let croppedPhoto = OpenCVWrapper.cropFor(matchingPreview: photo, imageViewIsOnTheLeft)
            return croppedPhoto
            }
        return nil
    }
    
    func tryStitching()
    {
        if(self.isConsecutive){
            if(currentStitched==nil){
                currentStitched = self.photosArray[self.photosArray.count-1] as! UIImage
                let newImageStitched:[String:UIImage] = ["stitched": currentStitched!]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stichedImage"), object: nil, userInfo: newImageStitched)
            }
            else{
                let newImage = OpenCVWrapper.stitchPhotos(currentStitched!,
                                                          photo2: self.photosArray[self.photosArray.count-1] as! UIImage,
                                                          panoramicWarp: self.isPanoramic)
                if newImage != nil{
                    let croppedNewImage = OpenCVWrapper.cropStitchedPhoto(newImage)
                    let newImageStitched:[String:UIImage] = ["stitched": croppedNewImage]
                    self.currentStitched = croppedNewImage
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stichedImage"), object: nil, userInfo: newImageStitched)
                }
                else{
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stichingFailed"), object: nil, userInfo: nil)
                }
            }
            
        }
        else{
            if(currentStitched==nil){
                currentStitched = self.photosArray[self.photosArray.count-1] as! UIImage
                let newImageStitched:[String:UIImage] = ["stitched": currentStitched!]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stichedImage"), object: nil, userInfo: newImageStitched)
            }
            else{
                
                let newImage = OpenCVWrapper.stitchPhotos(self.photosArray as! [Any], panoramicWarp: self.isPanoramic)
                if newImage != nil{
                    let croppedNewImage = OpenCVWrapper.cropStitchedPhoto(newImage)
                    let newImageStitched:[String:UIImage] = ["stitched": croppedNewImage]
                    self.currentStitched = croppedNewImage
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stichedImage"), object: nil, userInfo: newImageStitched)
                }
                else{
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "stichingFailed"), object: nil, userInfo: nil)
                }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error:Error?)
    {
        guard let imageData = photo.fileDataRepresentation() else{return}
        self.newPhoto = UIImage(data: imageData)!
        updateOverlayPhoto()
        photosArray.add(self.newPhoto)
        getData(photo:UIImage(data: imageData)!)
        tryStitching()
    }
    
    func updateOverlayPhoto() {
        NotificationCenter.default.post(Notification(name: Notification.Name("PhotoUpdate")))
    }
    
    @objc private func handleTakePhoto(){
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first{
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    func getData(photo: UIImage){
        let base64String = photo.pngData()!.base64EncodedString()
        self.acc!.addRawData(rawData: base64String)
        self.acc!.startRecordingSensorsData()
        DispatchQueue.main.asyncAfter(deadline: .now() + self.sensorsDuration) {
            let data = self.acc!.stopRecordingSensorData()
            self.currentData = data
            print("SHA256: \(getHash(data: data)) with size of \(data.count)")
            printMegaBytesOfData(data: data)
        }
    }
    
}

extension CMSensorDataList: Sequence {
    public typealias Iterator = NSFastEnumerationIterator
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

class ShelfScanner{
    let defaults = UserDefaults.standard
    var frequency: Int
    
    
    private var photosArray: NSMutableArray = NSMutableArray()
    private var cameraHandler: CameraHandler
    

    init() {
        cameraHandler = CameraHandler(cameraType: .builtInWideAngleCamera, cameraPreset: .hd4K3840x2160)
        if (defaults.object(forKey: "sensorsFrequency") != nil){
            self.frequency = defaults.integer(forKey: "sensorsFrequency")
        }
        else{
            self.frequency = 30
        }
    }
    func endPanorama(){

    }
}

func getHash(data: String) -> String
{
    var hasher = Hasher()
    hasher.combine(data)
    let hashFromData = hasher.finalize()
    return hashFromData.formatted()
}

func getImageFromBase64(stringData:String)->UIImage?{
    if let imageData = Data(base64Encoded: stringData) {
        if let image = UIImage(data: imageData) {
           return image
        }
    }
    return nil
}

func printMegaBytesOfData(data:String)
{
    let bcf = ByteCountFormatter()
    bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
    bcf.countStyle = .file
    let string = bcf.string(fromByteCount: Int64(data.count))
    print("Variable takes: \(string)")
}
