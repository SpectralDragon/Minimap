//
//  MinimapHostWindow.swift
//  
//
//  Created by Vladislav Prusakov on 21.07.2019.
//

import UIKit

@available(iOS 13.0, *)
final class MinimapHostWindow: UIWindow {
    
    init(windowScene: UIWindowScene, minimap: Minimap, size: CGSize) {
        super.init(windowScene: windowScene)
        
        let minimapHostView = MinimapHostView(minimap: minimap)
        let controller = MinimapHostViewController(minimapView: minimapHostView, size: size)
        controller.loadViewIfNeeded()
        controller.view.addSuperview(self)
        minimap.controller = controller
        self.rootViewController = controller
        minimap.window = self
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        guard let hostViewController = self.rootViewController as? MinimapHostViewController else { return nil }
        
        if view === hostViewController.minimapView, !view.isHidden, view.alpha > 0.01 {
            return view
        }
        
        return nil
    }
    
    func dismissMinimapView(completion: @escaping () -> Void) {
        (self.rootViewController as? MinimapHostViewController)?.dismissMinimapView(completion: completion)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
