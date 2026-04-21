import Testing
@testable import MetronomeApp

struct TimeSignatureTests {

    @Test func beatCounts() {
        #expect(TimeSignature.threeQuarter.beatCount == 3)
        #expect(TimeSignature.fourQuarter.beatCount  == 4)
        #expect(TimeSignature.fiveQuarter.beatCount  == 5)
        #expect(TimeSignature.sixEighth.beatCount    == 6)
        #expect(TimeSignature.sevenQuarter.beatCount == 7)
    }

    @Test func denominators() {
        #expect(TimeSignature.sixEighth.denominator == 8)
        for ts in [TimeSignature.threeQuarter, .fourQuarter, .fiveQuarter, .sevenQuarter] {
            #expect(ts.denominator == 4)
        }
    }

    @Test func beatMultiplierQuarterNotes() {
        for ts in [TimeSignature.threeQuarter, .fourQuarter, .fiveQuarter, .sevenQuarter] {
            #expect(ts.beatMultiplier == 1.0)
        }
    }

    @Test func beatMultiplierSixEighth() {
        // 6/8 compound metre: dotted quarter = 3 eighth notes; multiplier = 2/3
        #expect(abs(TimeSignature.sixEighth.beatMultiplier - 2.0/3.0) < 0.0001)
    }

    @Test func rawValueStrings() {
        #expect(TimeSignature.threeQuarter.rawValue  == "3/4")
        #expect(TimeSignature.fourQuarter.rawValue   == "4/4")
        #expect(TimeSignature.sixEighth.rawValue     == "6/8")
    }
}
