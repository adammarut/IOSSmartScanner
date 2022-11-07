import UIKit
import AVFoundation
import UniformTypeIdentifiers


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    let imagePicker = UIImagePickerController()
    var acc = AccelerometerHandler(updateInterval: 1.0/60.0)
    @IBOutlet weak var emailTxtBox: UITextField!
    @IBOutlet weak var secondsStepper: UIStepper!
    @IBOutlet weak var secondsLabel: UITextField!
    @IBOutlet weak var imageBox: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        imagePicker.delegate = self
        
        
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
    @IBAction func cameraTapped(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
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

class VideoHelper {
    
    static func startMediaBrowser(delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate, sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = sourceType
        mediaUI.mediaTypes = [UTType.movie.identifier]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        delegate.present(mediaUI, animated: true, completion: nil)
    }
}
