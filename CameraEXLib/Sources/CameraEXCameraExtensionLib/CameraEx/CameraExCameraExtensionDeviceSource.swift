//
//  CameraExCameraExtensionDeviceSource.swift
//  CameraExCameraExtension
//  
//  Created by fuziki on 2023/05/06
//  
//

import CoreMediaIO
import Foundation
import IOKit.audio
import os.log
import SystemExtensions

class CameraExCameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {

    private(set) var device: CMIOExtensionDevice!

    private var _sourceStreamSource: SourceDirectionExtensionStreamSource!
    private var _sinkStreamSource: SinkDirectionExtensionStreamSource!

    private var _streamingCounter: UInt32 = 0

    private var _videoDescription: CMFormatDescription!

    private var _sbp: SampleBufferProvider!

    private var soucing: Bool = false
    private var sinking: Bool = false

    init(localizedName: String) {
        super.init()

        let deviceID = UUID(uuidString: "C6D5AECB-066D-4FE4-98ED-0D0E29AD2BD8")! // replace this with your device UUID
        device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)

        CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                       codecType: kCVPixelFormatType_32BGRA,
                                       width: kWidth,
                                       height: kHeight,
                                       extensions: nil,
                                       formatDescriptionOut: &_videoDescription)

        let videoStreamFormat = CMIOExtensionStreamFormat(formatDescription: _videoDescription,
                                                          maxFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)),
                                                          minFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)),
                                                          validFrameDurations: nil)

        _sbp = .init(videoDescription: _videoDescription)

        let videoID = UUID(uuidString: "CE90BFDB-BFEB-44AA-89CA-5296ADC3ECC2")! // replace this with your video UUID
        _sourceStreamSource = .init(localizedName: "SampleCapture.Video",
                                    streamID: videoID,
                                    streamFormat: videoStreamFormat,
                                    device: device)
        let sinkID = UUID(uuidString: "CEC941BB-875A-40C5-A23E-A5603727A207")! // replace this with your video UUID
        _sinkStreamSource = .init(localizedName: "SampleCapture.Video.Sink",
                                  streamID: sinkID,
                                  streamFormat: videoStreamFormat,
                                  device: device)
        do {
            try device.addStream(_sourceStreamSource.stream)
            try device.addStream(_sinkStreamSource.stream)
        } catch let error {
            fatalError("Failed to add stream: \(error.localizedDescription)")
        }
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        
        return [.deviceTransportType, .deviceModel]
    }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
        if properties.contains(.deviceTransportType) {
            deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
        }
        if properties.contains(.deviceModel) {
            deviceProperties.model = "SampleCapture Model"
        }

        os_log("deviceProperties properties: \(properties)")

        return deviceProperties
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {

        // Handle settable properties here.
        os_log("setDeviceProperties: \(deviceProperties)")
    }

    func startSourceStreaming() {
        os_log("source startSourceStreaming")
        soucing = true

        _streamingCounter += 1

        _sbp.onBuffer = { [weak self] (buffer, nanoSec) in
            if self?.sinking == true { return }
            self?._sourceStreamSource.stream.send(buffer, discontinuity: [], hostTimeInNanoseconds: nanoSec)
        }
        _sbp.start()
    }

    func stopSourceStreaming() {
        os_log("source stopSourceStreaming")
        soucing = false

        if _streamingCounter > 1 {
            _streamingCounter -= 1
        } else {
            _streamingCounter = 0
            _sbp.onBuffer = nil
            _sbp.stop()
        }
    }

    func startSinkStreaming() {
        os_log("sink startSinkStreaming")
        sinking = true

        _streamingCounter += 1

        _sinkStreamSource.consumeSampleBuffer = { [weak self] buffer in
            if self?.soucing == false { return }
            var timingInfo = CMSampleTimingInfo()
            timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
            let nanoSec = UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
            self?._sourceStreamSource.stream.send(buffer,
                                                  discontinuity: [],
                                                  hostTimeInNanoseconds: nanoSec)
        }
    }

    func stopSinkStreaming() {
        os_log("sink stopSinkStreaming")
        sinking = false
        _sinkStreamSource.consumeSampleBuffer = nil

        if _streamingCounter > 1 {
            _streamingCounter -= 1
        } else {
            _streamingCounter = 0
        }
    }
}
