//
//  YouTubeView.swift
//  YouTubeSdk
//
//  Created by Buğra Göçer on 31.05.2019.
//  Copyright © 2019 Facebook. All rights reserved.
//


import UIKit

@objc class YouTubeView: UIView {
    
    @objc var onError: RCTDirectEventBlock?
    @objc var onReady: RCTDirectEventBlock?
    @objc var onChangeState: RCTDirectEventBlock?
    @objc var onChangeFullscreen: RCTDirectEventBlock?
    
    @objc var autoPlay: Bool = false;

    var initialized = false;
    
    var playerVars:[String: Any] = [
        "controls" : "0",
        "showinfo" : "0",
        "autoplay": "0",
        "rel": "0",
        "modestbranding": "1",
        "iv_load_policy" : "3",
        "fs": "0",
        "ecver" : "2",
        "playsinline" : "1"
    ]
    
    @objc var fullscreen: Bool = false {
        didSet{
            playerVars["fs"] = (fullscreen) ? "1" : "0";
            playerVars["playsinline"] = (fullscreen) ? "0" : "1";
        }
    }
    
    @objc var showSeekBar: Bool = false {
        didSet{
            playerVars["controls"] = (showSeekBar) ? "1" : "0";
            self.player.isUserInteractionEnabled = showSeekBar
        }
    }
   
    @objc var videoId: NSString = "" {
        didSet {
            _ = player.load(videoId: videoId as String,  playerVars: playerVars)
        }
    } 
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(player)
        
        // listen for videos playing in fullscreen
        NotificationCenter.default.addObserver(self, selector: #selector(onDidEnterFullscreen(_:)), name: UIWindow.didBecomeVisibleNotification, object: self.window)
        
        // listen for videos stopping to play in fullscreen
        NotificationCenter.default.addObserver(self, selector: #selector(onDidLeaveFullscreen(_:)), name: UIWindow.didBecomeHiddenNotification, object: self.window)
    }
    
    deinit{
        // remove video listeners
        NotificationCenter.default.removeObserver(self, name: UIWindow.didBecomeVisibleNotification, object: self.window)
        NotificationCenter.default.removeObserver(self, name: UIWindow.didBecomeHiddenNotification, object: self.window)
    }
    
    @objc func reactSetFrame(frame:CGRect) {
        super.reactSetFrame(frame)
        player.frame = frame
    }
    
    override func layoutSubviews() {
        player.frame = self.bounds
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var player: YTPlayerView = {
        let playerView = YTPlayerView(frame: frame)

        playerView.originURL = URL(string: "https://www.youtube.com")
        
        playerView.delegate = self
        return playerView
    }()
    
    
    @objc func play() {
        player.playVideo()
    }
    
    @objc func pause() {
        if self.initialized {
            player.pauseVideo()
        }
    }
    
    @objc func seekTo(seconds: NSInteger) {
       player.seek(seekToSeconds: Float(seconds), allowSeekAhead: true)
    }
    
    @objc func LoadVideo(videoId: NSString, seconds: NSInteger) {
         _ = player.load(videoId: videoId as String,  playerVars: playerVars)
    }
    
    @objc func getCurrentTime() -> NSInteger{
        return NSInteger(player.currentTime)
    }
    
    @objc func getVideoDuration() -> NSInteger{
        return NSInteger(player.duration)
    }
    
    @objc func onDidEnterFullscreen(_ notification: Notification) {
        print("video is now playing in fullscreen")
        onChangeFullscreen!(["isFullscreen" : true])
    }
    
    @objc func onDidLeaveFullscreen(_ notification: Notification) {
        print("video has stopped playing in fullscreen")
        onChangeFullscreen!(["isFullscreen" : false])
    }
}

extension YouTubeView: YTPlayerViewDelegate{
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        //player is ready to go
        onReady!(["type" : "ready"])
        
        if autoPlay {
            playerView.playVideo()
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState){
        onChangeState!(
        ["state" :
            {
                switch state {
                case .unstarted:  return "UNSTARTED"
                case .ended:  return "ENDED"
                case .playing:
                    self.initialized = true;
                    return "PLAYING"
                case .paused:  return"PAUSED"
                case .buffering:  return "BUFFERING"
                case .queued:  return "QERUED"
                case .unknown:  return "UNKNOWN"
                }
            }()
        ])
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        onError!(["error" : error.rawValue])
    }
    
}
