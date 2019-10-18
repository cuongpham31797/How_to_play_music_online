//
//  MainScreen.swift
//  demo_DoAn
//
//  Created by Cuong  Pham on 10/17/19.
//  Copyright © 2019 Cuong  Pham. All rights reserved.
//

import UIKit
import Stevia
import SDWebImage

import AVFoundation
import AVKit
import MediaPlayer

class MainScreen: UIViewController {
//khai bao cac bien de quan ly viec phat nhac
    var avPlayer : AVPlayer?
    var avPlayerItem : AVPlayerItem?
//---------------------------------------------
//khai bao bien de xac dinh khi nao play-pause
    var isPlaying : Bool = false
//-----------------------------------------------
//góc quay
    var alpha : Int = 0
//-----------------------------------------------
    lazy var avatarImage : UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 75
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    lazy var subView : UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.clipsToBounds = true
        return view
    }()
    
    lazy var playPauseButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.titleLabel?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        button.layer.cornerRadius = 30
        button.clipsToBounds = true
        button.setTitle("Play", for: .normal)
        button.addTarget(self, action: #selector(onTapPlay), for: .touchUpInside)
        return button
    }()
    
    lazy var volumeSlider : UISlider = {
        let slider = UISlider()
        slider.thumbTintColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        slider.maximumTrackTintColor = .lightGray
        slider.minimumTrackTintColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        slider.maximumValue = 10
        slider.value = 5
    //chỉnh volume của bài hát
        slider.addTarget(self, action: #selector(onTapVolumeSlider(_:)), for: .valueChanged)
        return slider
    }()
    
    lazy var timeSlider : UISlider = {
        let slider = UISlider()
        slider.thumbTintColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        slider.maximumTrackTintColor = .lightGray
        slider.minimumTrackTintColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
        slider.value = 0
    //hàm bắt sựu kiện tua bài hát bằng slider
        slider.addTarget(self, action: #selector(onTapTimeSlider(_:)), for: .valueChanged)
    //----------------------------------------------------------------------------------
        return slider
    }()
    
    lazy var beginLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "00:00:00"
        label.sizeToFit()
        return label
    }()
    
    lazy var finishLabel : UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "00:00:00"
        label.sizeToFit()
        return label
    }()
    
    lazy var volumeMinImage : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "volume_down")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    lazy var volumeMaxImage : UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "volume_up")
        image.contentMode = .scaleAspectFit
        return image
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setUpLayout()
    //play nhạc
        guard let url = URL(string: "https://drive.google.com/uc?export=download&id=1-u1GJDC-1xSiq8qatYC-ZzAwcF856g6k") else { return }
        avPlayerItem = AVPlayerItem(url: url)
        avPlayer = AVPlayer(playerItem: avPlayerItem)
        avPlayer?.play()
    //------------------------------------------------------------------------------------------------
    //lấy thời lượng của bài hát, convert từ dạng CMTime -> dạng Float (số giây) -> dạng String hh:mm:ss
        guard let duration : CMTime = self.avPlayer?.currentItem?.asset.duration else { return }
        let duration_second : Float = Float(CMTimeGetSeconds(duration))
        print(stringFromTimeInterval(interval: TimeInterval(duration_second)))
        finishLabel.text = stringFromTimeInterval(interval: TimeInterval(duration_second))
        timeSlider.maximumValue = duration_second
    //------------------------------------------------------------------------------------------------
    //cập nhật slider và beginLabel theo thời gian bài hát
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            guard let currentTime = self.avPlayer?.currentTime() else { return }
            let currentTime_second = Float(CMTimeGetSeconds(currentTime))
            self.timeSlider.value = currentTime_second
            self.beginLabel.text = self.stringFromTimeInterval(interval: TimeInterval(currentTime_second))
        }
    //------------------------------------------------------------------------------------------------
    //xoay dia
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(turnCD), userInfo: nil, repeats: true)
    //------------------------------------------------------------------------------------------------
    //Hiển thị thông tin bài hát lên locksreen, chỉ dùng cho máy thật
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
        //tên của bài hát
            MPMediaItemPropertyTitle : "Tên bài hát",
        //tên tác giả
            MPMediaItemPropertyArtist : "Tên tác giả",
        //
            MPMediaItemPropertyPlaybackDuration : avPlayerItem?.duration ?? ""
        ]
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    //------------------------------------------------------------------------------------------------
    //Cho phép phát nhạc khi đã khóa thiết bị
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,
                                                            mode: AVAudioSession.Mode.default,
                                                            options: [])
        }catch{
            print("error")
        }
    //------------------------------------------------------------------------------------------------
    }
    
    @objc func onTapPlay(){
        print("play")
    //check trạng thái play - pause
        if self.isPlaying == false{
            avPlayer?.pause()
            playPauseButton.setTitle("Play", for: .normal)
            isPlaying = true
        }else{
        //khi tap pause sau đó tiếp tục tap play, bài hát sẽ phát tiếp ở đoạn vừa pause mà ko play lại từ đầu
            guard let currentTime = avPlayer?.currentTime() else { return }
            print(CMTimeGetSeconds(currentTime))
            let seekToTime : CMTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime), preferredTimescale: 1)
            avPlayer?.seek(to: seekToTime)
            avPlayer?.play()
        //------------------------------------------------------------
            playPauseButton.setTitle("Pause", for: .normal)
            isPlaying = false
        }
    //--------------------------------------------------------------
    }
    
    @objc func onTapTimeSlider(_ sender : UISlider){
        self.avPlayer?.pause()
        let currentTime = TimeInterval(timeSlider.value)
        beginLabel.text = stringFromTimeInterval(interval: currentTime)
        let seekToTime : CMTime = CMTimeMakeWithSeconds(currentTime, preferredTimescale: 1)
        avPlayer?.seek(to: seekToTime)
        avPlayer?.play()
    }
    
    @objc func onTapVolumeSlider(_ sender : UISlider){
        avPlayer?.volume = sender.value
    }
    
    @objc func turnCD(){
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: {
            self.alpha += 3
            self.avatarImage.transform = CGAffineTransform(rotationAngle: (CGFloat(self.alpha) * CGFloat(Double.pi)) / 180)
        }, completion: nil)
    }
    
    fileprivate func setUpLayout(){
        view.sv(avatarImage, playPauseButton, timeSlider, beginLabel, finishLabel, volumeSlider, volumeMaxImage, volumeMinImage)
        avatarImage.centerHorizontally().size(150).Top == view.safeAreaLayoutGuide.Top + 20
        let url = URL(string: "https://drive.google.com/uc?export=download&id=1uKwWsoTwfVrjk_1o-qrVZ7R5_MTJMNwy")
        avatarImage.sd_setImage(with: url, completed: nil)
        volumeSlider.centerHorizontally().width(60%).Bottom == view.safeAreaLayoutGuide.Bottom - 15
        playPauseButton.centerHorizontally().size(60).Bottom == volumeSlider.Top - 20
        timeSlider.centerInContainer().width(80%)
        
        beginLabel.Top == timeSlider.Bottom + 5
        beginLabel.Leading == timeSlider.Leading
        
        finishLabel.Top == beginLabel.Top
        finishLabel.Trailing == timeSlider.Trailing
        
        volumeMinImage.size(30).Trailing == volumeSlider.Leading - 10
        volumeMinImage.Top == volumeSlider.Top
        
        volumeMaxImage.size(30).Leading == volumeSlider.Trailing + 10
        volumeMaxImage.Top == volumeSlider.Top
        
        avatarImage.sv(subView)
        subView.centerInContainer().size(50)
    }
    
//dinh dang hh:mm:ss
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
//-----------------------------------------------------------------------------------------------------
}
