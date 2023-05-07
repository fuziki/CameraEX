//
//  CameraExCameraExtensionProviderSource.swift
//  CameraExCameraExtension
//  
//  Created by fuziki on 2023/05/06
//  
//

import CoreMediaIO
import Foundation
import os.log
import SystemExtensions

let kFrameRate: Int = 60
let kWidth: Int32 = 1920
let kHeight: Int32 = 1080

public class CameraExCameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
    
    public private(set) var provider: CMIOExtensionProvider!
    
    private var deviceSource: CameraExCameraExtensionDeviceSource!
    
    // CMIOExtensionProviderSource protocol methods (all are required)
    
    public init(clientQueue: DispatchQueue?) {
        super.init()

        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
        deviceSource = CameraExCameraExtensionDeviceSource(localizedName: "SampleCapture (Swift)")
        
        do {
            try provider.addDevice(deviceSource.device)
        } catch let error {
            fatalError("Failed to add device: \(error.localizedDescription)")
        }

        os_log("Start!")
    }
    
    public func connect(to client: CMIOExtensionClient) throws {
        
        // Handle client connect
        os_log("connect: \(client)")
    }
    
    public func disconnect(from client: CMIOExtensionClient) {
        
        // Handle client disconnect
        os_log("disconnect: \(client)")
    }

    public var availableProperties: Set<CMIOExtensionProperty> {
        
        // See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
        return [.providerManufacturer]
    }
    
    public func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        
        let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
        if properties.contains(.providerManufacturer) {
            providerProperties.manufacturer = "SampleCapture Manufacturer"
        }
        return providerProperties
    }
    
    public func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
        
        // Handle settable properties here.
        os_log("setProviderProperties: \(providerProperties)")
    }
}
