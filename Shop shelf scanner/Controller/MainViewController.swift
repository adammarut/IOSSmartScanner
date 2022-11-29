import UIKit
import AVFoundation
import UniformTypeIdentifiers


class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    // let imagePicker = UIImagePickerController()
    //Camera device
    // Capture session
    //    var cameraSession: AVCaptureSession?
    //    // Photo output
    //    let cameraOutput = AVCapturePhotoOutput()
    //    // Video Preview
    //    let cameraPreviewLayer = AVCaptureVideoPreviewLayer()
    
    
    var acc = AccelerometerHandler(updateInterval: 1.0/60.0)
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var overlayPhotoImageView: UIImageView!
    @IBOutlet weak var lastPhotoImageView: UIImageView!
    var previewView = PreviewView()
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let cameraSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermissions()
        navigationItem.hidesBackButton = true
        
        
        self.modalPresentationStyle = .fullScreen
        
        // Add video preview at the bottom
        self.previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.previewView.videoPreviewLayer.session = self.cameraSession
        view.layer.insertSublayer(self.previewView.videoPreviewLayer, at: 0)
        
        //change button properties
        captureButton.alpha = 0.9
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
    }
    
    private func checkCameraPermissions(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .notDetermined:
            //Request camera accesss
            AVCaptureDevice.requestAccess(for: .video){ [weak self] granted in
                guard granted else{
                    return
                }
                DispatchQueue.main.async {
                    self?.setupCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            self.setupCamera()
        @unknown default:
            break
        }
    }
    
    func setupCamera(){
        cameraSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .unspecified)
        
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
              cameraSession.canAddInput(videoDeviceInput)
        else { return }
        cameraSession.addInput(videoDeviceInput)
        
        let photoOutput = AVCapturePhotoOutput()
        guard cameraSession.canAddOutput(photoOutput) else { return }
        cameraSession.sessionPreset = .photo
        cameraSession.addOutput(photoOutput)
        cameraSession.commitConfiguration()
        cameraSession.startRunning()
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
    
    //    private func setUpCamera(){
    //        let session = AVCaptureSession()
    //        if let device = AVCaptureDevice.default(for: .video){
    //            do{
    //                let input = try AVCaptureDeviceInput(device: device)
    //                if session.canAddInput(input) {
    //                    session.addInput(input)
    //                }
    //                if session.canAddOutput(cameraOutput){
    //                    session.addOutput(cameraOutput)
    //                }
    //
    //                cameraPreviewLayer.videoGravity = .resizeAspectFill
    //                cameraPreviewLayer.session = session
    //                session.startRunning()
    //                self.cameraSession = session
    //            }
    //            catch{
    //                print(error)
    //            }
    //        }
    //    }
    //
    //
    //
    
    @IBAction func settingsTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
        
    }
    @IBAction func logOutTapped(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func settingsBtnTapped(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
        
    }
    
    @IBAction func galleryTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "GallerySegue", sender: self)
    }
    
    
    @IBAction func cameraTapped(_ sender: UIButton) {
//        photoOutput.capturePhoto(with: AVCapturePhotoSettings(),
//                                 delegate: self)
        if let photoOutputConnection = self.photoOutput.connection(with: .video) {
            //            photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            //        }
            var photoSettings = AVCapturePhotoSettings()
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first{
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
                photoOutput.capturePhoto(with: photoSettings, delegate: self)
                print("Photo taken")
            }
        }
        // handleTakePhoto()
        //        if (imageBox.image != nil){
        //            lastPhotoImageView.image = imageBox.image
        //            let cropped = cropToBounds(image: imageBox.image!, width: 130.0, height: 649.0)
        //            overlayPhotoImageView.image = cropped.alpha(0.5)
        //
        //        }
        
        
        
        //    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //
        //        if let image = info[.originalImage] as? UIImage {
        //            let imageData = image.pngData()
        //            let base64String = imageData?.base64EncodedString()
        //            self.acc.addRawData(rawData: base64String!)
        //            self.imageBox.image = getImageFromBase64(stringData: base64String!)
        //            acc.addPhoto(image: image)
        //            if acc.stitchPhotos(){
        //                print("Stitched")
        //            }
        //            else{
        //                print("Stitching failed")
        //
        //            }
        //        }
        //        imagePicker.dismiss(animated: true, completion: nil)
        //        acc.startRecordingSensorsData()
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        //            let data = self.acc.stopRecordingSensorData()
        //            print("SHA256: \(getHash(data: data))")
        //
        //        }
        //    }
        
    }
    func getImageFromBase64(stringData:String)->UIImage?{
        if let imageData = Data(base64Encoded: stringData) {
            if let image = UIImage(data: imageData) {
                return image
            }
        }
        return nil
    }
    
    
    //func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
    //
    //    let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
    //
    //    let contextSize: CGSize = contextImage.size
    //
    //    var posX: CGFloat = 0.0
    //    var posY: CGFloat = 0.0
    //    var cgwidth: CGFloat = CGFloat(width)
    //    var cgheight: CGFloat = CGFloat(height)
    //
    //    // See what size is longer and create the center off of that
    //    if contextSize.width > contextSize.height {
    //        posX = ((contextSize.width - contextSize.height) / 2)
    //        posY = 0
    //        cgwidth = contextSize.height
    //        cgheight = contextSize.height
    //    } else {
    //        posX = 0
    //        posY = ((contextSize.height - contextSize.width) / 2)
    //        cgwidth = contextSize.width
    //        cgheight = contextSize.width
    //    }
    //
    //    let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
    //
    //    // Create bitmap image from context using the rect
    //    let imageRef = contextImage.cgImage!.cropping(to: rect)
    //
    //    // Create a new image based on the imageRef and rotate back to the original orientation
    //    let image: UIImage = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)
    //
    //    return image
    //}
    
    //
    //class VideoHelper {
    //
    //    static func startMediaBrowser(delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate, sourceType: UIImagePickerController.SourceType) {
    //        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
    //
    //        let mediaUI = UIImagePickerController()
    //        mediaUI.sourceType = sourceType
    //        mediaUI.mediaTypes = [UTType.movie.identifier]
    //        mediaUI.allowsEditing = true
    //        mediaUI.delegate = delegate
    //        delegate.present(mediaUI, animated: true, completion: nil)
    //    }
    //}
}
    extension UIImage{
        
        func alpha(_ value:CGFloat) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
            
        }
    }
    
    //extension MainViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
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
    //            self.photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
    //            if session.canAddOutput(self.photoOutput){
    //                session.addOutput(self.photoOutput)
    //            }
    //
    //
    //            videoDataOutput.connection(with: .video)?.isEnabled = true
    //            photoOutput.connection(with: .video)?.isEnabled = true
    //
    //            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    //            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
    //            if (self.cameraView != nil){
    //                let rootLayer :CALayer = self.cameraView.layer
    //                rootLayer.masksToBounds=true
    //                previewLayer.frame = rootLayer.bounds
    //                rootLayer.addSublayer(self.previewLayer)
    //                session.startRunning()
    //            }
    //        } catch let error as NSError {
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
    //        overlayPhotoImageView.image = cropImage(previewImage, toRect: CGRect(x: (2*previewImage.size.width)/3, y: 0, width: (previewImage.size.width/3)-1, height: previewImage.size.height))
    //    }
    //
    //    @objc private func handleTakePhoto(){
    ////        if let photoOutputConnection = self.photoOutput.connection(with: .video) {
    ////            photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
    ////        }
    //        var photoSettings = AVCapturePhotoSettings()
    //        if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
    //            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
    //        }
    //        if self.deviceInput.device.isFlashAvailable {
    //            photoSettings.flashMode = .auto
    //        }
    //        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first{
    //            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
    //            photoOutput.capturePhoto(with: photoSettings, delegate: self)
    //        }
    //    }
    //    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect) -> UIImage?
    //    {
    //
    //
    //        // Scale cropRect to handle images larger than shown-on-screen size
    //        let cropZone = CGRect(x:cropRect.origin.x ,
    //                              y:cropRect.origin.y ,
    //                              width:cropRect.size.width ,
    //                              height:cropRect.size.height)
    //
    //        // Perform cropping in Core Graphics
    //        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
    //        else {
    //            return nil
    //        }
    //
    //        // Return image to UIImage
    //        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
    //        return croppedImage
    //    }
    //}
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
      
extension MainViewController: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else{
            return
        }
        let image = UIImage(data: data)
        lastPhotoImageView.image = image
    }
}
