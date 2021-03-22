//
//  AVFoundationViewController.swift
//  QRDebugger
//
//  Created by Alexey Belousov on 11.03.2021.
//

import AVFoundation
import Combine
import SwiftUI
import UIKit

final class _AVFoundationViewController: UIViewController {

    private let didOutputMetadata = PassthroughSubject<String, Never>()

    private let didFailed = PassthroughSubject<Void, Never>()

    private var captureSession: AVCaptureSession!

    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var cancellable: AnyCancellable? = nil

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

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [ .qr ]
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

extension _AVFoundationViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }

        didOutputMetadata.send(stringValue)
    }

}

struct AVFoundationViewController: UIViewControllerRepresentable {

    typealias UIViewControllerType = _AVFoundationViewController

    private let controller = _AVFoundationViewController()

    func makeUIViewController(context: Context) -> _AVFoundationViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: _AVFoundationViewController, context: Context) {

    }

    public func onOutputMetadata(perform action: ((String) -> Void)? = nil) -> Self {
        controller.setOutputMetadataAction(action)
        return self
    }

}
