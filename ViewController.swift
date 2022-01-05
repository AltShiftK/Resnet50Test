//
//  ViewController.swift
//  VisionAPINew
//
//  Created by Kendrick Lee on 11/18/21.

// Super messy, fix later in production

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Startup Camera
        print("test")
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            if captureSession.canAddInput(input){
                captureSession.addInput(input)
            }
        }
        catch {
            print("Error")
        }
        captureSession.startRunning()

        // Make camera visible
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) as AVCaptureVideoPreviewLayer

        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        // Make overlays visible
        var previewView = UIView(frame: view.frame)
        view.addSubview(previewView)
        previewView.layer.addSublayer(previewLayer)


        let subButton = UIButton()
        subButton.setBackgroundImage(UIImage(named: "capImage"), for: UIControl.State.normal)
        subButton.frame = CGRect(x: 15, y: 50, width: 60, height: 60)
        subButton.center.x = view.center.x
        self.view.addSubview(subButton)

        // Make an output from the camera
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupIdentifierConfidenceLabel()
    }
    
    fileprivate func setupIdentifierConfidenceLabel(){
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //print("Camera was able to capture", Date())
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            // print(finishedReq.results)
            // finishedReq.results is raw result data (unusable)
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                self.identifierLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)%"
            }
            
        }
        // Sends request to the algorithm (Resnet50)
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

