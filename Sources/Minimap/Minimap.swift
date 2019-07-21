//
//  Minimap.swift
//
//
//  Created by Vladislav Prusakov on 21.07.2019.
//


import UIKit
import PencilKit

@available(iOS 13.0, *)
public protocol MinimapObserver: AnyObject {
    func minimapViewVisibleDidChange(_ minimapView: Minimap)
}

@available(iOS 13.0, *)
open class Minimap: NSObject {
    
    var window: MinimapHostWindow?
    weak var controller: MinimapHostViewController?
    private lazy var observers: ObserverSet<AnyObject> = []
    
    private var proxyDelegate: PKCanvasViewProxyDelegate?
    private(set) weak var observableCanvasView: PKCanvasView?
    private weak var firstResponder: UIResponder?
    
    
    private var scrollViewContentOffsetObservable: NSKeyValueObservation?
    private var scrollViewContentSizeObservable: NSKeyValueObservation?
    private var scrollViewContentZoomScaleObservable: NSKeyValueObservation?
    private var scrollViewSafeAreaObservable: NSKeyValueObservation?
    private var responderObserver: NSKeyValueObservation?
    private var previousSafeAreaInsets: UIEdgeInsets = .zero
    
    open var tintColor: UIColor = UIColor.systemBlue {
        didSet {
            self.window?.tintColor = self.tintColor
        }
    }
    
    open var isVisible: Bool {
        guard let controller = self.controller else { return false }
        return !controller.view.isHidden
    }
    
    open func observeCanvasView(_ canvasView: PKCanvasView) {
        scrollViewContentOffsetObservable = nil
        scrollViewContentSizeObservable = nil
        scrollViewContentZoomScaleObservable = nil
        scrollViewSafeAreaObservable = nil
        
        self.observableCanvasView = canvasView
        
        self.proxyDelegate = PKCanvasViewProxyDelegate(original: canvasView.delegate, drawingDidChangeHandler: { [weak self] canvasView in
            self?.controller?.minimapView.updateMinimapPreview()
        })
        
        canvasView.delegate = self.proxyDelegate
        
        scrollViewSafeAreaObservable = canvasView.observe(\.safeAreaInsets, options: [.initial, .new]) { [weak self] scrollView, value in
            guard let safeAreaInsets = value.newValue else { return }
            self?.previousSafeAreaInsets = safeAreaInsets
            self?.controller?.additionalSafeAreaInsets = safeAreaInsets
            self?.needsUpdateLayoutIfNeeded()
        }
        
        scrollViewContentOffsetObservable = canvasView.observe(\.contentOffset) { [weak self] scrollView, value in
            self?.controller?.minimapView.setNeedsDisplay()
        }
        
        scrollViewContentSizeObservable = canvasView.observe(\.contentSize) { [weak self] scrollView, value in
            self?.controller?.minimapView.setNeedsDisplay()
        }
        
        scrollViewContentZoomScaleObservable = canvasView.observe(\.zoomScale) { [weak self] scollView, value in
            self?.controller?.minimapView.setNeedsDisplay()
        }
        
        self.controller?.minimapView.updateMinimapPreview()
    }
    
    /// Add an observer for a tool picker changes.
    ///
    /// Adding a `MinimapView` as an observer, will also set its initial state.
    /// Observers are held weakly.
    open func addObserver(_ observer: MinimapObserver) {
        self.observers.insert(observer)
    }

    /// Remove an observer for a tool picker changes.
    open func removeObserver(_ observer: MinimapObserver) {
        self.observers.remove(observer)
    }
    
    private func notifyObservers(_ block: @escaping (MinimapObserver) -> Void) {
        DispatchQueue.main.async { [weak self] in
            self?.observers.forEach { ($0.value as? MinimapObserver).flatMap(block) }
        }
    }
    
    private func setVisible(_ isVisible: Bool) {
        notifyObservers { [unowned self] in $0.minimapViewVisibleDidChange(self) }
        if !isVisible {
            self.deinitWindow()
        } else {
            self.controller?.setVisible(isVisible)
            self.needsUpdateLayoutIfNeeded()
        }
    }
    
    private func deinitWindow() {
        self.window?.dismissMinimapView { [weak self] in
            self?.window?.windowScene = nil
            self?.window = nil
        }
    }
    
    open func setVisible(_ visible: Bool, forFirstResponder responder: UIResponder) {
        if !visible {
            self.responderObserver = nil
            self.setVisible(false)
        } else {
            self.firstResponder = responder
            
            self.responderObserver = responder.observe(\.isFirstResponder, options: [.initial, .new], changeHandler: { [weak self] _, value in
                self?.setVisible(value.newValue == true)
            })
        }
    }
    
    open class func shared(for window: UIWindow, size: CGSize = CGSize(width: 240, height: 128)) -> Minimap? {
        guard let windowScene = window.windowScene else { return nil }
        if let minimapHostWindow = windowScene.windows.first(where: { $0 is MinimapHostWindow }) as? MinimapHostWindow {
            return (minimapHostWindow.rootViewController as? MinimapHostViewController)?.minimapView.minimap
        } else {
            let minimap = Minimap()
            let hostWindow = MinimapHostWindow(windowScene: windowScene, minimap: minimap, size: size)
            hostWindow.makeKeyAndVisible()
            // fix bug when uiwindow hide status bar
            hostWindow.rootViewController?.setNeedsStatusBarAppearanceUpdate()

            return minimap
        }
    }
    
}

// MARK: - PKToolPickerObserver

extension Minimap: PKToolPickerObserver {
    
    public func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        self.needsUpdateLayoutIfNeeded()
    }
    
    func needsUpdateLayoutIfNeeded() {
        guard let window = self.window, let toolPicker = PKToolPicker.shared(for: window) else { return }
         
        let frame = toolPicker.frameObscured(in: window)
        
        if window.traitCollection.userInterfaceIdiom == .phone {
            self.controller?.additionalSafeAreaInsets.bottom = toolPicker.isVisible ? frame.height + previousSafeAreaInsets.bottom : previousSafeAreaInsets.bottom
        } else {
            self.controller?.additionalSafeAreaInsets.bottom = self.previousSafeAreaInsets.bottom
        }
        
        UIView.animate(withDuration: 0.15) {
            window.layoutIfNeeded()
        }
    }
}
