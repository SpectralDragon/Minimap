//
//  MinimapHostView.swift
//  
//
//  Created by Vladislav Prusakov on 21.07.2019.
//

import UIKit
import PencilKit

@available(iOS 13.0, *)
final class MinimapHostView: UIView {
    
    private weak var imageView: UIImageView!
    private(set) var minimap: Minimap
    
    func setup() {
        self.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.07, alpha: 1)
            } else {
                return .white
            }
        }
        let imageView = UIImageView()
        imageView.addSuperview(self)
        self.imageView = imageView
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.setNeedsDisplay()
    }
    
    init(minimap: Minimap) {
        self.minimap = minimap
        super.init(frame: .zero)
        self.setup()
    }
    
    func updateMinimapPreview() {
        guard let canvasView = self.minimap.observableCanvasView else { return }
        traitCollection.performAsCurrent {
            let rect = CGRect(origin: .zero, size: canvasView.contentSize)
            let image = canvasView.drawing.image(from: rect, scale: 0.9)
            self.imageView.image = image
        }
    }
    
    override func draw(_ rect: CGRect) {
        defer { super.draw(rect) }
        
        guard let canvasView = self.minimap.observableCanvasView else {
            return
        }
        
        let zoomScale = canvasView.zoomScale
        
        let height = (rect.height * zoomScale) * canvasView.frame.height / canvasView.contentSize.height
        let width = (rect.width * zoomScale) * canvasView.frame.width / canvasView.contentSize.width
        
        let positionY = rect.height / canvasView.contentSize.height * canvasView.contentOffset.y
        let positionX = rect.width / canvasView.contentSize.width * canvasView.contentOffset.x
        
        let visibleRect = CGRect(x: positionX, y: positionY, width: width, height: height)
        
        let visibleZonePath = UIBezierPath(rect: visibleRect)
        
        self.tintColor.setStroke()
        visibleZonePath.stroke()
        
        self.tintColor.withAlphaComponent(0.4).setFill()
        visibleZonePath.fill()
    }
    
}
