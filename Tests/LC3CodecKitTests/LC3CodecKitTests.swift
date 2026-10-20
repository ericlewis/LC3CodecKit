import XCTest
@testable import LC3CodecKit

final class LC3CodecKitTests: XCTestCase {
    func testFrameUtilityFunctions() throws {
        XCTAssertEqual(try LC3.frameSamples(frameDurationMicros: 10_000, sampleRate: 16_000), 160)
        XCTAssertEqual(try LC3.frameBytes(frameDurationMicros: 10_000, bitrate: 32_000), 40)
        XCTAssertEqual(try LC3.resolveBitrate(frameDurationMicros: 10_000, frameBytes: 40), 32_000)
    }

    func testDecoderRejectsInvalidFrameSize() throws {
        let decoder = try LC3FrameDecoder()
        XCTAssertThrowsError(try decoder.decodeS16(frame: Data(count: 20)))
    }

    func testDecoderHandlesSilentFrame() throws {
        let decoder = try LC3FrameDecoder()
        let samples = try decoder.decodeS16(frame: Data(repeating: 0, count: 40))
        XCTAssertEqual(samples.count, 160)
    }

    func testThirtyByteMonoFramesEncodeAndDecode() throws {
        let configuration = LC3Configuration(expectedBytesPerFrame: 30)
        let encoder = try LC3FrameEncoder(configuration: configuration)
        let decoder = try LC3FrameDecoder(configuration: configuration)
        XCTAssertEqual(encoder.samplesPerFrame, 160)

        var decoded = [Int16]()
        for frameIndex in 0..<6 {
            let samples = (0..<160).map { sampleIndex in
                Int16(6_000 * sin(2 * .pi * 440 * Double(frameIndex * 160 + sampleIndex) / 16_000))
            }
            let frame = try encoder.encodeS16(samples: samples)
            XCTAssertEqual(frame.count, 30)
            decoded = try decoder.decodeS16(frame: frame)
        }

        XCTAssertEqual(decoded.count, 160)
        XCTAssertTrue(decoded.contains { abs(Int($0)) > 500 }, "decoded PCM should contain the encoded tone")
    }

    func testEncoderRejectsIncorrectPCMFrameLength() throws {
        let encoder = try LC3FrameEncoder(configuration: .init(expectedBytesPerFrame: 30))
        XCTAssertThrowsError(try encoder.encodeS16(samples: [Int16](repeating: 0, count: 159))) { error in
            guard case LC3CodecError.invalidSampleCount(expected: 160, actual: 159) = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testEncoderRejectsUnsupportedCompressedFrameSize() {
        XCTAssertThrowsError(try LC3FrameEncoder(configuration: .init(expectedBytesPerFrame: 19)))
    }

    func testEncoderResetReproducesInitialFrame() throws {
        let encoder = try LC3FrameEncoder(configuration: .init(expectedBytesPerFrame: 30))
        let samples = (0..<160).map { sampleIndex in
            Int16(6_000 * sin(2 * .pi * 440 * Double(sampleIndex) / 16_000))
        }

        let firstFrame = try encoder.encodeS16(samples: samples)
        _ = try encoder.encodeS16(samples: samples)
        try encoder.reset()
        XCTAssertEqual(try encoder.encodeS16(samples: samples), firstFrame)
    }
}
