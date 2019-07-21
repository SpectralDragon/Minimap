//
//  MinimapHostViewController.swift
//  
//
//  Created by Vladislav Prusakov on 21.07.2019.
//

import UIKit

@available(iOS 13.0, *)
final class MinimapHostViewController: UIViewController {
    
    unowned let minimapView: MinimapHostView
    private weak var minimapContainerView: UIView?
    private let size: CGSize
    
    init(minimapView: MinimapHostView, size: CGSize) {
        self.minimapView = minimapView
        self.size = size
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .clear
        self.view = view
    }
    
    private lazy var positionViews: [MinimapPositionView] = []
    
    private var positions: [CGPoint] {
        return positionViews.map { $0.center }
    }
    
    private let horizontalSpacing: CGFloat = 16
    private let verticalSpacing: CGFloat = 16
    
    func setVisible(_ visible: Bool) {
        self.view.isHidden = !visible
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let minimapContainerView = UIView()
        minimapContainerView.applyShadow(color: .black, shouldRasterize: false)
        self.minimapView.addSuperview(minimapContainerView)
        self.minimapView.layer.cornerRadius = 8
        
        let topLeftView = addPositionView()
        topLeftView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalSpacing).isActive = true
        topLeftView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        let topRightView = addPositionView()
        topRightView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -horizontalSpacing).isActive = true
        topRightView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        let bottomLeftView = addPositionView()
        bottomLeftView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalSpacing).isActive = true
        bottomLeftView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -verticalSpacing).isActive = true
        
        let bottomRightView = addPositionView()
        bottomRightView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -horizontalSpacing).isActive = true
        bottomRightView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -verticalSpacing).isActive = true
        
        view.addSubview(minimapContainerView)
        minimapContainerView.translatesAutoresizingMaskIntoConstraints = false
        minimapContainerView.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        minimapContainerView.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(minimapPanned(_:)))
        minimapContainerView.addGestureRecognizer(panRecognizer)
        
        self.minimapContainerView = minimapContainerView
        
        minimapContainerView.transform = CGAffineTransform(scaleX: 0, y: 0)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            minimapContainerView.transform = .identity
        }, completion: nil)
        
    }
    
    func dismissMinimapView(completion: @escaping () -> Void) {
        self.minimapContainerView?.alpha = 1
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.minimapContainerView?.alpha = 0
        }, completion: { _ in completion() })
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.minimapView.updateMinimapPreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.minimapContainerView?.center = positions.last ?? .zero
    }
    
    private func addPositionView() -> MinimapPositionView {
        let view = MinimapPositionView()
        self.view.addSubview(view)
        positionViews.append(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: size.height).isActive = true
        return view
    }
    
    private var initialOffset: CGPoint = .zero
    
    @objc private func minimapPanned(_ recognizer: UIPanGestureRecognizer) {
        guard let minimapContainerView = self.minimapContainerView else { return }
        let touchPoint = recognizer.location(in: view)
        switch recognizer.state {
        case .began:
            initialOffset = CGPoint(x: touchPoint.x - minimapContainerView.center.x, y: touchPoint.y - minimapContainerView.center.y)
        case .changed:
            minimapContainerView.center = CGPoint(x: touchPoint.x - initialOffset.x, y: touchPoint.y - initialOffset.y)
        case .ended, .cancelled:
            let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
            let velocity = recognizer.velocity(in: view)
            let projectedPosition = CGPoint(
                x: minimapContainerView.center.x + project(initialVelocity: velocity.x, decelerationRate: decelerationRate),
                y: minimapContainerView.center.y + project(initialVelocity: velocity.y, decelerationRate: decelerationRate)
            )
            let nearestCornerPosition = nearestCorner(to: projectedPosition)
            let relativeInitialVelocity = CGVector(
                dx: relativeVelocity(forVelocity: velocity.x, from: minimapContainerView.center.x, to: nearestCornerPosition.x),
                dy: relativeVelocity(forVelocity: velocity.y, from: minimapContainerView.center.y, to: nearestCornerPosition.y)
            )

            let timingParameters = UISpringTimingParameters(damping: 1, response: 0.4, initialVelocity: relativeInitialVelocity)
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
            animator.addAnimations {
                self.minimapContainerView?.center = nearestCornerPosition
            }
            animator.startAnimation()
        default: break
        }
    }
    
    /// Distance traveled after decelerating to zero velocity at a constant rate.
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate)
    }
    
    /// Finds the position of the nearest corner to the given point.
    private func nearestCorner(to point: CGPoint) -> CGPoint {
        var minDistance = CGFloat.greatestFiniteMagnitude
        var closestPosition = CGPoint.zero
        for position in self.positions {
            let distance = point.distance(to: position)
            if distance < minDistance {
                closestPosition = position
                minDistance = distance
            }
        }
        return closestPosition
    }
    
    /// Calculates the relative velocity needed for the initial velocity of the animation.
    private func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: CGFloat, to targetValue: CGFloat) -> CGFloat {
        guard currentValue - targetValue != 0 else { return 0 }
        return velocity / (targetValue - currentValue)
    }
}

fileprivate class MinimapPositionView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
