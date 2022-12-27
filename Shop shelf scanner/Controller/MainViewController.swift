import UIKit
import AVFoundation
import UniformTypeIdentifiers

class MainViewController: UIViewController, UINavigationControllerDelegate
{
    func opacityChanged(opacity:Double) {
        overlayPhotoImageView.alpha = opacity
    }
    
    
    
    @IBOutlet weak var overlayPhotoImageView: UIImageView!
    @IBOutlet weak var endPanoramaButton: UIButton!
    @IBOutlet weak var imageBox: UIImageView!
    
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var lastPhotoImageView: UIImageView!
    var previewView = PreviewView()
    
    let cameraHandler = CameraHandler(cameraType: .builtInWideAngleCamera, cameraPreset: .hd4K3840x2160)
    let scanner = ShelfScanner()
    
    var overlayIsOnLeft = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        self.cameraHandler.checkCameraPermissions()
        self.modalPresentationStyle = .fullScreen
        self.previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.previewView.videoPreviewLayer.session = self.cameraHandler.session
        view.layer.insertSublayer(self.previewView.videoPreviewLayer, at: 0)
        lastPhotoImageView.alpha = 1.0
        view.layer.addSublayer(lastPhotoImageView.layer)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        overlayPhotoImageView.isUserInteractionEnabled = true
        overlayPhotoImageView.addGestureRecognizer(tapGestureRecognizer)
        
        endPanoramaButton.superview?.bringSubviewToFront(endPanoramaButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateOverlayPhotoOnDisplay(_:)), name: Notification.Name("PhotoUpdate"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateOverlayOpacity(_:)), name: Notification.Name("overlayOpacityChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateStitchedImage(_:)), name: Notification.Name("stichedImage"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSensorsDuration(_:)), name: Notification.Name("sensorsDurationChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSensorsFrequency(_:)), name: Notification.Name("sensorsFrequencyChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stitchingFailed(_:)), name: Notification.Name("stichingFailed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(consecutiveStitching(_:)), name: Notification.Name("consecutiveStitchingChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(panoramicStitching(_:)), name: Notification.Name("panoramicStitchingChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stitchingConfChanged(_:)), name: Notification.Name("stitchingConfChanged"), object: nil)

   
        

        let defaults = UserDefaults.standard
        var overlayOpacity: Float
        if  (defaults.object(forKey: "overlayOpacity") != nil){
            overlayOpacity = defaults.float(forKey: "overlayOpacity")
            opacityChanged(opacity: Double(overlayOpacity))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
    }
    
    


@objc func stitchingConfChanged(_ notification: Notification)
{
    if let value = notification.userInfo?["stitchingConf"] as? Float{
        cameraHandler.setStitchingConf(value)
        
    }

}
    @objc func updateOverlayPhotoOnDisplay(_ notification: Notification) {
        updateOverlayPhoto()
    }
   
    @objc func stitchingFailed(_ notification: Notification) {
        
    }
    @objc func consecutiveStitching(_ notification: Notification) {
        if let value = notification.userInfo?["consecutive"] as? Bool{
            cameraHandler.changeStitchingMode(isConsecutive: value)
        }
    }
    @objc func panoramicStitching(_ notification: Notification) {
        if let value = notification.userInfo?["isPanoramic"] as? Bool{
            cameraHandler.changeStitchingMode(isPanoramic: value)
        }
    }
    
    
       
    @objc func updateSensorsDuration(_ notification: Notification) {
        let defaults = UserDefaults.standard
        cameraHandler.changeDuration(newDuration: defaults.double(forKey: "sensorsDuration"))
    }
    
    @objc func updateSensorsFrequency(_ notification: Notification) {
        let defaults = UserDefaults.standard
        cameraHandler.changeFrequency(newFrequency: defaults.double(forKey: "sensorsFrequency"))
    }
    
    @objc func updateOverlayOpacity(_ notification: Notification) {
        if let value = notification.userInfo?["opacity"] as? Double{
            opacityChanged(opacity: value)
        }
    }
    @objc func updateStitchedImage(_ notification: Notification){
        if let value = notification.userInfo?["stitched"] as? UIImage{
            lastPhotoImageView.image = value
        }
    }
    @IBAction func endPanoramaBtnTapped(_ sender: UIButton) {
        scanner.endPanorama()
        cameraHandler.endStitching()
        lastPhotoImageView.image = nil
        overlayPhotoImageView.image = nil
    }
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        UIView.animate(withDuration: 0.3, delay: 0.1, options: [], animations: {
            tappedImage.center.x = self.view.bounds.width-tappedImage.center.x
            }, completion: nil)
        if tappedImage.center.x > self.view.bounds.width/2{
            self.overlayIsOnLeft = false
        }
        else{
            self.overlayIsOnLeft = true
        }
        self.updateOverlayPhoto()
    }
    
    func updateOverlayPhoto(){
        if let newPhoto = self.cameraHandler.getImage(imageViewIsOnTheLeft: self.overlayIsOnLeft){
            self.overlayPhotoImageView.image = newPhoto
        }
    }
    
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
        DispatchQueue.main.async {
            self.previewView.videoPreviewLayer.opacity = 0
            UIView.animate(withDuration: 0.25) {
                self.previewView.videoPreviewLayer.opacity = 1
            }
        }
        cameraHandler.takePhoto()
    }
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


   
class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
