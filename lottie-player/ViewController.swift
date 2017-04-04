//
//  ViewController.swift
//  lottie-player
//
//  Created by Jackson Taylor on 2/10/17.
//  Copyright © 2017 WillowTree Apps, Inc. All rights reserved.
//

import Cocoa
import Lottie

class ViewController: NSViewController, NSTextFieldDelegate {

    var canvas: LOTAnimationView? = nil
    
    @IBOutlet weak var canvasContainer: NSView!
    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var controlView: NSView!
    @IBOutlet weak var sideView: NSView!
    @IBOutlet weak var backgroundColorView: NSBox!
    @IBOutlet weak var transparentBackgroundView: NSBox!
    @IBOutlet weak var imageBackgroundView: NSView!
    
    @IBOutlet weak var canvasWidth: NSTextField!
    @IBOutlet weak var canvasHeight: NSTextField!
    
    @IBOutlet weak var animationWidth: NSTextField!
    @IBOutlet weak var animationHeight: NSTextField!
    @IBOutlet weak var animationX: NSTextField!
    @IBOutlet weak var animationY: NSTextField!
    
    var progressTimer: Timer?
    
    var isActive: Bool {
        let controller = NSApplication.shared().keyWindow?.contentViewController
        return controller == self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startProgressTimer()
        NSColorPanel.shared().showsAlpha = true
        
        if #available(OSX 10.12.2, *) {
            slider.trackFillColor = NSColor(red:0.00, green:0.82, blue:0.76, alpha:1.00)
        }
        
        if let backgroundImage = NSImage(named: "icTransparentBackground") {
            transparentBackgroundView.fillColor = NSColor(patternImage: backgroundImage)
        }
        
        imageBackgroundView.wantsLayer = true
        imageBackgroundView.layer = CALayer()
        imageBackgroundView.layer?.contentsGravity = kCAGravityResizeAspectFill
        
        setupKeyPressObserver()
        
        DispatchQueue.main.async {
            self.setupInitialAnimationValues()
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        DispatchQueue.main.async {
            self.setupCanvasSizeValues()
            self.reloadAnimationValues()
        }
    }
    
    func setupCanvasSizeValues() {
        canvasWidth.stringValue = "\(canvasContainer?.frame.size.width ?? 0.0)"
        canvasHeight.stringValue = "\(canvasContainer?.frame.size.height ?? 0.0)"
    }
    
    func setupInitialAnimationValues() {
        animationX.doubleValue = 0.0
        animationY.doubleValue = 0.0
        animationWidth.doubleValue = Double(canvasContainer?.frame.size.width ?? 0.0)
        animationHeight.doubleValue = Double(canvasContainer?.frame.size.height ?? 0.0)
    }
    
    func reloadAnimationValues() {
        animationX.doubleValue = Double(canvas?.frame.origin.x ?? 0.0)
        animationY.doubleValue = Double(canvas?.frame.origin.y ?? 0.0)
        animationWidth.doubleValue = Double(canvas?.frame.size.width ?? 0.0)
        animationHeight.doubleValue = Double(canvas?.frame.size.height ?? 0.0)
    }
    
    func updateCanvas(withAnimation animation: [AnyHashable : Any]) {
        if let canvas = self.canvas {
            canvas.removeFromSuperview()
            self.canvas = nil
        }
        guard let tempCanvas = LOTAnimationView(json: animation) else {
            return
        }
        
        tempCanvas.loopAnimation = true
        tempCanvas.contentMode = LOTViewContentMode.scaleAspectFill
        tempCanvas.frame = canvasContainer.bounds
        tempCanvas.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        canvasContainer.addSubview(tempCanvas)
        self.canvas = tempCanvas
        play()
    }
    
    func set(backgroundColor: NSColor) {
        backgroundColorView.fillColor = backgroundColor
    }
    
    func set(backgroundImage: NSImage?) {
        imageBackgroundView.layer?.contents = backgroundImage
    }
    
    @IBAction func colorValueChanged(sender: NSColorWell) {
        set(backgroundColor: sender.color)
    }
    
    @IBAction func imageValueChanged(sender: NSImageView) {
        set(backgroundImage: sender.image)
    }
    
    @IBAction func imageWellClicked(sender: NSClickGestureRecognizer) {
        guard let imageView = sender.view as? NSImageView,
            let window = self.view.window else {
            return
        }
        let openDialog = NSOpenPanel()
        openDialog.allowedFileTypes = ["png","jpg","jpeg"]
        openDialog.allowsMultipleSelection = false
        openDialog.beginSheetModal(for: window) { [weak self] result in
            guard result == NSFileHandlingPanelOKButton,
                let imageURL = openDialog.urls.first,
                let image = NSImage(contentsOf: imageURL) else {
                    return
            }
            imageView.image = image
            self?.set(backgroundImage: image)
        }
    }
    
    @IBAction func sliderChangedValue(sender: NSSlider) {
        
        guard let event = NSApplication.shared().currentEvent else {
            return
        }
        
        switch event.type {
        case .leftMouseDown:
            sliderStartedDragging()
            pause()
        case .leftMouseUp:
            sliderStoppedDragging()
        default:
            break
        }
        
        canvas?.animationProgress = CGFloat(sender.doubleValue)
    }
    
    func sliderStartedDragging() {
        stopProgressTimer()
    }
    
    func sliderStoppedDragging() {
        startProgressTimer()
    }
    
    @IBAction func toggleAnimation(sender: NSButton) {
        if canvas?.isAnimationPlaying == true {
            pause()
        }
        else {
            play()
        }
    }
    
    @IBAction func didTapCanvas(sender: NSClickGestureRecognizer) {
        toggleAnimation(sender: playButton)
    }
    
    func play() {
        guard canvas?.isAnimationPlaying == false else {
            return
        }
        playButton.image = NSImage(named: "icPause")
        canvas?.play()
    }
    
    func pause() {
        guard canvas?.isAnimationPlaying == true else {
            return
        }
        playButton.image = NSImage(named: "icPlay")
        canvas?.pause()
    }
    
    func startProgressTimer() {
        guard self.progressTimer == nil else {
            return
        }
        let progressTimer = Timer(timeInterval: 0.01, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
        RunLoop.main.add(progressTimer, forMode: .commonModes)
        self.progressTimer = progressTimer
    }
    
    func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func updateProgress() {
        slider.doubleValue = Double(canvas?.animationProgress ?? 0.0)
    }
    
    func updateAnimationProgress(by value: CGFloat) {
        guard let currentProgress = canvas?.animationProgress else {
            return
        }
        canvas?.animationProgress = currentProgress + value
    }
    
    // MARK: Keyboard Events
    
    func setupKeyPressObserver() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] in
            self?.keyPressed(withEvent: $0)
            return $0
        }
    }
    
    func keyPressed(withEvent event: NSEvent) {
        guard isActive else {
            return
        }
        
        switch event.keyCode {
        case 49: // space bar
            toggleAnimation(sender: playButton)
        case 123: // left arrow
            pause()
            updateAnimationProgress(by: -0.01)
        case 124: // right arrow
            pause()
            updateAnimationProgress(by: 0.01)
        default:
            break
        }
    }
    
    @IBAction func canvasValuesChanged(sender: NSTextField) {
        setCanvasSize(CGSize(width: canvasWidth.doubleValue, height: canvasHeight.doubleValue))
    }
    
    func setCanvasSize(_ size: CGSize) {
        guard let window = self.view.window else {
            return
        }
        let bottomOffset = controlView.frame.size.height
        let rightOffset = sideView.frame.size.width
        
        var realSize = size
        realSize.width += rightOffset
        realSize.height += bottomOffset
        
        var windowFrame = window.frame
        
        windowFrame.size = realSize
        
        window.setFrame(windowFrame, display: true, animate: true)
    }
    
    @IBAction func animationValuesChanged(sender: NSTextField) {
        var frame = CGRect()
        frame.origin.x = CGFloat(animationX.doubleValue)
        frame.origin.y = CGFloat(animationY.doubleValue)
        frame.size.width = CGFloat(animationWidth.doubleValue)
        frame.size.height = CGFloat(animationHeight.doubleValue)
        setAnimationFrame(frame)
    }
    
    func setAnimationFrame(_ frame: CGRect) {
        canvas?.frame = frame
    }
    
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        
        print(event)
    }
}

