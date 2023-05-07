//
//  main.swift
//  CameraEXCameraExtension
//  
//  Created by fuziki on 2023/05/07
//  
//

import Foundation
import CameraEXCameraExtensionLib
import CoreMediaIO

let providerSource = CameraExCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
