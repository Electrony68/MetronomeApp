import Testing
@testable import MetronomeApp

struct ScaleTests {

    // MARK: – DroneInterval

    @Test func droneIntervalSemitonesFixed() {
        #expect(DroneInterval.none.semitones == 0)
        #expect(DroneInterval.fifth.semitones == 7)
        #expect(DroneInterval.octave.semitones == 12)
    }

    @Test func droneIntervalThirdIsMajorForMajorScales() {
        for mode in [ScaleMode.major, .mixolydian, .pentatonicMajor, .root] {
            #expect(DroneInterval.third.semitones(for: mode) == 4,
                    "\(mode.rawValue) should yield major third (4 semitones)")
        }
    }

    @Test func droneIntervalThirdIsMinorForMinorScales() {
        for mode in [ScaleMode.minor, .dorian, .pentatonicMinor] {
            #expect(DroneInterval.third.semitones(for: mode) == 3,
                    "\(mode.rawValue) should yield minor third (3 semitones)")
        }
    }

    @Test func nonThirdIntervalsUnaffectedByScale() {
        for mode in ScaleMode.allCases {
            #expect(DroneInterval.fifth.semitones(for: mode)  == 7)
            #expect(DroneInterval.octave.semitones(for: mode) == 12)
            #expect(DroneInterval.none.semitones(for: mode)   == 0)
        }
    }

    // MARK: – MusicalKey

    @Test func musicalKeySemitoneOffsets() {
        #expect(MusicalKey.c.semitoneOffset  == 0)
        #expect(MusicalKey.cSharp.semitoneOffset == 1)
        #expect(MusicalKey.a.semitoneOffset  == 9)
        #expect(MusicalKey.b.semitoneOffset  == 11)
    }

    @Test func allTwelveTonesPresent() {
        let offsets = Set(MusicalKey.allCases.map { $0.semitoneOffset })
        #expect(offsets == Set(0...11))
    }

    // MARK: – ScaleMode intervals

    @Test func majorScaleIntervals() {
        #expect(ScaleMode.major.intervals == [0, 2, 4, 5, 7, 9, 11])
    }

    @Test func minorScaleIntervals() {
        #expect(ScaleMode.minor.intervals == [0, 2, 3, 5, 7, 8, 10])
    }

    @Test func rootScaleIsSingleNote() {
        #expect(ScaleMode.root.intervals == [0])
    }

    @Test func pentatonicScalesHaveFiveNotes() {
        #expect(ScaleMode.pentatonicMajor.intervals.count == 5)
        #expect(ScaleMode.pentatonicMinor.intervals.count == 5)
    }
}
