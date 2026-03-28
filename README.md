# LC3CodecKit

A Swift package for decoding [LC3 (Low Complexity Communication Codec)](https://www.bluetooth.com/specifications/specs/low-complexity-communication-codec/) audio frames. LC3 is the standard audio codec for Bluetooth LE Audio.

## Features

- Decode LC3 frames to 16-bit PCM audio
- Packet loss concealment (PLC) for dropped frames
- Configurable frame duration, sample rate, and bitrate
- ARM NEON SIMD optimizations
- Swift 6 concurrency safe

## Requirements

- Swift 6.2+
- iOS 16+ / macOS 13+ / watchOS 9+ / tvOS 16+ / visionOS 1+

## Installation

Add LC3CodecKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ericlewis/LC3CodecKit.git", from: "1.0.0")
]
```

Then add it as a dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["LC3CodecKit"]
)
```

## Usage

### Decoding LC3 Frames

```swift
import LC3CodecKit

// Create a decoder with default configuration (16kHz, 10ms frames, 40 bytes/frame)
let decoder = try LC3FrameDecoder()

// Decode an LC3 frame to PCM samples
let samples: [Int16] = try decoder.decodeS16(frame: lc3FrameData)

// Handle packet loss with concealment
let concealedSamples = try decoder.decodePacketLossConcealmentS16()
```

### Custom Configuration

```swift
let config = LC3Configuration(
    frameDurationMicros: 10_000,  // 10ms
    sampleRate: 48_000,           // 48kHz
    pcmSampleRate: 0,             // 0 = same as sampleRate
    channels: 1,                  // mono only
    expectedBytesPerFrame: 120
)

let decoder = try LC3FrameDecoder(configuration: config)
```

### Utility Functions

```swift
// Calculate samples per frame
let samples = try LC3.frameSamples(frameDurationMicros: 10_000, sampleRate: 16_000) // 160

// Calculate frame bytes for a bitrate
let bytes = try LC3.frameBytes(frameDurationMicros: 10_000, bitrate: 32_000) // 40

// Resolve bitrate from frame size
let bitrate = try LC3.resolveBitrate(frameDurationMicros: 10_000, frameBytes: 40) // 32000
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).

The bundled LC3 C implementation is from [Google's liblc3](https://github.com/google/liblc3).
