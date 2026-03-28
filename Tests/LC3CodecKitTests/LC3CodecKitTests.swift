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
}
