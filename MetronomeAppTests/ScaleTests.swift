import Testing
@testable import MetronomeApp

struct ScaleTests {

    // MARK: – DroneInterval semitones

    @Test func fixedIntervalsUnaffectedByScale() {
        for mode in ScaleMode.allCases {
            #expect(DroneInterval.root.semitones(for: mode)   == 0)
            #expect(DroneInterval.fourth.semitones(for: mode) == 5)
            #expect(DroneInterval.fifth.semitones(for: mode)  == 7)
        }
    }

    @Test func thirdIsMajorForMajorAndRoot() {
        for mode in [ScaleMode.major, .root] {
            #expect(DroneInterval.third.semitones(for: mode) == 4,
                    "\(mode.rawValue) should yield major third (4 semitones)")
        }
    }

    @Test func thirdIsMinorForMinor() {
        #expect(DroneInterval.third.semitones(for: .minor) == 3)
    }

    @Test func seventhIsMajorForMajorAndRoot() {
        for mode in [ScaleMode.major, .root] {
            #expect(DroneInterval.seventh.semitones(for: mode) == 11,
                    "\(mode.rawValue) should yield major seventh (11 semitones)")
        }
    }

    @Test func seventhIsMinorForMinor() {
        #expect(DroneInterval.seventh.semitones(for: .minor) == 10)
    }

    // MARK: – DroneConfiguration interval toggle

    @Test func toggleAddsAndRemovesInterval() {
        var config = DroneConfiguration()
        config.activeIntervals = [.root]

        config.toggle(.fifth)
        #expect(config.activeIntervals.contains(.fifth))

        config.toggle(.fifth)
        #expect(!config.activeIntervals.contains(.fifth))
    }

    @Test func toggleCannotRemoveLastInterval() {
        var config = DroneConfiguration()
        config.activeIntervals = [.root]

        config.toggle(.root)
        #expect(config.activeIntervals == [.root])
    }

    // MARK: – MusicalKey

    @Test func musicalKeySemitoneOffsets() {
        #expect(MusicalKey.c.semitoneOffset     == 0)
        #expect(MusicalKey.cSharp.semitoneOffset == 1)
        #expect(MusicalKey.a.semitoneOffset     == 9)
        #expect(MusicalKey.b.semitoneOffset     == 11)
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

    @Test func onlyThreeScaleModesAvailable() {
        #expect(ScaleMode.allCases.count == 3)
    }
}
