//
//  SwiftTKViewController.swift
//  TUSKit
//
//  Created by Mark Masterson on 2/20/18.
//  Copyright © 2018 Michael Avila. All rights reserved.
//

import UIKit
import Photos

class SwiftTKViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //MARK: Blocks
    var progressBlock: TUSUploadProgressBlock = {(_ bytesWritten: Int64, _ bytesTotal: Int64) -> Void in
        // Update your progress bar here
        print("progress: \(UInt64(bytesWritten)) / \(UInt64(bytesTotal))")
    }
    var resultBlock: TUSUploadResultBlock = {(_ fileURL: URL) -> Void in
        // Use the upload url
        print("url: \(fileURL)")
    }
    var failureBlock: TUSUploadFailureBlock = {(_ error: Error?) -> Void in
        // Handle the error
        print("error: \(String(describing: error))")
    }
    
    //CONSTANTS
    let UPLOAD_ENDPOINT: URL = URL(string: "http://master.tus.io/files/")!
    let FILE_NAME = "test.jpg"
    
    //Objects Used
    var tusSession: TUSSession?
    var uploadStore: TUSUploadStore?
    let imagePicker: UIImagePickerController = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        var applicationSupportURL: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first

        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        uploadStore = TUSFileUploadStore(url: (applicationSupportURL?.appendingPathComponent(FILE_NAME))!)
        tusSession = TUSSession(endpoint: UPLOAD_ENDPOINT, dataStore: uploadStore!, allowsCellularAccess: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.selectFile("")
    }
    
    @IBAction func selectFile(_ sender: Any) {
        //imagePicker.mediaTypes = [imagePicker.sourceType]
        
        let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.present(imagePicker, animated: true, completion: nil)
            break
        default:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    print("success")
                }
            })
            break
        }
    }
    
@objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil);
        
        let assetURL: URL = info[UIImagePickerControllerReferenceURL] as! URL
        let result: PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        
        var assetCollection: PHAssetCollection = result.firstObject!
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil)
        let asset: PHAsset = fetchResult.firstObject!
        
        let photoManager: PHImageManager = PHImageManager()
        
        photoManager.requestImageData(for: asset, options: nil) { (imageData, dataUTI, orientation, info) in
            let documentDir: URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.allDomainsMask)[0]
            let fileURl: URL = documentDir.appendingPathComponent(UUID.init().uuidString)
            
            if ((try! imageData?.write(to: fileURl)) != nil) {
                print(fileURl)
                let upload: TUSResumableUpload = (self.tusSession?.createUpload(fromFile: fileURl, headers: ["":""], metadata: ["":""] ))!
                upload.resultBlock = self.resultBlock
                upload.progressBlock = self.progressBlock
                upload.failureBlock = self.failureBlock
                
                upload.resume()
            }
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
