import AppKit
import AVFoundation

class AlarmController {
    private var audioPlayer: AVAudioPlayer?
    private var powerAssertion = PowerAssertion()
    private var isPlaying = false
    private var fallbackTimer: Timer?

    func prepare() {
        guard audioPlayer == nil else { return }
        if prepareAlarmPlayer() {
            NSLog("[AlarmController] Alarm audio prepared")
        }
    }

    func trigger() {
        guard !isPlaying else { return }
        isPlaying = true

        powerAssertion.acquire(name: "NoHand: Theft alarm active")
        maximizeVolume()

        if audioPlayer == nil {
            _ = prepareAlarmPlayer()
        }

        if let audioPlayer, audioPlayer.play() {
            NSLog("[AlarmController] Alarm MP3 playing — player playing=\(audioPlayer.isPlaying)")
        } else {
            startFallbackAlarm()
        }
        NSLog("[AlarmController] Triggered")
    }

    func stop() {
        guard isPlaying || audioPlayer != nil || fallbackTimer != nil else { return }
        isPlaying = false

        stopAlarmSound()
        powerAssertion.release()
        NSLog("[AlarmController] Stopped")
    }

    func resumeAfterWake() {
        guard isPlaying else { return }
        guard audioPlayer?.isPlaying != true else { return }

        stopAlarmSound()
        maximizeVolume()
        if prepareAlarmPlayer(), audioPlayer?.play() == true {
            NSLog("[AlarmController] Alarm MP3 resumed after wake")
        } else {
            startFallbackAlarm()
        }
    }

    private func maximizeVolume() {
        let script = "set volume output volume 100"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                NSLog("[AlarmController] Volume script error: \(error)")
            }
        }
    }

    private func prepareAlarmPlayer() -> Bool {
        guard let url = Bundle.main.url(forResource: "audio", withExtension: "mp3") else {
            NSLog("[AlarmController] Missing bundled resource: audio.mp3")
            return false
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0
            guard player.prepareToPlay() else {
                NSLog("[AlarmController] Failed to prepare audio.mp3")
                return false
            }
            audioPlayer = player
            return true
        } catch {
            NSLog("[AlarmController] Failed to load audio.mp3: \(error)")
            return false
        }
    }

    private func startFallbackAlarm() {
        guard fallbackTimer == nil else { return }
        NSLog("[AlarmController] Falling back to system alert sound")
        NSSound.beep()
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
            NSSound.beep()
        }
        if let fallbackTimer {
            RunLoop.main.add(fallbackTimer, forMode: .common)
        }
    }

    private func stopAlarmSound() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        NSLog("[AlarmController] Alarm sound stopped")
    }

    deinit {
        stop()
    }
}
