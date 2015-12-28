//
//  DYECameraViewController.swift
//  DYECamera
//
//  Created by Danny Yassine on 2015-12-28.
//  Copyright © 2015 Danny Yassine. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import AssetsLibrary
import Photos
import MediaPlayer
import MobileCoreServices

class DYECameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var movieFileOutPut: AVCaptureMovieFileOutput!
    var imageFileOutPut: AVCaptureStillImageOutput!
    @IBOutlet weak var previewCameraView: UIView!
    
    var frontCameraOn: Bool = false
    
    @IBOutlet weak var cameraButton: DYECameraButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var audioMicrophone: AVCaptureDevice!
        
        for device in AVCaptureDevice.devices() {
            print(device.localizedName)
            if device.hasMediaType(AVMediaTypeVideo) {
                if device.position == AVCaptureDevicePosition.Back {
                    print("Device position : back");
                }
                else {
                    print("Device position : front");
                }
            } else if device.hasMediaType(AVMediaTypeAudio) {
                print("Device has media type audio")
                audioMicrophone = device as! AVCaptureDevice
            }
        }
        
        let backCamera = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).first!
        
        let deviceInput = try! AVCaptureDeviceInput(device: backCamera as! AVCaptureDevice)
        let deviceAudioInput = try! AVCaptureDeviceInput(device: audioMicrophone)
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = AVCaptureSessionPresetHigh
        self.captureSession.addInput(deviceInput)
        self.captureSession.addInput(deviceAudioInput)
        
        self.movieFileOutPut = AVCaptureMovieFileOutput()
        movieFileOutPut.maxRecordedDuration = CMTime(seconds: 8, preferredTimescale: 30)
        movieFileOutPut.minFreeDiskSpaceLimit = 1024 * 1024
        self.captureSession.addOutput(movieFileOutPut)
        
        self.imageFileOutPut = AVCaptureStillImageOutput()
        self.imageFileOutPut.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        self.captureSession.addOutput(self.imageFileOutPut)
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer!.frame = self.view.bounds
        self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
        self.previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        self.previewCameraView.layer.addSublayer(self.previewLayer)
        
        self.captureSession.startRunning()
        
        self.cameraButton.duration = 8.0
        let longPress = UILongPressGestureRecognizer(target: self, action: "longPressGuesture:")
        longPress.minimumPressDuration = 1.0
        longPress.allowableMovement = 1000
        self.cameraButton.addGestureRecognizer(longPress)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        
    }
    
    func longPressGuesture(longPress: UILongPressGestureRecognizer) {
        
        if longPress.state == .Began {
            self.startVideoRecording()
        } else if longPress.state == .Ended {
            self.stopRecording()
        }
        
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        // A problem occurred: Find out if the recording was successful.
        var recordedSuccessfully: Bool = true
        
        if error != nil {
            let value = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey]
            if ((value) != nil) {
                recordedSuccessfully = value!.boolValue
                print("recordedSuccessfully: ", recordedSuccessfully)
            }
        }
        
        if recordedSuccessfully {
            
            // Save
            let photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
            photoLibrary.performChanges({ () -> Void in
                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputFileURL)
                }) { (done, error) -> Void in
                    print("done: ", done, "error: ", error)
            }
        }
        
        
    }
    
    @IBAction func startRecording(sender: AnyObject?) {
        
        if self.movieFileOutPut.recording == true {
            return
        }
        
        if self.cameraButton.isAnimating == true {
            self.stopRecording()
        } else {
            var videoConnection: AVCaptureConnection!
            for connection in self.imageFileOutPut.connections {
                for port in connection.inputPorts as! [AVCaptureInputPort] {
                    if port.mediaType == AVMediaTypeVideo {
                        videoConnection = connection as! AVCaptureConnection
                        break
                    }
                }
                if videoConnection != nil {
                    break
                }
            }
            self.imageFileOutPut.captureStillImageAsynchronouslyFromConnection(videoConnection) { (sampleBuffer, error) -> Void in
                if (sampleBuffer != nil) {
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Left)
                    
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 75, height: 100))
                    imageView.image = image
                    self.view.addSubview(imageView)
                    
                }
            }
        }
        
    }
    
    func startVideoRecording() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let moviePath = documentsPath + "/movie\(NSDate()).mov"
        let url = NSURL(fileURLWithPath: moviePath)
        print(url)
        
        self.movieFileOutPut.startRecordingToOutputFileURL(url, recordingDelegate: self)
        
        self.cameraButton.setRecording()
    }
    
    func stopRecording() {
        self.movieFileOutPut.stopRecording()
        self.cameraButton.stoppedRecording()
    }
    
    @IBAction func toggleCameraButtonPressed(sender: AnyObject) {
        
        var devicePosition: AVCaptureDevicePosition
        
        if frontCameraOn {
            devicePosition = .Back
        } else {
            devicePosition = .Front
        }
        
        captureSession.beginConfiguration()
        let device = self.switchCameras(devicePosition)
        var input = AVCaptureDeviceInput?()
        do {
            input = try AVCaptureDeviceInput(device: device)
            let inputs = self.captureSession.inputs as! [AVCaptureInput]
            self.frontCameraOn = !self.frontCameraOn
            for input in inputs {
                if let deviceInput = input as? AVCaptureDeviceInput {
                    if deviceInput.device.hasMediaType(AVMediaTypeVideo) {
                        self.captureSession.removeInput(input)
                    }
                }
            }
            self.captureSession.addInput(input!)
        } catch _ {
            input = nil
        }
        captureSession.commitConfiguration()
    }
    func switchCameras(devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        let deviceArrays = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in deviceArrays {
            if device.position == devicePosition {
                return device as? AVCaptureDevice
            }
        }
        
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func presentMovie(movieURL: NSURL) {
        let moviePlayerMovieController = AVPlayerViewController()
        let playerItem = AVPlayerItem(URL: movieURL)
        let player = AVPlayer(playerItem: playerItem)
        moviePlayerMovieController.player = player
        self.presentViewController(moviePlayerMovieController, animated: true) { () -> Void in
            
        }
    }
    
}


