//
//  main.swift
//  CameraEXCameraExtension
//  
//  Created by fuziki on 2023/05/07
//  
//

import Foundation
import CoreMediaIO

let providerSource = CameraEXCameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
