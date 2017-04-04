//
//  Document.swift
//  lottie-player
//
//  Created by Jackson Taylor on 2/10/17.
//  Copyright © 2017 WillowTree Apps, Inc. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    
    var oldModificationDate: Date?
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }
    
    override var isInViewingMode: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "Document Window Controller") as! NSWindowController
        windowController.window?.titlebarAppearsTransparent = true
        windowController.window?.titleVisibility = .hidden
        self.addWindowController(windowController)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        
        guard let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] else {
            return
        }
        
        DispatchQueue.main.async {
            self.loadAnimationToWindows(animation: obj)
        }
        
        oldModificationDate = getModificationDate(forFileURL: fileURL)
    }

    func loadAnimationToWindows(animation: [AnyHashable: Any]) {
        windowControllers.forEach {
            if let controller = $0.contentViewController as? ViewController {
                controller.updateCanvas(withAnimation: animation)
            }
        }
    }
    
    override func presentedItemDidChange() {
        guard let fileURL = fileURL,
            oldModificationDate?.compare(getModificationDate(forFileURL: fileURL)) != .orderedSame else {
            return
        }
        
        try? read(from: fileURL, ofType: fileType ?? "")
    }
    
    func getModificationDate(forFileURL fileURL: URL?) -> Date {
        guard let fileURL = fileURL,
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let modificationDate = attributes[.modificationDate] as? Date else {
            return Date.distantPast
        }
        return modificationDate
    }
}

