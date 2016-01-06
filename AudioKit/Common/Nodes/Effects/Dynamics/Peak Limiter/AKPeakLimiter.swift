//
//  AKPeakLimiter.swift
//  AudioKit
//
//  Autogenerated by scripts by Aurelius Prochazka. Do not edit directly.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// AudioKit version of Apple's PeakLimiter Audio Unit
///
/// - parameter input: Input node to process
/// - parameter attackTime: Attack Time (Secs) ranges from 0.001 to 0.03 (Default: 0.012)
/// - parameter decayTime: Decay Time (Secs) ranges from 0.001 to 0.06 (Default: 0.024)
/// - parameter preGain: Pre Gain (dB) ranges from -40 to 40 (Default: 0)
///
public class AKPeakLimiter: AKNode, AKToggleable {

    private let cd = AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0)

    internal var internalEffect = AVAudioUnitEffect()
    internal var internalAU = AudioUnit()

    /// Required property for AKNode containing the output node
    public var avAudioNode: AVAudioNode

    /// Required property for AKNode containing all the node's connections
    public var connectionPoints = [AVAudioConnectionPoint]()

    private var mixer: AKMixer

    /// Attack Time (Secs) ranges from 0.001 to 0.03 (Default: 0.012)
    public var attackTime: Double = 0.012 {
        didSet {
            if attackTime < 0.001 {
                attackTime = 0.001
            }            
            if attackTime > 0.03 {
                attackTime = 0.03
            }
            AudioUnitSetParameter(
                internalAU,
                kLimiterParam_AttackTime,
                kAudioUnitScope_Global, 0,
                Float(attackTime), 0)
        }
    }

    /// Decay Time (Secs) ranges from 0.001 to 0.06 (Default: 0.024)
    public var decayTime: Double = 0.024 {
        didSet {
            if decayTime < 0.001 {
                decayTime = 0.001
            }            
            if decayTime > 0.06 {
                decayTime = 0.06
            }
            AudioUnitSetParameter(
                internalAU,
                kLimiterParam_DecayTime,
                kAudioUnitScope_Global, 0,
                Float(decayTime), 0)
        }
    }

    /// Pre Gain (dB) ranges from -40 to 40 (Default: 0)
    public var preGain: Double = 0 {
        didSet {
            if preGain < -40 {
                preGain = -40
            }            
            if preGain > 40 {
                preGain = 40
            }
            AudioUnitSetParameter(
                internalAU,
                kLimiterParam_PreGain,
                kAudioUnitScope_Global, 0,
                Float(preGain), 0)
        }
    }

    /// Dry/Wet Mix (Default 100)
    public var dryWetMix: Double = 100 {
        didSet {
            if dryWetMix < 0 {
                dryWetMix = 0
            }
            if dryWetMix > 100 {
                dryWetMix = 100
            }
            inputGain?.gain = 1 - dryWetMix / 100
            effectGain?.gain = dryWetMix / 100
        }
    }

    private var lastKnownMix: Double = 100
    private var inputGain: AKBooster?
    private var effectGain: AKBooster?

    /// Tells whether the node is processing (ie. started, playing, or active)
    public var isStarted = true

    /// Initialize the peak limiter node
    ///
    /// - parameter input: Input node to process
    /// - parameter attackTime: Attack Time (Secs) ranges from 0.001 to 0.03 (Default: 0.012)
    /// - parameter decayTime: Decay Time (Secs) ranges from 0.001 to 0.06 (Default: 0.024)
    /// - parameter preGain: Pre Gain (dB) ranges from -40 to 40 (Default: 0)
    ///
    public init(
        _ input: AKNode,
        attackTime: Double = 0.012,
        decayTime: Double = 0.024,
        preGain: Double = 0) {

            self.attackTime = attackTime
            self.decayTime = decayTime
            self.preGain = preGain

            inputGain = AKBooster(input, gain: 0)
            mixer = AKMixer(inputGain!)

            effectGain = AKBooster(input, gain: 1)

            internalEffect = AVAudioUnitEffect(audioComponentDescription: cd)
            AKManager.sharedInstance.engine.attachNode(internalEffect)
            internalAU = internalEffect.audioUnit
            AKManager.sharedInstance.engine.connect((effectGain?.avAudioNode)!, to: internalEffect, format: AKManager.format)
            AKManager.sharedInstance.engine.connect(internalEffect, to: mixer.avAudioNode, format: AKManager.format)
            self.avAudioNode = mixer.avAudioNode

            AudioUnitSetParameter(internalAU, kLimiterParam_AttackTime, kAudioUnitScope_Global, 0, Float(attackTime), 0)
            AudioUnitSetParameter(internalAU, kLimiterParam_DecayTime, kAudioUnitScope_Global, 0, Float(decayTime), 0)
            AudioUnitSetParameter(internalAU, kLimiterParam_PreGain, kAudioUnitScope_Global, 0, Float(preGain), 0)
    }

    /// Function to start, play, or activate the node, all do the same thing
    public func start() {
        if isStopped {
            dryWetMix = lastKnownMix
            isStarted = true
        }
    }

    /// Function to stop or bypass the node, both are equivalent
    public func stop() {
        if isPlaying {
            lastKnownMix = dryWetMix
            dryWetMix = 0
            isStarted = false
        }
    }
}