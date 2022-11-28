import UIKit
import AVFoundation
import UniformTypeIdentifiers


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    let imagePicker = UIImagePickerController()
    var acc = AccelerometerHandler(updateInterval: 1.0/60.0)
    @IBOutlet weak var emailTxtBox: UITextField!
    @IBOutlet weak var overlayPhotoImageView: UIImageView!
    @IBOutlet weak var secondsStepper: UIStepper!
    @IBOutlet weak var secondsLabel: UITextField!
    @IBOutlet weak var imageBox: UIImageView!
    
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var lastPhotoImageView: UIImageView!
    var previewView : UIView!

    //Camera Capture requiered properties
      var videoDataOutput: AVCaptureVideoDataOutput!
      var videoDataOutputQueue: DispatchQueue!
      var previewLayer:AVCaptureVideoPreviewLayer!
      var captureDevice : AVCaptureDevice!
      let session = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        imagePicker.delegate = self
       // previewView = UIView(frame: CGRect(x: 0,
//                                                   y: 0,
//                                                   width: UIScreen.main.bounds.size.width,
//                                                   height: UIScreen.main.bounds.size.height))
       // previewView.contentMode = UIView.ContentMode.scaleAspectFit
      //  view.addSubview(previewView)
        
        self.setupAVCapture()

       // self.modalPresentationStyle = .fullScreen
        // Do any additional setup after loading the view.
    }

    @IBAction func LoginButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "MainWindowSegue", sender: self)
    }
    @IBAction func settingsTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
        secondsStepper.minimumValue = 1
        secondsStepper.maximumValue = 120
        secondsStepper.value = 3.0
        secondsLabel.text = String(secondsStepper.value)

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
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
        if (imageBox.image != nil){
            lastPhotoImageView.image = imageBox.image
            let cropped = cropToBounds(image: imageBox.image!, width: 130.0, height: 649.0)
            overlayPhotoImageView.image = cropped.alpha(0.5)
            
        }
    }
    
    @IBAction func secondsChanged(_ sender: UIStepper) {
        print(secondsStepper.value)
        secondsLabel.text = String(secondsStepper.value)

    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            let imageData = image.pngData()
            let base64String = imageData?.base64EncodedString()
            self.acc.addRawData(rawData: base64String!)
            self.imageBox.image = getImageFromBase64(stringData: base64String!)
            acc.addPhoto(image: image)
            if acc.stitchPhotos(){
                print("Stitched")
            }
            else{
                print("Stitching failed")

            }
        }
        imagePicker.dismiss(animated: true, completion: nil)
        acc.startRecordingSensorsData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let data = self.acc.stopRecordingSensorData()
            print("SHA256: \(getHash(data: data))")
            
        }
    }
    
}
func getImageFromBase64(stringData:String)->UIImage?{
    if let imageData = Data(base64Encoded: stringData) {
        if let image = UIImage(data: imageData) {
           return image
        }
    }
    return nil
}


func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

    let contextImage: UIImage = UIImage(cgImage: image.cgImage!)

    let contextSize: CGSize = contextImage.size

    var posX: CGFloat = 0.0
    var posY: CGFloat = 0.0
    var cgwidth: CGFloat = CGFloat(width)
    var cgheight: CGFloat = CGFloat(height)

    // See what size is longer and create the center off of that
    if contextSize.width > contextSize.height {
        posX = ((contextSize.width - contextSize.height) / 2)
        posY = 0
        cgwidth = contextSize.height
        cgheight = contextSize.height
    } else {
        posX = 0
        posY = ((contextSize.height - contextSize.width) / 2)
        cgwidth = contextSize.width
        cgheight = contextSize.width
    }

    let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)

    // Create bitmap image from context using the rect
    let imageRef = contextImage.cgImage!.cropping(to: rect)

    // Create a new image based on the imageRef and rotate back to the original orientation
    let image: UIImage = UIImage(cgImage: imageRef!, scale: image.scale, orientation: image.imageOrientation)

    return image
}

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

extension UIImage{
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
        
    }
}

extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
     func setupAVCapture(){
         session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
        guard let device = AVCaptureDevice
        .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                 for: .video,
                 position: AVCaptureDevice.Position.back) else {
                            return
        }
        captureDevice = device
        beginSession()
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
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)

            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }

            videoDataOutput.connection(with: .video)?.isEnabled = true

            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            if (self.cameraView != nil){
                let rootLayer :CALayer = self.cameraView.layer
                rootLayer.masksToBounds=true
                previewLayer.frame = rootLayer.bounds
                rootLayer.addSublayer(self.previewLayer)
                session.startRunning()
            }
        } catch let error as NSError {
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

}
