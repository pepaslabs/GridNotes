//
//  Note.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/11/21.
//

import UIKit


/// The core data structure of the app.
struct AppState {
    var interface: Interface = .gridNotes
    var tonicNote: Note = .C
    var scale: Scale = .major
    var octaves: [Octave]
    var keysPerOctave: KeysPerOctave
    var nonScaleStyle: NonDiatonicKeyStyle = .disabled
    var stickyMode: Bool = false
    var stuckKeys: Set<AbsoluteNote> = []
    var chordMode: Bool = false

    var explicitlyPlayedNotes: Set<AbsoluteNote> = []
//    var implicitlyPlayedNotes: Set<AbsoluteNote> = []

//    func implicitlyPlayedNotes(forChordRoots roots: Set<AbsoluteNote>) -> Set<AbsoluteNote> {
//        var notes = Set<AbsoluteNote>()
//        for root in roots {
//            notes.insert(root)
//        }
//        return notes
//    }
    
    static var defaultState: AppState {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return AppState(
                octaves: Octave.octavesForPhone,
                keysPerOctave: .diatonicKeys
            )
        case .pad:
            return AppState(
                octaves: Octave.octavesForPad,
                keysPerOctave: .chromaticKeys
            )
        default:
            fatalError()
        }
    }
}


/// Which piano layout to use.
enum Interface: String, CaseIterable {
    case gridNotes = "Grid (Notes)"
    case ringNotes = "Ring (Notes)"
    case gridChords = "Grid (Chords)"

    var displayName: String {
        return rawValue
    }
}


/// A 12TET musical pitch.
enum Note: String, CaseIterable {
    case A = "A"
    case AsBb = "A♯/B♭"
    case B = "B"
    case C = "C"
    case CsDb = "C♯/D♭"
    case D = "D"
    case DsEb = "D♯/E♭"
    case E = "E"
    case F = "F"
    case FsGb = "F♯/G♭"
    case G = "G"
    case GsAb = "G♯/A♭"

    var displayName: String {
        return rawValue
    }

    var index: Int {
        return Note.allCases.firstIndex(of: self)!
    }
    
    var next: Note {
        let currentIndex = Note.allCases.firstIndex(of: self)!
        let nextIndex = (currentIndex + 1) % Note.allCases.count
        return Note.allCases[nextIndex]
    }
    
    /// False for sharps and flats.
    var isNaturalNote: Bool {
        switch self {
        case .A, .B, .C, .D, .E, .F, .G:
            return true
        default:
            return false
        }
    }

    static var noteNames: [String] {
        return Note.allCases.map { $0.displayName }
    }
    
    /// All 12 notes in an octave.
    static func chromaticScale(from startingNote: Note) -> [Note] {
        var note: Note = startingNote
        var notes: [Note] = []
        for _ in 0..<12 {
            notes.append(note)
            note = note.next
        }
        return notes
    }
}


enum Octave: Int {
    case zero = 0
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    
    var next: Octave? {
        switch self {
        case .eight:
            return nil
        default:
            return Octave(rawValue: rawValue+1)
        }
    }
    
    static var octavesForPhone: [Octave] {
        // On iPhone, we only have room for 5 octaves.
        return [.two, .three, .four, .five, .six]
    }
    
    static var octavesForPad: [Octave] {
        // On iPhone, we have room for 7 octaves.
        return [.one, .two, .three, .four, .five, .six, .seven]
    }
}


/// A note and an octave, e.g. "C4".
struct AbsoluteNote: Hashable {
    var note: Note
    var octave: Octave
    
    var displayName: String {
        switch note {
        case .A, .B, .C, .D, .E, .F, .G:
            return "\(note.rawValue)\(octave.rawValue)"
        case .AsBb:
            return "A\(octave.rawValue)♯/B\(octave.rawValue)♭"
        case .CsDb:
            return "C\(octave.rawValue)♯/D\(octave.rawValue)♭"
        case .DsEb:
            return "D\(octave.rawValue)♯/E\(octave.rawValue)♭"
        case .FsGb:
            return "F\(octave.rawValue)♯/G\(octave.rawValue)♭"
        case .GsAb:
            return "G\(octave.rawValue)♯/A\(octave.rawValue)♭"
        }
    }
    
    /// The display name, but wrapped into two lines of text.
    var buttonText: String {
        switch note {
        case .A, .B, .C, .D, .E, .F, .G:
            return "\(note.rawValue)\(octave.rawValue)"
        case .AsBb:
            return "A\(octave.rawValue)♯\nB\(octave.rawValue)♭"
        case .CsDb:
            return "C\(octave.rawValue)♯\nD\(octave.rawValue)♭"
        case .DsEb:
            return "D\(octave.rawValue)♯\nE\(octave.rawValue)♭"
        case .FsGb:
            return "F\(octave.rawValue)♯\nG\(octave.rawValue)♭"
        case .GsAb:
            return "G\(octave.rawValue)♯\nA\(octave.rawValue)♭"
        }
    }
    
    /// The next chromatic note.  May be nil if it runs past the eight octave.
    var next: AbsoluteNote? {
        switch note {
        case .GsAb:
            switch octave {
            case .eight:
                return nil
            default:
                return AbsoluteNote(note: .A, octave: octave.next!)
            }
        default:
            return AbsoluteNote(note: note.next, octave: octave)
        }
    }
    
    /// All 12 notes in an octave.
    static func chromaticScale(from startingNote: AbsoluteNote) -> [AbsoluteNote?] {
        var note: AbsoluteNote? = startingNote
        var notes: [AbsoluteNote?] = []
        for _ in 0..<12 {
            notes.append(note)
            note = note?.next
        }
        return notes
    }
    
    /// The MIDI numerical index of this note.
    var midiPitch: UInt32 {
        return UInt32((note.index-3) + (octave.rawValue+1) * 12)
    }
}


enum Scale: String, CaseIterable {
    case chromatic = "Chromatic"
    case major = "Major / Ionian"
    case naturalMinor = "Natural Minor / Aeolian"
    case harmonicMinor = "Harmonic Minor"
    case melodicMinorBi = "Melodic Minor (bidirectional)"
    case melodicMinorAsc = "Melodic Minor (ascending)"
    case melodicMinorDesc = "Melodic Minor (descending)"
    case dorian = "Dorian"
    case phyrgian = "Phyrgian"
    case lydian = "Lydian"
    case mixolydian = "Mixolydian"
    case locrian = "Locrian"
    case wholeTone = "Whole Tone"
    case majorPent = "Major Pentatonic"
    case minorPent = "Minor Pentatonic"

    var displayName: String {
        return rawValue
    }
    
    var semitoneIndices: [Int] {
        switch self {
        case .chromatic:
            return [1,2,3,4,5,6,7,8,9,10,11,12].map { $0 - 1 }
        case .major:
            return [1,  3,  5,6,  8,  10,   12].map { $0 - 1 }
        case .naturalMinor:
            return [1,  3,4,  6,  8,9,   11,  ].map { $0 - 1 }
        case .harmonicMinor:
            return [1,  3,4,  6,  8,9,      12].map { $0 - 1 }
        case .melodicMinorBi:
            return [1,  3,4,  6,  8,9,10,11,12].map { $0 - 1 }
        case .melodicMinorAsc:
            return [1,  3,4,  6,  8,  10,   12].map { $0 - 1 }
        case .melodicMinorDesc:
            return [1,  3,4,  6,  8,9,   11,  ].map { $0 - 1 }
        case .dorian:
            return [1,  3,4,  6,  8,  10,11   ].map { $0 - 1 }
        case .phyrgian:
            return [1,2,  4,  6,  8,9,   11   ].map { $0 - 1 }
        case .lydian:
            return [1,  3,  5,  7,8,  10,   12].map { $0 - 1 }
        case .mixolydian:
            return [1,  3,  5,6,  8,  10,11   ].map { $0 - 1 }
        case .locrian:
            return [1,2,  4,  6,7,  9,   11   ].map { $0 - 1 }
        case .wholeTone:
            return [1,  3,  5,  7,  9,   11   ].map { $0 - 1 }
        case .majorPent:
            return [1,  3,  5,    8,  10      ].map { $0 - 1 }
        case .minorPent:
            return [1,    4,  6,  8,     11,  ].map { $0 - 1 }
        }
    }
    
    /// The (7) in-scale notes.  May include nils at the end if the sequence runs past the eight octave.
    func absoluteNotes(fromTonic tonic: AbsoluteNote, octaveCount: Int = 1) -> [AbsoluteNote?] {
        var notes: [AbsoluteNote?] = []
        var note: AbsoluteNote? = tonic
        for _ in 0..<octaveCount {
            for i in 0..<12 {
                if semitoneIndices.contains(i) {
                    notes.append(note)
                }
                note = note?.next
            }
        }
        return notes
    }

    /// The (7) notes of this scale, but with nils inserted for the non-scale notes (12 values total).
    /// May include nils at the end if the sequence runs past the eight octave.
    func sparseAbsoluteNotes(fromTonic tonic: AbsoluteNote) -> [AbsoluteNote?] {
        var notes: [AbsoluteNote?] = []
        var note: AbsoluteNote? = tonic
        for i in 0..<12 {
            if semitoneIndices.contains(i) {
                notes.append(note)
            } else {
                notes.append(nil)
            }
            note = note?.next
        }
        return notes
    }
}


enum KeysPerOctave: String, CaseIterable {
    case chromaticKeys
    case diatonicKeys
    
    var displayName: String {
        switch self {
        case .chromaticKeys:
            return "Chromatic (all 12 keys)"
        case .diatonicKeys:
            return "Diatonic (only in-scale keys)"
        }
    }
}


/// Treatment styles for the out-of-scale notes.
enum NonDiatonicKeyStyle: String, CaseIterable {
    case shaded
    case disabled
    
    var displayName: String {
        switch self {
        case .shaded:
            return "Shaded, but Enabled"
        case .disabled:
            return "Shaded and Disabled"
        }
    }
}


enum Chord {
    case I
    case II
    case III
    case IV
    case V
    case VI
    case VII

    var diatonicIndices: [Int] {
        func noteNumbers() -> [Int] {
            switch self {
            case .I:   return [1,3,5]
            case .II:  return [2,4,6]
            case .III: return [3,5,7]
            case .IV:  return [4,6,8]
            case .V:   return [5,7,9]
            case .VI:  return [6,8,10]
            case .VII: return [7,9,11]
            }
        }

        let indices = noteNumbers().map { $0 - 1 }
        return indices
    }

    /// Return the notes of this chord, for the scale starting at tonic.
    /// Does not return notes past the eight octave.
    func absoluteNotes(tonic: AbsoluteNote, scale: Scale) -> [AbsoluteNote] {
        let scaleNotes: [AbsoluteNote] = scale.absoluteNotes(fromTonic: tonic, octaveCount: 2).compactMap { $0 }
        return scaleNotes.getAt(indices: diatonicIndices)
    }
}
