//
//  GameViewModel.swift
//  
//  
//  Created by fuziki on 2023/05/08
//  
//

import AVFoundation
import CoreMediaIO
import Foundation
import Metal
import MetalKit

public class GameViewModel {
    private var streamQueue: CMSimpleQueue?
    private var isStreaming: Bool = false
    private var shouldEnqueue: Bool = false

    let sbf = SampleBufferVideoFactory(width: 1920, height: 1080)
    
    public init() {
        guard let cd = getCaptureDevice(name: "SampleCapture (Swift)") else {
            print("no capture device")
            return
        }
        let deviceIDs = CoreMediaIOUtil.getDeviceIDs()
        if deviceIDs.isEmpty {
            print("deviceIDs is empty")
            return
        }
        print("deviceIDs: \(deviceIDs)")
        guard let deviceID = deviceIDs
            .first(where: { CoreMediaIOUtil.getDeviceUID(deviceID: $0) == cd.uniqueID }) else {
            print("no math deviceID")
            return
        }
        print("deviceID: \(deviceID)")
        let streams = CoreMediaIOUtil.getStreams(deviceID: deviceID)
        if streams.count < 2 {
            print("Streams is less than expected")
            return
        }
        startStream(deviceID: deviceID, streamID: streams[1])
    }
    
    public func onRender(texture: MTLTexture) {
        print("texture: \(texture.width) x \(texture.height)")
        if !(isStreaming && shouldEnqueue) { return }
        guard let streamQueue else { return }
        
        let time = CMClockGetTime(CMClockGetHostTimeClock())
        guard let buffer = sbf.make(mtlTexture: texture, time: time) else { return }
        
        // enqueue
        print("enqueue")
        CMSimpleQueueEnqueue(streamQueue, element: Unmanaged.passRetained(buffer).toOpaque())
        
        shouldEnqueue = false
    }
    
    private func getCaptureDevice(name: String) -> AVCaptureDevice? {
        print("get capture device name:",name)
        return AVCaptureDevice
            .DiscoverySession(deviceTypes: [.externalUnknown],
                              mediaType: .video,
                              position: .unspecified)
            .devices
            .first { $0.localizedName == name }
    }
    
    private func startStream(deviceID: CMIODeviceID, streamID: CMIOStreamID) {
        let proc: CMIODeviceStreamQueueAlteredProc = { (streamID: CMIOStreamID,
                                                        token: UnsafeMutableRawPointer?,
                                                        refCon: UnsafeMutableRawPointer?) in
            print("proc streamID: \(streamID), token: \(String(describing: token)), refCon: \(String(describing: refCon))")
            guard let refCon else { return }
            let con = Unmanaged<GameViewModel>.fromOpaque(refCon).takeUnretainedValue()
            con.alteredProc()
        }
        let refCon = Unmanaged.passUnretained(self).toOpaque()
        streamQueue = CoreMediaIOUtil.startStream(deviceID: deviceID, streamID: streamID, proc: proc, refCon: refCon)
        print("streamQueue: \(String(describing: streamQueue))")
        isStreaming = true
        shouldEnqueue = true
    }
    
    private func stopStream(device: CMIODeviceID, stream: CMIOStreamID) {
        let res = CMIODeviceStopStream(device, stream)
        if res != noErr {
            print("failed CMIOStreamCopyBufferQueue")
            return
        }
        isStreaming = false
        shouldEnqueue = false
    }
    
    private func alteredProc() {
        if !isStreaming { return }
        shouldEnqueue = true
    }
}
