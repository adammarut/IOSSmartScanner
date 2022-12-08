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
    var shelfPhotos: [UIImage] = []
    var stitchedShelfPhotos: [UIImage] = []

    
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
    
    func getPhotoDataWithTelemetry(photo: UIImage, duration: Int) async -> String
    {
        startRecordingSensorsData()
        self.addPhoto(image: photo)
        let data = stopRecordingSensorData(duration: Double(duration))
            return data
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
    
    func addPhoto(image: UIImage)
    {
        self.shelfPhotos.append(image)
        if shelfPhotos.count>1
        {
            self.stitchPhotos()
        }
    }
    
    func getBLEDevices(){
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func stopRecordingSensorData(duration: Double) -> String
    {
         DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.manager.stopGyroUpdates()
            self.manager.stopMagnetometerUpdates()
            self.manager.stopAccelerometerUpdates()
            self.manager.stopDeviceMotionUpdates()
            self.centralManager?.stopScan()
            print("Finished with \(self.accelData.count) telemetry records.")
        }
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
        return  String(data:stringJSON, encoding: .utf8)!
    }
    
    func stitchPhotos()->Bool{
        if self.shelfPhotos.count>1{
            let stitchedPhoto = OpenCVWrapper.stitchPhotos(self.shelfPhotos as! [Any], panoramicWarp: false)
            stitchedShelfPhotos.append(stitchedPhoto)
            print("Stitched photos \(stitchedShelfPhotos.count)")
            return true
        }
        return false
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

    
    init(cameraType:AVCaptureDevice.DeviceType, cameraPreset:AVCaptureSession.Preset) {
        self.cameraType = cameraType
        self.cameraPreset = cameraPreset
       // self.checkCameraPermissions()
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
    
    func takePhoto()->UIImage{
        //
handleTakePhoto()
//        while(self.newPhoto == nil)
//        {
//        }
        let newPhotoCGImage = self.newPhoto?.cgImage?.copy()
        let newPhotoUIImage = UIImage(cgImage: newPhotoCGImage!,
                                      scale: self.newPhoto!.scale,
                                      orientation: self.newPhoto!.imageOrientation)
        self.newPhoto = nil
        return newPhotoUIImage
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
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error:Error?)
    {
        guard let imageData = photo.fileDataRepresentation() else{return}
        self.newPhoto = UIImage(data: imageData)!
        //overlayPhotoImageView.image
       // photosArray.add(previewImage)
        
    }
    
    @objc private func handleTakePhoto(){
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first{
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    
}

extension CMSensorDataList: Sequence {
    public typealias Iterator = NSFastEnumerationIterator
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

class OpenCVHandler{
    var photosArray: NSMutableArray = NSMutableArray()
    var isPanoramic: Bool = false
    
}

class ShelfScanner{
    private var acc = AccelerometerHandler(updateInterval: 1.0/60.0)
    private var photosArray: NSMutableArray = NSMutableArray()
    private var cameraHandler = CameraHandler(cameraType: .builtInWideAngleCamera, cameraPreset: .hd4K3840x2160)
    func takePhoto()-> UIImage{
        
        return cameraHandler.takePhoto()
        
    }
    
    
    func getData(){
       // let imagePngData = previewImage.pngData()
     //   let base64String = imagePngData?.base64EncodedString()
     //   self.acc.addRawData(rawData: base64String!)
//        acc.startRecordingSensorsData()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//            let data = self.acc.stopRecordingSensorData()
//            print("SHA256: \(getHash(data: data))")
//        }
        
//        if photosArray.count > 1 {
//            let newStitchedImage = OpenCVWrapper.stitchPhotos(photosArray as! [Any], panoramicWarp: isPanoramic)
       //     lastPhotoImageView.image = newStitchedImage
            
     //   }
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

func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect) -> UIImage?
{
    // Scale cropRect to handle images larger than shown-on-screen size
    let cropZone = CGRect(x:cropRect.origin.x ,
                          y:cropRect.origin.y ,
                          width:cropRect.size.width ,
                          height:cropRect.size.height)

    // Perform cropping in Core Graphics
    guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
    else {
        return nil
    }

    // Return image to UIImage
    let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
    return croppedImage
}


//    override var shouldAutorotate: Bool {
//            if (UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft ||
//            UIDevice.current.orientation == UIDeviceOrientation.landscapeRight ||
//            UIDevice.current.orientation == UIDeviceOrientation.unknown) {
//                return false
//            }
//            else {
//                return true
//            }
//        }

//extension CameraHandler:  AVCaptureVideoDataOutputSampleBufferDelegate{
//     func setupAVCapture(){
//         session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
//        guard let device = AVCaptureDevice
//        .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
//                 for: .video,
//                 position: AVCaptureDevice.Position.back) else {
//                            return
//        }
//        captureDevice = device
//        beginSession()
//    }
//
//    func beginSession(){
//        var deviceInput: AVCaptureDeviceInput!
//
//        do {
//            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
//            guard deviceInput != nil else {
//                print("error: cant get deviceInput")
//                return
//            }
//            
//            if self.session.canAddInput(deviceInput){
//                self.session.addInput(deviceInput)
//            }
//            
//            videoDataOutput = AVCaptureVideoDataOutput()
//            videoDataOutput.alwaysDiscardsLateVideoFrames=true
//            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
//            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
//            
//            if session.canAddOutput(self.photoOutput){
//                session.addOutput(self.photoOutput)
//            }
//            
//            
//            videoDataOutput.connection(with: .video)?.isEnabled = true
//            photoOutput.connection(with: .video)?.isEnabled = true
//            session.startRunning()
//        }
//        catch let error as NSError {
//            deviceInput = nil
//            print("error: \(error.localizedDescription)")
//        }
//    }
//
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        // do stuff here
//    }
//
//    // clean up AVCapture
//    func stopCamera(){
//        session.stopRunning()
//    }
//    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error:Error?)
//    {
//        guard let imageData = photo.fileDataRepresentation() else{return}
//        let previewImage = UIImage(data: imageData)!
//        
//        overlayPhotoImageView.image = OpenCVWrapper.cropFor(matchingPreview: previewImage)
//        photosArray.add(previewImage)
//        let imagePngData = previewImage.pngData()
//        let base64String = imagePngData?.base64EncodedString()
//        self.acc.addRawData(rawData: base64String!)
//        acc.startRecordingSensorsData()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//            let data = self.acc.stopRecordingSensorData()
//            print("SHA256: \(getHash(data: data)), size: \(data.count)")
//            
//        }
//        
//        if photosArray.count > 1 {
//            let newStitchedImage = OpenCVWrapper.stitchPhotos(photosArray as! [Any], panoramicWarp: isPanoramic)
//            lastPhotoImageView.image = newStitchedImage
//            
//        }
//        // cropImage(previewImage, toRect: CGRect(x: (2*previewImage.size.width)/3, y: 0, width: (previewImage.size.width/3)-1, height: previewImage.size.height))
//    }
//    
