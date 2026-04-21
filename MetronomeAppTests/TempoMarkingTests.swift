import Testing
@testable import MetronomeApp

struct TempoMarkingTests {

    @Test func correctMarkingForTypicalValues() {
        #expect(TempoMarking(bpm: BPM(rawValue: 60))  == .larghetto)
        #expect(TempoMarking(bpm: BPM(rawValue: 90))  == .andante)
        #expect(TempoMarking(bpm: BPM(rawValue: 112)) == .moderato)
        #expect(TempoMarking(bpm: BPM(rawValue: 120)) == .allegretto)
        #expect(TempoMarking(bpm: BPM(rawValue: 140)) == .allegro)
        #expect(TempoMarking(bpm: BPM(rawValue: 200)) == .prestissimo)
    }

    @Test func boundaryValues() {
        // Each boundary belongs to the upper range
        #expect(TempoMarking(bpm: BPM(rawValue: 56))  == .larghetto)   // 56..<66
        #expect(TempoMarking(bpm: BPM(rawValue: 66))  == .adagio)      // 66..<76
        #expect(TempoMarking(bpm: BPM(rawValue: 76))  == .andante)     // 76..<108
        #expect(TempoMarking(bpm: BPM(rawValue: 108)) == .moderato)    // 108..<120
        #expect(TempoMarking(bpm: BPM(rawValue: 132)) == .allegro)     // 132..<168
        #expect(TempoMarking(bpm: BPM(rawValue: 176)) == .presto)     // vivace ends at 176 (exclusive); presto starts here
    }

    @Test func allCasesHaveNonOverlappingRanges() {
        // Verify that for any given BPM, exactly one marking matches
        let testBPMs: [Double] = [30, 50, 60, 70, 90, 110, 125, 145, 170, 180, 210, 300]
        for bpmVal in testBPMs {
            let matches = TempoMarking.allCases.filter { $0.bpmRange.contains(bpmVal) }
            #expect(matches.count == 1, "Expected exactly 1 match for BPM \(bpmVal), got \(matches.count)")
        }
    }

    @Test func minimumBPMIs30Larghissimo() {
        // BPM 30 is clamped minimum; larghissimo covers 0..<24 but BPM min is 30
        // so largo (24..<56) applies at 30
        #expect(TempoMarking(bpm: BPM(rawValue: 30)) == .largo)
    }
}
