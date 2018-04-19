//
//  ViewController.swift
//  Camera
//
//  Created by Kaique Magno Dos Santos on 19/04/18.
//  Copyright © 2018 Dreamers and Makers. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet weak var outletCamerasSegement: UISegmentedControl!
    @IBOutlet weak var outletCameraView: UIView!
    @IBOutlet weak var outletCaptureButton: UIButton!
    @IBOutlet weak var outletFlash: UIStackView!
    @IBOutlet weak var outletFlashSwitch: UISwitch!
    
    // MARK: - Varaible
    // MARK: Private
    private var currentImage:UIImage?
    //
    private var captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var cameraLayer:AVCaptureVideoPreviewLayer?
    //Devices
    private var currentDevice:AVCaptureDevice? {
        didSet{
            self.outletFlash.isHidden = !self.currentDevice!.isTorchAvailable
            self.outletFlashSwitch.isOn = self.currentDevice!.isTorchActive
        }
    }
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    // MARK: Public
    
    // MARK: - UIViewController Variables
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - UIViewController Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch(_:)))
        self.view.addGestureRecognizer(pinchGesture)
        
        self.outletCaptureButton.layer.cornerRadius = self.outletCaptureButton.bounds.height / 2
        self.outletCaptureButton.backgroundColor = .white
        
        self.setupCaptureSession()
        self.setupDevice()
        self.setupInputOutput()
        self.setupPreviewLayer()
        self.startSession()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Functions
    // MARK: Private
    private func set(cameraLayer:AVCaptureVideoPreviewLayer){
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.frame = self.outletCameraView.bounds
        cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.outletCameraView.layer.addSublayer(cameraLayer)
    }
    
    
    private func setupCaptureSession() {
        self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    
    private func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                self.backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                self.frontCamera = device
            }
        }
        self.currentDevice = self.backCamera
    }
    
    
    private func setupInputOutput() {
        do {
            
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            self.captureSession.addInput(captureDeviceInput)
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            self.captureSession.addOutput(photoOutput!)
            
        } catch {
            print(error)
        }
    }
    
    private func setupPreviewLayer() {
        self.cameraLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.set(cameraLayer: self.cameraLayer!)
    }
    
    private func startSession(){
        self.captureSession.startRunning()
        
    }
    
    private func swapCamera(position:AVCaptureDevice.Position) {
        do {
            var captureDeviceInput = self.captureSession.inputs.first!
            
            //
            self.captureSession.removeInput(captureDeviceInput)
            
            //
            switch position {
            case .back:
                self.currentDevice = self.backCamera
            case .front:
                self.currentDevice = self.frontCamera
            case .unspecified:
                self.currentDevice = self.backCamera
            }
            
            //
            captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            self.captureSession.addInput(captureDeviceInput)
        } catch {
            print(error)
        }
    }
    
    private func zoom(scale:CGFloat) {
        guard let currentDeviceVerified = self.currentDevice else {
            return
        }
        
        do {
            try currentDeviceVerified.lockForConfiguration()
            
            if scale < currentDeviceVerified.maxAvailableVideoZoomFactor && scale > currentDeviceVerified.minAvailableVideoZoomFactor {
                currentDeviceVerified.videoZoomFactor = scale
            }
            currentDeviceVerified.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    private func save(image:UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    // MARK: Public
    
    @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
        self.zoom(scale: sender.scale)
    }
    
    // MARK: - IBAction
    @IBAction func tapTakePicture(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func valueChangedCamera(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.swapCamera(position: .back)
        }else{
            self.swapCamera(position: .front)
        }
    }
    @IBAction func valueChangedFlash(_ sender: UISwitch) {
        
        do {
            try self.currentDevice?.lockForConfiguration()
            if sender.isOn {
                self.currentDevice?.torchMode = .on
            }else{
                self.currentDevice?.torchMode = .off
            }
            self.currentDevice?.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPreviewViewController" {
            let previewViewController = segue.destination as! PreviewViewController
            previewViewController.image = self.currentImage
        }
    }
}


// MARK: - AVCaptureDepthDataOutputDelegate
extension ViewController:AVCapturePhotoCaptureDelegate{
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            self.currentImage = UIImage(data: imageData)
            self.save(image: self.currentImage!)
            self.performSegue(withIdentifier: "toPreviewViewController", sender: self)
        }
    }
}
