import Testing
@testable import MetronomeApp

struct AccentPatternTests {

    @Test func defaultPatternBeatCountMatchesTimeSignature() {
        for ts in TimeSignature.allCases {
            let pattern = AccentPattern.defaultPattern(for: ts)
            #expect(pattern.beats.count == ts.beatCount,
                    "\(ts.rawValue): expected \(ts.beatCount) beats")
        }
    }

    @Test func defaultPatternFirstBeatIsStrong() {
        for ts in TimeSignature.allCases {
            let pattern = AccentPattern.defaultPattern(for: ts)
            #expect(pattern.beats[0] == .strong,
                    "\(ts.rawValue): first beat should be .strong")
        }
    }

    @Test func defaultPatternRemainingBeatsAreMedium() {
        for ts in TimeSignature.allCases {
            let pattern = AccentPattern.defaultPattern(for: ts)
            for i in 1..<pattern.beats.count {
                #expect(pattern.beats[i] == .medium)
            }
        }
    }

    @Test func accentLevelAmplitudes() {
        #expect(AccentLevel.off.amplitude    == 0.0)
        #expect(AccentLevel.weak.amplitude   == 0.4)
        #expect(AccentLevel.medium.amplitude == 0.7)
        #expect(AccentLevel.strong.amplitude == 1.0)
    }

    @Test func accentLevelRawValues() {
        #expect(AccentLevel.off.rawValue    == 0)
        #expect(AccentLevel.weak.rawValue   == 1)
        #expect(AccentLevel.medium.rawValue == 2)
        #expect(AccentLevel.strong.rawValue == 3)
    }

    @Test func patternEquality() {
        let p1 = AccentPattern(beats: [.strong, .medium, .weak], name: "Test")
        let p2 = AccentPattern(beats: [.strong, .medium, .weak], name: "Test")
        let p3 = AccentPattern(beats: [.strong, .weak, .medium], name: "Test")
        #expect(p1 == p2)
        #expect(p1 != p3)
    }
}
