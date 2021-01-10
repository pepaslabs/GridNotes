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


// The below code was adapted from https://rollout.io/blog/building-a-midi-music-app-for-ios-in-swift/

var graph: AUGraph?
var synthNode: AUNode = AUNode()
var outputNode: AUNode = AUNode()
var synthUnit: AudioUnit?

func initAudio() {
    // Allow audio output even when silent switch engaged.
    try? AVAudioSession.sharedInstance().setCategory(.playback)
    
    var ret: OSStatus
    
    ret = NewAUGraph(&graph)
    precondition(ret == kAudioServicesNoError)

    var desc = AudioComponentDescription(
        componentType: OSType(kAudioUnitType_Output),
        componentSubType: OSType(kAudioUnitSubType_RemoteIO),
        componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
        componentFlags: 0,
        componentFlagsMask: 0
    )
    ret = AUGraphAddNode(graph!, &desc, &outputNode)
    precondition(ret == kAudioServicesNoError)

    desc = AudioComponentDescription(
        componentType: OSType(kAudioUnitType_MusicDevice),
        componentSubType: OSType(kAudioUnitSubType_MIDISynth),
        componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
        componentFlags: 0,
        componentFlagsMask: 0
    )
    ret = AUGraphAddNode(graph!, &desc, &synthNode)
    precondition(ret == kAudioServicesNoError)

    ret = AUGraphOpen(graph!)
    precondition(ret == kAudioServicesNoError)

    ret = AUGraphNodeInfo(graph!, synthNode, nil, &synthUnit)
    precondition(ret == kAudioServicesNoError)
    
    let synthOutElement: AudioUnitElement = 0
    let ioInputElement: AudioUnitElement = 0
    ret = AUGraphConnectNodeInput(graph!, synthNode, synthOutElement, outputNode, ioInputElement)
    precondition(ret == kAudioServicesNoError)
    
    ret = AUGraphInitialize(graph!)
    precondition(ret == kAudioServicesNoError)

    ret = AUGraphStart(graph!)
    precondition(ret == kAudioServicesNoError)
    
    // load a sound font.
    var soundFont: URL = Bundle.main.url(forResource: "Rhodes EP", withExtension: "sf2")!
    ret = AudioUnitSetProperty(
        synthUnit!,
        AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
        AudioUnitScope(kAudioUnitScope_Global),
        0,
        &soundFont,
        UInt32(MemoryLayout<URL>.size)
    )
    precondition(ret == kAudioServicesNoError)

    // load a patch.
    let channel: UInt32 = 0
    var disabled: UInt32 = 0
    var enabled: UInt32 = 1
    let patch: UInt32 = 0
    
    ret = AudioUnitSetProperty(
      synthUnit!,
      AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
      AudioUnitScope(kAudioUnitScope_Global),
      0,
      &enabled,
      UInt32(MemoryLayout<UInt32>.size)
    )
    precondition(ret == kAudioServicesNoError)

    let command = UInt32(MIDICommand.patchChange | channel)
    ret = MusicDeviceMIDIEvent(
        synthUnit!,
        command,
        patch,
        0,
        0
    )
    precondition(ret == kAudioServicesNoError)

    ret = AudioUnitSetProperty(
      synthUnit!,
      AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
      AudioUnitScope(kAudioUnitScope_Global),
      0,
      &disabled,
      UInt32(MemoryLayout<UInt32>.size)
    )
    precondition(ret == kAudioServicesNoError)

    ret = MusicDeviceMIDIEvent(synthUnit!, command, patch, 0, 0)
    precondition(ret == kAudioServicesNoError)
}

func startNote(note: UInt8) {
    print("startNote \(note)")
    var ret: OSStatus
    let channel: UInt32 = 0
    let command: UInt32 = (MIDICommand.noteOn | channel)
    let base: UInt8 = note
    let octave: UInt32 = 0
    let pitch: UInt32 = UInt32(base) + (octave * 12)
    let velocity: UInt32 = 128
    ret = MusicDeviceMIDIEvent(synthUnit!, command, pitch, velocity, 0)
    precondition(ret == kAudioServicesNoError)
}

func endNote(note: UInt8) {
    print("endNote \(note)")
    var ret: OSStatus
    let channel: UInt32 = 0
    let command: UInt32 = (MIDICommand.noteOff | channel)
    let base: UInt8 = note
    let octave: UInt32 = 0
    let pitch: UInt32 = UInt32(base) + (octave * 12)
    ret = MusicDeviceMIDIEvent(synthUnit!, command, pitch, 0, 0)
    precondition(ret == kAudioServicesNoError)
}
