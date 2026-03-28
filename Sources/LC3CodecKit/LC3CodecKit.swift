import CLibLC3
import Foundation

public struct LC3Configuration: Sendable {
    public let frameDurationMicros: Int
    public let sampleRate: Int
    public let pcmSampleRate: Int
    public let channels: Int
    public let expectedBytesPerFrame: Int

    public init(
        frameDurationMicros: Int = 10_000,
        sampleRate: Int = 16_000,
        pcmSampleRate: Int = 0,
        channels: Int = 1,
        expectedBytesPerFrame: Int = 40
    ) {
        self.frameDurationMicros = frameDurationMicros
        self.sampleRate = sampleRate
        self.pcmSampleRate = pcmSampleRate
        self.channels = channels
        self.expectedBytesPerFrame = expectedBytesPerFrame
    }

    var resolvedPcmSampleRate: Int {
        pcmSampleRate == 0 ? sampleRate : pcmSampleRate
    }
}

public enum LC3CodecError: LocalizedError {
    case invalidConfiguration(String)
    case unsupportedChannelCount(Int)
    case decoderInitializationFailed
    case invalidFrameSize(expected: Int, actual: Int)
    case decodeFailed(status: Int32)
    case resetFailed

    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(reason):
            return "Invalid LC3 configuration: \(reason)"
        case let .unsupportedChannelCount(count):
            return "Unsupported channel count \(count). Only mono decoding is currently supported."
        case .decoderInitializationFailed:
            return "Failed to initialize LC3 decoder"
        case let .invalidFrameSize(expected, actual):
            return "Invalid LC3 frame size \(actual), expected \(expected)"
        case let .decodeFailed(status):
            return "LC3 decode failed with status \(status)"
        case .resetFailed:
            return "Failed to reset LC3 decoder"
        }
    }
}

public enum LC3 {
    public static func frameSamples(frameDurationMicros: Int, sampleRate: Int) throws -> Int {
        let value = lc3_bridge_frame_samples(Int32(frameDurationMicros), Int32(sampleRate))
        guard value > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "frameDurationMicros=\(frameDurationMicros), sampleRate=\(sampleRate)"
            )
        }
        return Int(value)
    }

    public static func frameBytes(frameDurationMicros: Int, bitrate: Int) throws -> Int {
        let value = lc3_bridge_frame_bytes(Int32(frameDurationMicros), Int32(bitrate))
        guard value > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "frameDurationMicros=\(frameDurationMicros), bitrate=\(bitrate)"
            )
        }
        return Int(value)
    }

    public static func resolveBitrate(frameDurationMicros: Int, frameBytes: Int) throws -> Int {
        let value = lc3_bridge_resolve_bitrate(Int32(frameDurationMicros), Int32(frameBytes))
        guard value > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "frameDurationMicros=\(frameDurationMicros), frameBytes=\(frameBytes)"
            )
        }
        return Int(value)
    }
}

public final class LC3FrameDecoder: @unchecked Sendable {
    public let configuration: LC3Configuration
    public let samplesPerFrame: Int

    private let decoderMemory: UnsafeMutableRawPointer
    private let decoderMemorySize: Int
    private var decoderHandle: lc3_bridge_decoder_t

    public init(configuration: LC3Configuration = .init()) throws {
        if configuration.channels != 1 {
            throw LC3CodecError.unsupportedChannelCount(configuration.channels)
        }

        let decodedSampleRate = configuration.resolvedPcmSampleRate
        let decoderSize = Int(
            lc3_bridge_decoder_size(Int32(configuration.frameDurationMicros), Int32(decodedSampleRate))
        )
        guard decoderSize > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "decoder size is zero for frameDurationMicros=\(configuration.frameDurationMicros), sampleRate=\(decodedSampleRate)"
            )
        }

        let frameSamples = lc3_bridge_frame_samples(
            Int32(configuration.frameDurationMicros),
            Int32(decodedSampleRate)
        )
        guard frameSamples > 0 else {
            throw LC3CodecError.invalidConfiguration(
                "invalid frame sample count for frameDurationMicros=\(configuration.frameDurationMicros), sampleRate=\(decodedSampleRate)"
            )
        }

        let memory = UnsafeMutableRawPointer.allocate(
            byteCount: decoderSize,
            alignment: MemoryLayout<UnsafeRawPointer>.alignment
        )

        guard let decoder = lc3_bridge_setup_decoder(
            Int32(configuration.frameDurationMicros),
            Int32(configuration.sampleRate),
            Int32(decodedSampleRate),
            memory
        ) else {
            memory.deallocate()
            throw LC3CodecError.decoderInitializationFailed
        }

        self.configuration = configuration
        self.samplesPerFrame = Int(frameSamples)
        self.decoderMemory = memory
        self.decoderMemorySize = decoderSize
        self.decoderHandle = decoder
    }

    deinit {
        decoderMemory.deallocate()
    }

    public func decodeS16(frame: Data) throws -> [Int16] {
        if frame.count != configuration.expectedBytesPerFrame {
            throw LC3CodecError.invalidFrameSize(
                expected: configuration.expectedBytesPerFrame,
                actual: frame.count
            )
        }

        var output = Array(repeating: Int16(0), count: samplesPerFrame)

        let status = frame.withUnsafeBytes { inputBuffer in
            output.withUnsafeMutableBufferPointer { outputBuffer in
                lc3_bridge_decode_s16(
                    decoderHandle,
                    inputBuffer.baseAddress,
                    Int32(frame.count),
                    outputBuffer.baseAddress,
                    1
                )
            }
        }

        guard status >= 0 else {
            throw LC3CodecError.decodeFailed(status: status)
        }

        return output
    }

    public func decodePacketLossConcealmentS16() throws -> [Int16] {
        var output = Array(repeating: Int16(0), count: samplesPerFrame)
        let status = output.withUnsafeMutableBufferPointer { outputBuffer in
            lc3_bridge_decode_s16(
                decoderHandle,
                nil,
                0,
                outputBuffer.baseAddress,
                1
            )
        }

        guard status >= 0 else {
            throw LC3CodecError.decodeFailed(status: status)
        }

        return output
    }

    public func reset() throws {
        guard let decoder = lc3_bridge_reset_decoder(
            Int32(configuration.frameDurationMicros),
            Int32(configuration.sampleRate),
            Int32(configuration.resolvedPcmSampleRate),
            decoderMemory
        ) else {
            throw LC3CodecError.resetFailed
        }
        decoderHandle = decoder
    }

    public var decoderStateBytes: Int {
        decoderMemorySize
    }
}
