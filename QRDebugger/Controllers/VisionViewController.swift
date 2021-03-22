//
//  VisionViewController.swift
//  QRDebugger
//
//  Created by Alexey Belousov on 22.03.2021.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit
import Vision

final class _VisionViewController: UIViewController {

    private static let minimalConfidence: VNConfidence = 0.9

    private static let videoDataOutputQueueLabel = "com.example.video-data-output-queue"

    private let didOutputMetadata = PassthroughSubject<String, Never>()

    private let didFailed = PassthroughSubject<Error, Never>()

    private var captureSession: AVCaptureSession!

    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var cancellable: AnyCancellable? = nil

    private var detectBarcodeRequest: VNDetectBarcodesRequest!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        detectBarcodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
            if let error = error {
                self?.didFailed.send(error)
                return
            }

            guard let barcode = request.results?.first as? VNBarcodeObservation,
                  barcode.symbology == .QR,
                  barcode.confidence > Self.minimalConfidence,
                  let payloadString = barcode.payloadStringValue else { return }

//            print("[confidence: \(barcode.confidence)]", payloadString[...payloadString.index(payloadString.startIndex, offsetBy: 20)], "...")
            self?.didOutputMetadata.send(payloadString)
        }

        let captureOutput = AVCaptureVideoDataOutput()
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)

            let outputQueue = DispatchQueue(label: Self.videoDataOutputQueueLabel)
            captureOutput.setSampleBufferDelegate(self, queue: outputQueue)
            captureOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    public func setOutputMetadataAction(_ action: ((String) -> Void)? = nil) {
        guard let action = action else {
            cancellable = nil
            return
        }

        cancellable = didOutputMetadata
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: action)
    }

}

extension _VisionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)

        do {
            try imageRequestHandler.perform([ detectBarcodeRequest ])
        } catch {
            print(error)
        }
    }
}

struct VisionViewController: UIViewControllerRepresentable {

    typealias UIViewControllerType = _VisionViewController

    private let controller = _VisionViewController()

    func makeUIViewController(context: Context) -> _VisionViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: _VisionViewController, context: Context) {

    }

    public func onOutputMetadata(perform action: ((String) -> Void)? = nil) -> Self {
        controller.setOutputMetadataAction(action)
        return self
    }

}
