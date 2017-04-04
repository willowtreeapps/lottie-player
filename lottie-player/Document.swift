//
//  Document.swift
//  lottie-player
//
//  Copyright (c) 2017 WillowTree, Inc.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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

