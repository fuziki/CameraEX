//
//  File.swift
//  
//  
//  Created by fuziki on 2023/05/07
//  
//

import CoreMediaIO
import Foundation
import os.log
import SwiftUI
import SystemExtensions

class ContentViewModel: NSObject, ObservableObject {
    @Published var state: String = "---"

    private let extID: String = "com.example.CameraEXApp.CameraEXCameraExtension"

    func activate() {
        let activationRequest = OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier: extID, queue: .main)
        activationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(activationRequest)

        state = "activated"
    }

    func deactivate() {
        let deactivationRequest = OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: extID, queue: .main)
        deactivationRequest.delegate = self
        OSSystemExtensionManager.shared.submitRequest(deactivationRequest)

        state = "deactivated"
    }
}

extension ContentViewModel: OSSystemExtensionRequestDelegate {
    func request(_ request: OSSystemExtensionRequest,
                 actionForReplacingExtension existing: OSSystemExtensionProperties,
                 withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {
        os_log("actionForReplacingExtension: \(existing), withExtension: \(ext)")
        return .replace
    }

    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        os_log("requestNeedsUserApproval: \(request)")
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        os_log("didFinishWithResult")
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        os_log("didFailWithError: \(error)")
    }
}
