import Testing
import Foundation
@testable import MetronomeApp

struct FrequencyTests {

    let config = DroneConfiguration()  // A, middle octave, 440 Hz reference

    @Test func a4Is440Hz() {
        let freq = config.frequency(for: .a, octave: .middle)
        #expect(abs(freq - 440.0) < 0.001)
    }

    @Test func a5IsOneOctaveUp() {
        let a4 = config.frequency(for: .a, octave: .middle)
        let a5 = config.frequency(for: .a, octave: .high)
        #expect(abs(a5 - a4 * 2) < 0.001)
    }

    @Test func a3IsOneOctaveDown() {
        let a4 = config.frequency(for: .a, octave: .middle)
        let a3 = config.frequency(for: .a, octave: .low)
        #expect(abs(a3 - a4 / 4) < 0.001)   // low=2, middle=4 → two octaves down
    }

    @Test func c4MajorThirdAboveA3() {
        // C4 should be ~261.63 Hz
        let c4 = config.frequency(for: .c, octave: .middle)
        #expect(abs(c4 - 261.626) < 0.01)
    }

    @Test func customReferenceA4() {
        var tuned = DroneConfiguration()
        tuned.referenceA4 = 415.0
        let freq = tuned.frequency(for: .a, octave: .middle)
        #expect(abs(freq - 415.0) < 0.001)
    }

    @Test func semitoneRatioIsCorrect() {
        // Each semitone up multiplies frequency by 2^(1/12)
        let c4 = config.frequency(for: .c, octave: .middle)
        let cSharp4 = config.frequency(for: .cSharp, octave: .middle)
        let ratio = cSharp4 / c4
        #expect(abs(ratio - pow(2.0, 1.0/12.0)) < 0.0001)
    }

    @Test func referenceRangeBounds() {
        #expect(DroneConfiguration.referenceRange.lowerBound == 415)
        #expect(DroneConfiguration.referenceRange.upperBound == 446)
    }
}
