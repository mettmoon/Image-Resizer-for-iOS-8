//
//  MainViewController.swift
//  Image Resizer for iOS
//
//  Created by peter on 06/07/2019.
//  Copyright © 2019 OliveStory. All rights reserved.
//

import Cocoa

extension NSImage {
    class func thumbnail(from path:String) -> NSImage? {
        let sourceImage = NSImage(contentsOfFile: path)
        sourceImage?.size = .init(width: 64, height: 64)
        return sourceImage
    }
}

class MainViewController: NSViewController {

    @IBOutlet weak var collectionView:NSCollectionView!
    @IBOutlet weak var sizeTextField:NSTextField!
    @IBOutlet weak var progressIndicator:NSProgressIndicator!
    @IBOutlet weak var directionSegmentControl:NSSegmentedControl!
    @IBOutlet weak var checkButton:NSButton!
    @IBOutlet weak var scaleTextField:NSTextField!
    @IBOutlet weak var exportScaleTextField:NSTextField!

    var browserData:[ImageItem] = []
    
    var originalScale:CGFloat = 1
    var targetScales:[Int] = [1,2,3]
    var fixedSize:CGSize = .zero
    var isFixedSize:Bool = false
    // 0: width, 1:height
    var fixedTarget:Int = 0
    
    
    @IBAction func segmentedControlAction(_ sender: NSSegmentedControl) {
        self.fixedTarget = sender.selectedSegment
        self.reloadData()
    }
    @IBAction func checkAction(_ sender:NSButton) {
        self.isFixedSize = sender.state == .on
        self.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.registerForDraggedTypes([.fileURL])
        self.collectionView.register(Cell.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("Cell"))
        self.loadCache()
        self.reloadData()
        self.checkAction(self.checkButton)
        
    }
    func loadCache(){
        let userDefaults = UserDefaults.standard
        self.isFixedSize = userDefaults.bool(forKey: "ImageSizeChecked")
        self.fixedSize = CGSize(width: userDefaults.integer(forKey: "SizeWdithValue"), height: userDefaults.integer(forKey: "SizeHeightValue"))
        self.originalScale = CGFloat(userDefaults.float(forKey: "ScaleValue"))
        self.fixedTarget = userDefaults.integer(forKey: "SelectedDirectionSegment")
        if let value = userDefaults.string(forKey: "ExportScaleValue"), value.count > 0 {
            self.targetScales = value.components(separatedBy: ",").compactMap({Int($0)})
        }
    }
    func saveCache(){
        let userDefaults = UserDefaults.standard
        userDefaults.set(self.isFixedSize, forKey: "ImageSizeChecked")
        userDefaults.set(self.fixedSize.width, forKey: "SizeWdithValue")
        userDefaults.set(self.fixedSize.height, forKey: "SizeHeightValue")
        userDefaults.set(self.originalScale, forKey: "ScaleValue")
        userDefaults.set(self.fixedTarget, forKey: "SelectedDirectionSegment")
        userDefaults.set(self.targetScales.map({"\($0)"}).joined(separator: ","), forKey: "ExportScaleValue")
    }
    func reloadData(){
        self.sizeTextField.isEnabled = self.isFixedSize
        self.directionSegmentControl.isEnabled = self.isFixedSize
        self.exportScaleTextField.stringValue = self.targetScales.map({"\($0)"}).joined(separator: ",")
        self.checkButton.state = self.isFixedSize ? .on : .off
        self.scaleTextField.stringValue = "\(self.originalScale)"
        self.directionSegmentControl.selectedSegment = self.fixedTarget
        self.sizeTextField.stringValue = self.fixedTarget == 0 ? "\(self.fixedSize.width)" : "\(self.fixedSize.height)"
    }
    
    @IBAction func resizePressed(_ sender:NSButton) {
        self.view.window?.makeFirstResponder(nil)
        if self.checkButton.state == .on {
            guard self.sizeTextField.floatValue > 0 else{
                let alert = NSAlert()
                alert.addButton(withTitle: "OK")
                alert.messageText = "form error"
                alert.informativeText = "Check a image size"
                alert.alertStyle = .warning
                alert.runModal()
                return;
            }
        }else{
            guard self.scaleTextField.floatValue > 0 else{
                let alert = NSAlert()
                alert.addButton(withTitle: "OK")
                alert.messageText = "form error"
                alert.informativeText = "sclae value must be over 0"
                alert.alertStyle = .warning
                alert.runModal()
                return;
            }
        }
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(self.checkButton.state.rawValue, forKey: "ImageSizeChecked")
        userDefaults.set(self.sizeTextField.stringValue, forKey:"SizeValue")
        userDefaults.set(self.directionSegmentControl.selectedSegment, forKey:"SelectedDirectionSegment")
        userDefaults.set(self.scaleTextField.stringValue, forKey:"ScaleValue")
        userDefaults.set(self.exportScaleTextField.stringValue, forKey:"ExportScaleValue")
        var browserData = self.browserData
        let collectionView = self.collectionView
        let progressIndicator = self.progressIndicator
        let longestSideLength = CGFloat(self.sizeTextField.floatValue)
        
        progressIndicator?.isHidden = false
        progressIndicator?.startAnimation(self)
        progressIndicator?.display()
        collectionView?.alphaValue = 0.4
        let resizeQueue = DispatchQueue(label: "Resize Image Queue")
        resizeQueue.async {
            for item in browserData {
                self.resizeImageUsingImageBrowserItem(item: item, toLongestSide: longestSideLength)
            }
            
            DispatchQueue.main.async {
                browserData.removeAll()
                collectionView?.reloadData()
                progressIndicator?.stopAnimation(self)
                progressIndicator?.isHidden = true
                collectionView?.alphaValue = 1
            }
        }
            
    }
    @IBAction func openExistingImageFile(sender:NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.begin { (result) in
            if result == .OK {
                panel.urls.forEach({ (url) in
                    guard let image = NSImage(contentsOf: url) else{return}
                    let browserItem = ImageItem(image: image, url: url)
                    self.browserData.append(browserItem)
                })
                self.collectionView.reloadData()
            }
        }
    }
}
extension MainViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.browserData.count
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), for: indexPath) as! Cell
        let data = self.browserData[indexPath.item]
        viewItem.myImageView.image = data.image
        return viewItem
    }
}

extension MainViewController: NSDraggingDestination {
    
    
    func draggingEntered(sender:NSDraggingInfo) -> NSDragOperation {
        if let vc = sender.draggingSource as? MainViewController, vc != self {
            return .every
        }
        return NSDragOperation()
    }
    
    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .every
    }
    
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let browserData = self.browserData
        let collectionView = self.collectionView
        let progressIndicator = self.progressIndicator
        guard let files = sender.draggingPasteboard.propertyList(forType: .fileURL) as? [String] else{return false}
        
        progressIndicator?.isHidden = false
        progressIndicator?.startAnimation(self)
        progressIndicator?.display()
        collectionView?.alphaValue = 0.4
        
        let addImageQueue = DispatchQueue(label: "Add Image Queue")
        addImageQueue.async {
            for file in files {
                self.addImage(from: URL(fileURLWithPath: file), to: browserData)
            }
            
            DispatchQueue.main.async {
                collectionView?.reloadData()
                progressIndicator?.stopAnimation(self)
                progressIndicator?.isHidden = true
                collectionView?.alphaValue = 1
            }
                
        }
        return true
    }
    func concludeDragOperation(_ sender: NSDraggingInfo?) {
        self.collectionView.reloadData()
    }

    func addImage(from fileURL:URL, to array:[ImageItem]){
        var array = array
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else{return}
        
        if let value = attrs[FileAttributeKey.type] as? FileAttributeType, value == .typeDirectory {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: fileURL.path) else{return}
            for content in contents {
                let contentPath = fileURL.appendingPathComponent(content)
                self.addImage(from: contentPath, to: array)
            }
            return
        }
        
        let isPNG = fileURL.pathExtension == "png"
        let isJPG = fileURL.pathExtension == "jpg"
        
        guard isPNG || isJPG else{return}
        
        guard let image = NSImage.thumbnail(from: fileURL.path) else{return}
        let browserItem = ImageItem(image: image, url: fileURL)
        array.append(browserItem)
        
    }
    func resizeImageUsingImageBrowserItem(item:ImageItem, toLongestSide longestSide:CGFloat) {
        guard let imageRep = NSBitmapImageRep.imageReps(withContentsOfFile: item.url.path)?.first else{return}
        // Issues with some PNG files: https://discussions.apple.com/thread/1976694?start=0&tstart=0
        
        var width:Int = 0
        var height:Int = 0
        
        if imageRep.pixelsWide > width { width = imageRep.pixelsWide}
        if imageRep.pixelsHigh > height { height = imageRep.pixelsHigh}
        
        let size = NSSize(width: width, height: height)
        
        for number in [3,2] {
            if Int(size.width) % number != 0 || Int(size.height) % number != 0 {
                print("\(item.url.path) is not multiple of \(number)")
            }
        }
        
        let saveFolderPath = item.url.deletingLastPathComponent().appendingPathComponent("Resized Images")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: saveFolderPath.path) {
            try? fileManager.createDirectory(at: saveFolderPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        
        var exportScaleArray = [Int]()
        
        for value in self.targetScales {
            exportScaleArray.append(value)
        }
        
        for number in exportScaleArray {
            var nameExtension = ""
            if number > 1 {
                nameExtension = "@\(number)x"
            }
            var scaleRatio = CGFloat(number)
            
            if isFixedSize {
                if self.fixedTarget == 0 {
                    scaleRatio *= longestSide / (size.width / originalScale)
                }else{
                    scaleRatio *= longestSide / (size.height / originalScale)
                }
            }
            let targetSize = NSSize(width: round(size.width / originalScale * scaleRatio), height: round(size.height / originalScale * scaleRatio))
            let resizedImage = item.image.resizedImage(targetSize, scale: 1)
            guard let data = resizedImage.tiffRepresentation else{return}
            let filename = item.url.lastPathComponent.components(separatedBy: ".").first!
            
            try?  data.write(to: saveFolderPath.appendingPathComponent(filename + nameExtension).appendingPathExtension(item.url.pathExtension))
            
        }
        self.browserData = []
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.saveCache()
        }
    }
    
    
}

extension MainViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        return true
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            switch textField {
            case self.sizeTextField:
                if let value = Float(textField.stringValue) {
                    if self.fixedTarget == 0 {
                        self.fixedSize.width = CGFloat(value)
                    }else{
                        self.fixedSize.height = CGFloat(value)
                    }
                }
            case self.scaleTextField:
                if let value = Float(textField.stringValue) {
                    self.originalScale = CGFloat(value)
                }
            case self.exportScaleTextField:
                self.targetScales = textField.stringValue.components(separatedBy: ",").map({$0.trimmingCharacters(in: .whitespacesAndNewlines)}).compactMap({Int($0)})
            default:break
            }
            self.reloadData()
        }
    }
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else{return}
        switch textField.stringValue {
        case "2.0":
            self.exportScaleTextField.stringValue = "1,2"
        case "3.0":
            self.exportScaleTextField.stringValue = "1,2,3"
        case "1.0":
            self.exportScaleTextField.stringValue = "1"
        default:break
        }
    }
    func control(_ control: NSControl, isValidObject obj: Any?) -> Bool {
        return true
    }
}

extension NSImage {
    func resizedImage(_ size:CGSize, scale ratio:CGFloat) -> NSImage {
        let scaledSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(scaledSize.width), pixelsHigh: Int(scaledSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        
        rep.size = scaledSize
        let originalImage = self
        originalImage.size = scaledSize
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        
        let fromRect = NSRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height)
        originalImage.draw(at: .zero, from: fromRect, operation: .copy, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        let resizedImage = NSImage(size: scaledSize)
        resizedImage.addRepresentation(rep)
        return resizedImage
    }
    
}
