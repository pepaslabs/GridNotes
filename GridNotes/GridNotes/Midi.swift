//
//  Midi.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//


import AudioToolbox
import AVKit


enum MIDICommand {
    static let noteOff: UInt32 = 0x80
    static let noteOn: UInt32 = 0x90
    static let patchChange: UInt32 = 0xC0
}

enum Instrument: String, CaseIterable {
    case yamahaGrandPiano = "Yamaha Grand Piano"
    case harpsichord = "Harpsichord"
    case rhodesEP = "Rhodes EP"
    case rockOrgan = "Rock Organ"
    case churchOrgan2 = "Church Organ 2"

    case sineWave = "Sine Wave"
    case sawWave = "Saw Wave"
    case synthStrings2 = "Synth Strings 2"

    case cleanGuitar = "Clean Guitar"
    case overdriveGuitar = "Overdrive Guitar"
    case distortionGuitar = "Distortion Guitar"

    case violin = "Violin"
    case cello = "Cello"

    case trumpet = "Trumpet"
    case frenchHorns = "French Horns"

    case ohhVoices = "Ohh Voices"

    
    var filename: String {
        return rawValue
    }
    
    var displayName: String {
        switch self {
        case .rhodesEP:
            return "Rhodes"
        case .synthStrings2:
            return "Synth Strings"
        case .churchOrgan2:
            return "Church Organ"
        default:
            return rawValue
        }
    }
}

var g_instrument: Instrument = .rhodesEP


var g_graph: AUGraph?
var g_synthNode: AUNode = AUNode()
var g_outputNode: AUNode = AUNode()
var g_synthUnit: AudioUnit?


func initAudio() {
    // Allow audio output even when silent switch engaged.
    try? AVAudioSession.sharedInstance().setCategory(.playback)

    // The below code was adapted from https://rollout.io/blog/building-a-midi-music-app-for-ios-in-swift/

    var ret: OSStatus
    
    ret = NewAUGraph(&g_graph)
    precondition(ret == noErr)

    var desc = AudioComponentDescription(
        componentType: OSType(kAudioUnitType_Output),
        componentSubType: OSType(kAudioUnitSubType_RemoteIO),
        componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
        componentFlags: 0,
        componentFlagsMask: 0
    )
    ret = AUGraphAddNode(g_graph!, &desc, &g_outputNode)
    precondition(ret == noErr)

    desc = AudioComponentDescription(
        componentType: OSType(kAudioUnitType_MusicDevice),
        componentSubType: OSType(kAudioUnitSubType_MIDISynth),
        componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
        componentFlags: 0,
        componentFlagsMask: 0
    )
    ret = AUGraphAddNode(g_graph!, &desc, &g_synthNode)
    precondition(ret == noErr)

    ret = AUGraphOpen(g_graph!)
    precondition(ret == noErr)

    ret = AUGraphNodeInfo(g_graph!, g_synthNode, nil, &g_synthUnit)
    precondition(ret == noErr)
    
    let synthOutElement: AudioUnitElement = 0
    let ioInputElement: AudioUnitElement = 0
    ret = AUGraphConnectNodeInput(g_graph!, g_synthNode, synthOutElement, g_outputNode, ioInputElement)
    precondition(ret == noErr)
    
    ret = AUGraphInitialize(g_graph!)
    precondition(ret == noErr)

    ret = AUGraphStart(g_graph!)
    precondition(ret == noErr)
    
    // load a sound font.
    var soundFont: URL = Bundle.main.url(forResource: g_instrument.filename, withExtension: "sf2")!
    ret = AudioUnitSetProperty(
        g_synthUnit!,
        AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
        AudioUnitScope(kAudioUnitScope_Global),
        0,
        &soundFont,
        UInt32(MemoryLayout<URL>.size)
    )
    precondition(ret == noErr)

    // load a patch.
    let channel: UInt32 = 0
    var disabled: UInt32 = 0
    var enabled: UInt32 = 1
    let patch: UInt32 = 0
    
    ret = AudioUnitSetProperty(
      g_synthUnit!,
      AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
      AudioUnitScope(kAudioUnitScope_Global),
      0,
      &enabled,
      UInt32(MemoryLayout<UInt32>.size)
    )
    precondition(ret == noErr)

    let command = UInt32(MIDICommand.patchChange | channel)
    ret = MusicDeviceMIDIEvent(
        g_synthUnit!,
        command,
        patch,
        0,
        0
    )
    precondition(ret == noErr)

    ret = AudioUnitSetProperty(
      g_synthUnit!,
      AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
      AudioUnitScope(kAudioUnitScope_Global),
      0,
      &disabled,
      UInt32(MemoryLayout<UInt32>.size)
    )
    precondition(ret == noErr)

    ret = MusicDeviceMIDIEvent(g_synthUnit!, command, patch, 0, 0)
    precondition(ret == noErr)
}


func deinitAudio() {
    var ret: OSStatus

    ret = AUGraphStop(g_graph!)
    precondition(ret == noErr)
    ret = AUGraphRemoveNode(g_graph!, g_outputNode)
    precondition(ret == noErr)
    ret = AUGraphRemoveNode(g_graph!, g_synthNode)
    precondition(ret == noErr)
    ret = DisposeAUGraph(g_graph!)
    precondition(ret == noErr)
}


func startPlaying(absoluteNote: AbsoluteNote) {
    var ret: OSStatus
    let channel: UInt32 = 0
    let command: UInt32 = (MIDICommand.noteOn | channel)
    let velocity: UInt32 = 128
    ret = MusicDeviceMIDIEvent(g_synthUnit!, command, absoluteNote.midiPitch, velocity, 0)
    precondition(ret == noErr)
}


func stopPlaying(absoluteNote: AbsoluteNote) {
    var ret: OSStatus
    let channel: UInt32 = 0
    let command: UInt32 = (MIDICommand.noteOff | channel)
    ret = MusicDeviceMIDIEvent(g_synthUnit!, command, absoluteNote.midiPitch, 0, 0)
    precondition(ret == noErr)
}


func stopPlayingAllNotes() {
    var ret: OSStatus
    let channel: UInt32 = 0
    let command: UInt32 = (MIDICommand.noteOff | channel)
    for pitch in 0..<128 {
        ret = MusicDeviceMIDIEvent(g_synthUnit!, command, UInt32(pitch), 0, 0)
        precondition(ret == noErr)
    }
}
