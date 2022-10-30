import UIKit
import AVFoundation
import UniformTypeIdentifiers


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    let imagePicker = UIImagePickerController()
    var acc = AccelerometerHandler(updateInterval: 1.0/60.0)
    let device = UIDevice()
    @IBOutlet weak var emailTxtBox: UITextField!
    @IBOutlet weak var imageBox: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        imagePicker.delegate = self
        print(device.identifierForVendor?.uuidString)
        // Do any additional setup after loading the view.
    }

    @IBAction func LoginButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "MainWindowSegue", sender: self)
    }
    @IBAction func logOutTapped(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func cameraTapped(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
        print(acc.accelData.count)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            let imageData = image.pngData()
            let base64String = imageData?.base64EncodedString()
            print(imageData!.count)
            self.imageBox.image = getImageFromBase64(stringData: base64String!)
        }
        //getAccelerometerData(durationInSeconds: 1.0)
        imagePicker.dismiss(animated: true, completion: nil)
        acc.recordSensorsData(duration: 4.0)

        
    }
    
    func recordSensors() async throws -> String{
        
        
        return ""
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
