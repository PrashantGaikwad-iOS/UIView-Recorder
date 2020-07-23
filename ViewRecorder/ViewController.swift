//
//  ViewController.swift
//  ViewRecorder
//
//  Created by Prashant Gaikwad on 17/07/20.
//  Copyright © 2020 Prashant Gaikwad. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AVKit
import Photos

class ViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var imgView: UIImageView! // to show the images which are captured...
    @IBOutlet weak var mainView: UIView! //to which we are recording...
    
    //MARK: - Properties
    var videoFinalUrl = URL(string: "")
    var timer: DispatchSourceTimer?
    var myImagesArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if videoFinalUrl != nil {
            self.saveVideoToAlbum(videoFinalUrl!) { (error) in
                //Save to photos
                print("Done")
            }
        }
        
    }
    
    //MARK: - Actions
    @IBAction func startAction(_ sender: Any) {
        // Start recording
        startTimer()
    }
    
    @IBAction func stopAction(_ sender: Any) {
        // Stop recording
        stopTimer()
        let uiImages = myImagesArray
        let settings = CXEImagesToVideo.videoSettings(codec: AVVideoCodecType.h264.rawValue, width: (uiImages[0].cgImage?.width)!, height: (uiImages[0].cgImage?.height)!)
        let movieMaker = CXEImagesToVideo(videoSettings: settings)
        movieMaker.createMovieFrom(images: uiImages){ (fileURL:URL) in
            self.videoFinalUrl = fileURL
            self.playVideo(url: fileURL)
        }
    }
    
    //MARK: - Custom Actions
    func startTimer() {
        let queue = DispatchQueue(label: "com.domain.app.timer")  // you can also use `DispatchQueue.main`, if you want
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.schedule(deadline: .now(), repeating: .milliseconds(500))
        timer!.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.imgView.image = self?.mainView.takeScreenshot()
                self?.myImagesArray.append((self?.mainView.takeScreenshot())!)
            }
            
        }
        timer!.resume()
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    deinit {
        self.stopTimer()
    }
    
}



//MARK: - Play Video
extension ViewController {
    func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        let vc = AVPlayerViewController()
        vc.player = player
        self.present(vc, animated: true) { vc.player?.play() }
    }
}


//MARK: - Save Video
extension ViewController  {
    
    func requestAuthorization(completion: @escaping ()->Void) {
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    completion()
                }
            }
        } else if PHPhotoLibrary.authorizationStatus() == .authorized{
            completion()
        }
    }
    
    func saveVideoToAlbum(_ outputURL: URL, _ completion: ((Error?) -> Void)?) {
        requestAuthorization {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .video, fileURL: outputURL, options: nil)
            }) { (result, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        print("Saved successfully")
                    }
                    completion?(error)
                }
            }
        }
    }
    
}
