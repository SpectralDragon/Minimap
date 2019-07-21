//
//  ProxyDelegate.swift
//  
//
//  Created by Vladislav Prusakov on 21.07.2019.
//

import UIKit
import PencilKit

@available(iOS 13.0, *)
final class PKCanvasViewProxyDelegate: NSObject, PKCanvasViewDelegate {
    
    typealias DrawingDidChangeHandler = (_ canvasView: PKCanvasView) -> Void
    
    weak var original: PKCanvasViewDelegate?
    private let drawingDidChangeHandler: DrawingDidChangeHandler
    
    init(original: PKCanvasViewDelegate?, drawingDidChangeHandler: @escaping DrawingDidChangeHandler) {
        self.original = original
        self.drawingDidChangeHandler = drawingDidChangeHandler
    }
    
    @objc func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        self.drawingDidChangeHandler(canvasView)
        self.original?.canvasViewDrawingDidChange?(canvasView)
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if aSelector == #selector(canvasViewDrawingDidChange(_:)) {
            return true
        } else {
            return self.original?.responds(to: aSelector) ?? false
        }
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.original
    }
    
}
