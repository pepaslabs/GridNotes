//
//  Note.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/11/21.
//

import Foundation


enum Note: String, CaseIterable, Hashable {
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

    var index: Int {
        return Note.allCases.firstIndex(of: self)!
    }
    
    var next: Note {
        let currentIndex = Note.allCases.firstIndex(of: self)!
        let nextIndex = (currentIndex + 1) % Note.allCases.count
        return Note.allCases[nextIndex]
    }
    
    var isNaturalNote: Bool {
        switch self {
        case .A, .B, .C, .D, .E, .F, .G: return true
        default: return false
        }
    }

    var name: String {
        return rawValue
    }

    static var noteNames: [String] {
        return Note.allCases.map { $0.rawValue }
    }
    
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


enum Octave: Int, Hashable {
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
        return [.two, .three, .four, .five, .six]
    }
    
    static var octavesForPad: [Octave] {
        return [.one, .two, .three, .four, .five, .six, .seven]
    }
}


struct AbsoluteNote: Hashable {
    var note: Note
    var octave: Octave
    
    var name: String {
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
    
    static func chromaticScale(from startingNote: AbsoluteNote) -> [AbsoluteNote?] {
        var note: AbsoluteNote? = startingNote
        var notes: [AbsoluteNote?] = []
        for _ in 0..<12 {
            notes.append(note)
            note = note?.next
        }
        return notes
    }
    
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

    var name: String {
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
    
    func absoluteNotes(fromTonic tonic: AbsoluteNote) -> [AbsoluteNote?] {
        var notes: [AbsoluteNote?] = []
        var note: AbsoluteNote? = tonic
        for i in 0..<12 {
            if semitoneIndices.contains(i) {
                notes.append(note)
            }
            note = note?.next
        }
        return notes
    }
}
