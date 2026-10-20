import CLibLC3
import Foundation

public final class LC3FrameEncoder {
    public let configuration: LC3Configuration
    public let samplesPerFrame: Int

    private let encoderMemory: UnsafeMutableRawPointer
    private let encoderMemorySize: Int
    private var encoderHandle: lc3_bridge_encoder_t

    public init(configuration: LC3Configuration = .init()) throws {
        guard configuration.channels == 1 else {
            throw LC3CodecError.unsupportedChannelCount(configuration.channels)
        }
        guard (20...400).contains(configuration.expectedBytesPerFrame) else {
            throw LC3CodecError.invalidConfiguration(
                "expectedBytesPerFrame=\(configuration.expectedBytesPerFrame) is outside the LC3 range 20...400"
            )
        }

        let pcmSampleRate = configuration.resolvedPcmSampleRate
        let encoderSize = Int(
            lc3_bridge_encoder_size(Int32(configuration.frameDurationMicros), Int32(pcmSampleRate))
        )
        guard encoderSize > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "encoder size is zero for frameDurationMicros=\(configuration.frameDurationMicros), pcmSampleRate=\(pcmSampleRate)"
            )
        }

        let frameSamples = lc3_bridge_frame_samples(
            Int32(configuration.frameDurationMicros), Int32(pcmSampleRate)
        )
        guard frameSamples > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "invalid frame sample count for frameDurationMicros=\(configuration.frameDurationMicros), pcmSampleRate=\(pcmSampleRate)"
            )
        }

        let memory = UnsafeMutableRawPointer.allocate(
            byteCount: encoderSize,
            alignment: MemoryLayout<UnsafeRawPointer>.alignment
        )
        guard let encoder = lc3_bridge_setup_encoder(
            Int32(configuration.frameDurationMicros),
            Int32(configuration.sampleRate),
            Int32(pcmSampleRate),
            memory
        ) else {
            memory.deallocate()
            throw LC3CodecError.encoderInitializationFailed
        }

        self.configuration = configuration
        self.samplesPerFrame = Int(frameSamples)
        self.encoderMemory = memory
        self.encoderMemorySize = encoderSize
        self.encoderHandle = encoder
    }

    deinit {
        encoderMemory.deallocate()
    }

    public func encodeS16(samples: [Int16]) throws -> Data {
        guard samples.count == samplesPerFrame else {
            throw LC3CodecError.invalidSampleCount(expected: samplesPerFrame, actual: samples.count)
        }

        let frameBytes = configuration.expectedBytesPerFrame
        var frame = [UInt8](repeating: 0, count: frameBytes)
        let status = samples.withUnsafeBufferPointer { pcmBuffer in
            frame.withUnsafeMutableBufferPointer { frameBuffer in
                lc3_bridge_encode_s16(
                    encoderHandle,
                    pcmBuffer.baseAddress,
                    1,
                    Int32(frameBytes),
                    frameBuffer.baseAddress
                )
            }
        }
        guard status == 0 else {
            throw LC3CodecError.encodeFailed(status: status)
        }
        return Data(frame)
    }

    public func reset() throws {
        guard let encoder = lc3_bridge_reset_encoder(
            Int32(configuration.frameDurationMicros),
            Int32(configuration.sampleRate),
            Int32(configuration.resolvedPcmSampleRate),
            encoderMemory
        ) else {
            throw LC3CodecError.resetFailed
        }
        encoderHandle = encoder
    }

    public var encoderStateBytes: Int {
        encoderMemorySize
    }
}
