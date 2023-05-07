//
//  SampleBufferProvider.swift
//  CameraExCameraExtension
//  
//  Created by fuziki on 2023/05/07
//  
//

import CoreMedia
import Foundation
import os.log

private let kWhiteStripeHeight: Int = 10

class SampleBufferProvider {
    var onBuffer: ((_ buffer: CMSampleBuffer, _ hostTimeInNanoseconds: UInt64) -> Void)?

    private var _whiteStripeStartRow: UInt32 = 0
    private var _whiteStripeIsAscending: Bool = false

    private var _bufferPool: CVPixelBufferPool!
    private var _bufferAuxAttributes: NSDictionary!

    private var _timer: DispatchSourceTimer?
    private let _timerQueue = DispatchQueue(label: "timerQueue",
                                            qos: .userInteractive,
                                            attributes: [],
                                            autoreleaseFrequency: .workItem,
                                            target: .global(qos: .userInteractive))

    private let _videoDescription: CMFormatDescription
    init(videoDescription: CMFormatDescription) {
        _videoDescription = videoDescription

        let pixelBufferAttributes: NSDictionary = [
            kCVPixelBufferWidthKey: kWidth,
            kCVPixelBufferHeightKey: kHeight,
            kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary
        ]
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)

        _bufferAuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey: 5]
    }

    func start() {
        guard let _ = _bufferPool else {
            return
        }

        _timer = DispatchSource.makeTimerSource(flags: .strict, queue: _timerQueue)
        _timer!.schedule(deadline: .now(), repeating: 1.0 / Double(kFrameRate), leeway: .seconds(0))

        _timer!.setEventHandler { [weak self] in
            guard let self else { return }

            var err: OSStatus = 0
            let now = CMClockGetTime(CMClockGetHostTimeClock())

            var pixelBuffer: CVPixelBuffer?
            err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault,
                                                                      _bufferPool,
                                                                      _bufferAuxAttributes,
                                                                      &pixelBuffer)
            if err != 0 {
                os_log(.error, "out of pixel buffers \(err)")
            }

            if let pixelBuffer = pixelBuffer {

                CVPixelBufferLockBaseAddress(pixelBuffer, [])

                var bufferPtr = CVPixelBufferGetBaseAddress(pixelBuffer)!
                let width = CVPixelBufferGetWidth(pixelBuffer)
                let height = CVPixelBufferGetHeight(pixelBuffer)
                let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
                memset(bufferPtr, 0, rowBytes * height)

                let whiteStripeStartRow = _whiteStripeStartRow
                if _whiteStripeIsAscending {
                    _whiteStripeStartRow = whiteStripeStartRow - 1
                    _whiteStripeIsAscending = _whiteStripeStartRow > 0
                }
                else {
                    _whiteStripeStartRow = whiteStripeStartRow + 1
                    _whiteStripeIsAscending = _whiteStripeStartRow >= (height - kWhiteStripeHeight)
                }
                bufferPtr += rowBytes * Int(whiteStripeStartRow)
                for _ in 0..<kWhiteStripeHeight {
                    for _ in 0..<width {
                        var white: UInt32 = 0xFFFFFFFF
                        memcpy(bufferPtr, &white, MemoryLayout.size(ofValue: white))
                        bufferPtr += MemoryLayout.size(ofValue: white)
                    }
                }

                CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

                var sbuf: CMSampleBuffer!
                var timingInfo = CMSampleTimingInfo()
                timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer,
                                                         dataReady: true,
                                                         makeDataReadyCallback: nil,
                                                         refcon: nil,
                                                         formatDescription: _videoDescription,
                                                         sampleTiming: &timingInfo,
                                                         sampleBufferOut: &sbuf)
                if err == 0 {
                    onBuffer?(sbuf, UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                }
                os_log("video time \(timingInfo.presentationTimeStamp.seconds) now \(now.seconds) err \(err)")
            }
        }

        _timer!.setCancelHandler {
        }

        _timer!.resume()
    }

    func stop() {
        if let timer = _timer {
            timer.cancel()
            _timer = nil
        }
    }
}
