//
//  Cell.swift
//  Image Resizer for iOS
//
//  Created by peter on 07/07/2019.
//  Copyright © 2019 OliveStory. All rights reserved.
//

import Cocoa

final class Cell: NSCollectionViewItem {
    let myImageView = NSImageView()
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.addSubview(self.myImageView)
        self.myImageView.frame = self.view.bounds
        self.myImageView.autoresizingMask = [.width, .height]
    }
    override func viewDidLayout() {
        super.viewDidLayout()
        
    }
}
