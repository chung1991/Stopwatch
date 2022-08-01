//
//  ViewController.swift
//  Stopwatch
//
//  Created by Chung Nguyen on 6/10/22.
//

import UIKit
import Combine

extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let ti = NSInteger(self)

        
        let ms = Int(self.truncatingRemainder(dividingBy: 1) * 1000)

        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)

        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }
}

struct Lap {
    let elasped: TimeInterval
}

class StopWatch {
    var cum: TimeInterval = 0.0
    var startDate: Date = Date()
    var currentDate: Date = Date()
    
    init() {
        reset()
    }
    
    func reset() {
        cum = 0.0
        startDate = Date()
        currentDate = Date()
    }
    
    func check() {
        cum = getElapsing()
        startDate = Date()
        currentDate = Date()
    }
    
    func getElapsing() -> TimeInterval {
        cum + currentDate.timeIntervalSince(startDate)
    }
}

protocol StopWatchViewModel {
    var stopWatch: StopWatch { get set }
    var laps: [Lap] { get set }
    var delegate: StopWatchViewModelDelegate? { get set }
    func play()
    func pause()
    func reset()
    func record()
    func getElapsed() -> String
}

protocol StopWatchViewModelDelegate: AnyObject {
    func timerUpdate(_ timerString: String)
}

class StopWatchViewModelImpl: StopWatchViewModel {
    var stopWatch: StopWatch = StopWatch()
    var laps: [Lap] = []
    var timer: AnyCancellable?
    weak var delegate: StopWatchViewModelDelegate? {
        didSet {
            delegate?.timerUpdate(TimeInterval(0.0).stringFromTimeInterval())
        }
    }
    
    func play() {
        stopWatch.check()
        timer = Timer.publish(every: 1/60,
                              on: .current,
                              in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.global(qos: .background))
            .sink(receiveValue: { [weak self] currentDate in
                guard let self = self else { return }
                self.stopWatch.currentDate = currentDate
                self.delegate?.timerUpdate(self.getElapsed())
            })
    }
    
    func pause() {
        timer?.cancel()
    }
    
    func reset() {
        timer?.cancel()
        stopWatch.reset()
        laps = []
        self.delegate?.timerUpdate("0")
    }
    
    func record() {
        let lap = Lap(elasped: stopWatch.getElapsing())
        laps.append(lap)
    }
    
    func getElapsed() -> String {
        return stopWatch.getElapsing().stringFromTimeInterval()
    }
}

class ViewController: UIViewController {
    
    @IBOutlet var currentElapsedLabel: UILabel!
    @IBOutlet var lapTableView: UITableView!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var lapButton: UIButton!
    
    lazy var viewModel: StopWatchViewModel = StopWatchViewModelImpl()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupDelegates()
        reloadData()
    }
    
    func setupViews() {
        lapTableView.register(UITableViewCell.self,
                              forCellReuseIdentifier: "cell")
        
        let playButtonWidth = playButton.frame.width
        playButton.layer.cornerRadius = playButtonWidth / 2
        playButton.layer.masksToBounds = true
        
        let resetButtonWidth = resetButton.frame.width
        resetButton.layer.cornerRadius = resetButtonWidth / 2
        resetButton.layer.masksToBounds = true
        
        let lapButtonWidth = lapButton.frame.width
        lapButton.layer.cornerRadius = lapButtonWidth / 2
        lapButton.layer.masksToBounds = true
    }
    
    func setupDelegates() {
        lapTableView.delegate = self
        lapTableView.dataSource = self
        viewModel.delegate = self
    }
    
    func reloadData() {
        lapTableView.reloadData()
    }
    
    @IBAction func buttonDidTap(_ button: UIButton) {
        switch button {
        case playButton:
            if playButton.titleLabel?.text == "Play" {
                viewModel.play()
                playButton.setTitle("Pause", for: .normal)
            } else {
                viewModel.pause()
                playButton.setTitle("Play", for: .normal)
            }
            break
        case resetButton:
            viewModel.reset()
            playButton.setTitle("Play", for: .normal)
            break
        case lapButton:
            viewModel.record()
            break
        default:
            break
        }
        reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.laps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let n = viewModel.laps.count
        let row = n - indexPath.row - 1
        let elapsedString = viewModel.laps[row].elasped.stringFromTimeInterval()
        cell.textLabel?.text = "Lap: \(row + 1) \(elapsedString)"
        return cell
    }
    
}


extension ViewController: StopWatchViewModelDelegate {
    func timerUpdate(_ timerString: String) {
        DispatchQueue.main.async { [weak self] in
            self?.currentElapsedLabel.text = timerString
        }
        
    }
}
