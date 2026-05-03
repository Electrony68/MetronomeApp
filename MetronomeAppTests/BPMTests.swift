import Testing
@testable import MetronomeApp

struct BPMTests {

    @Test func clampsToMinimum() {
        #expect(BPM(rawValue: 10).rawValue == 30)
        #expect(BPM(rawValue: -50).rawValue == 30)
        #expect(BPM(rawValue: 30).rawValue == 30)
    }

    @Test func clampsToMaximum() {
        #expect(BPM(rawValue: 400).rawValue == 300)
        #expect(BPM(rawValue: 300).rawValue == 300)
    }

    @Test func preservesValueWithinRange() {
        #expect(BPM(rawValue: 120).rawValue == 120)
        #expect(BPM(rawValue: 60).rawValue == 60)
        #expect(BPM(rawValue: 200).rawValue == 200)
    }

    @Test func defaultIs120() {
        #expect(BPM.default.rawValue == 120)
    }

    @Test func beatDuration() {
        #expect(BPM(rawValue: 60).beatDuration == 1.0)
        #expect(BPM(rawValue: 120).beatDuration == 0.5)
        #expect(BPM(rawValue: 30).beatDuration == 2.0)
    }

    @Test func description() {
        #expect(BPM(rawValue: 120).description == "120")
        #expect(BPM(rawValue: 72.9).description == "73")
    }

    @Test func hashableAndEquatable() {
        let a = BPM(rawValue: 100)
        let b = BPM(rawValue: 100)
        let c = BPM(rawValue: 110)
        #expect(a == b)
        #expect(a != c)
        let set: Set<BPM> = [a, b, c]
        #expect(set.count == 2)
    }

    @Test func tapTempoAveragingLogic() {
        // Simulate tap tempo: 4 taps at 500ms intervals → 120 BPM
        let intervals: [Double] = [0.5, 0.5, 0.5]
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        let bpm = BPM(rawValue: 60.0 / avg)
        #expect(bpm.rawValue == 120)
    }
}
