import AVFoundation

/// 全局音效播放器
/// 使用方法：
///   SoundManager.shared.play("pick_up")           // 普通音效
///   SoundManager.shared.playLoop("pouring")       // 循环音效（倒酒）
///   SoundManager.shared.stopLoop("pouring")       // 停止循环
///   SoundManager.shared.playBGM("background")     // 背景音乐
///   SoundManager.shared.stopBGM()                 // 停止背景音乐
///
/// 音效文件（.mp3 或 .wav）放在 Sounds/ 文件夹里
@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    private var loopPlayers: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?
    
    private init() {
        // 设置音频会话，允许和其他音频混合
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(" Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - 普通音效（播放一次）
    
    /// 播放音效
    /// - Parameter name: 音效文件名（不含扩展名）
    func play(_ name: String) {
        guard let url = findAudioFile(name) else {
            print(" Sound file not found: \(name)")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
            players[name] = player
        } catch {
            print(" Could not play sound: \(name), error: \(error)")
        }
    }
    
    /// 停止音效
    /// - Parameter name: 音效文件名
    func stop(_ name: String) {
        players[name]?.stop()
        players[name] = nil
    }
    
    // MARK: - 循环音效（倒酒用）
    
    /// 循环播放音效
    /// - Parameter name: 音效文件名
    func playLoop(_ name: String) {
        // 如果已经在播放，不重复启动
        if loopPlayers[name]?.isPlaying == true { return }
        
        guard let url = findAudioFile(name) else {
            print(" Sound file not found: \(name)")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1  // 无限循环
            player.play()
            loopPlayers[name] = player
        } catch {
            print(" Could not play loop: \(name), error: \(error)")
        }
    }
    
    /// 停止循环音效
    /// - Parameter name: 音效文件名
    func stopLoop(_ name: String) {
        loopPlayers[name]?.stop()
        loopPlayers[name] = nil
    }
    
    // MARK: - 背景音乐
    
    /// 播放背景音乐（循环）
    /// - Parameter name: 音乐文件名
    /// - Parameter volume: 音量（0.0 - 1.0），默认 0.3
    func playBGM(_ name: String, volume: Float = 0.1) {
        if bgmPlayer?.isPlaying == true { return }
        guard let url = findAudioFile(name) else {
            print(" BGM file not found: \(name)")
            return
        }
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1  // 无限循环
            bgmPlayer?.volume = volume
            bgmPlayer?.play()
        } catch {
            print(" Could not play BGM: \(name), error: \(error)")
        }
    }
    
    /// 停止背景音乐
    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }
    
    /// 设置背景音乐音量
    /// - Parameter volume: 音量（0.0 - 1.0）
    func setBGMVolume(_ volume: Float) {
        bgmPlayer?.volume = volume
    }
    
    /// 暂停背景音乐
    func pauseBGM() {
        bgmPlayer?.pause()
    }
    
    /// 恢复背景音乐
    func resumeBGM() {
        bgmPlayer?.play()
    }
    
    // MARK: - 工具方法
    
    /// 查找音频文件（支持 .wav 和 .mp3）
    private func findAudioFile(_ name: String) -> URL? {
        // .swiftpm 项目用 Bundle.module
        if let url = Bundle.module.url(forResource: name, withExtension: "wav") { return url }
        if let url = Bundle.module.url(forResource: name, withExtension: "mp3") { return url }
        if let url = Bundle.module.url(forResource: name, withExtension: "m4a") { return url }
        // fallback to Bundle.main
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: "m4a") { return url }
        return nil
    }
}
