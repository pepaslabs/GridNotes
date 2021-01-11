//
//  Note.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/11/21.
//

import Foundation


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
        return [.two, .three, .four, .five, .six]
    }
    
    static var octavesForPad: [Octave] {
        return [.one, .two, .three, .four, .five, .six, .seven]
    }
}


struct AbsoluteNote {
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
