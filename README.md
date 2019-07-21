# Minimap

Minimap is light way to represent your canvas to mini map. 

[![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat)](https://swift.org/)

For base I used PKToolPicker API and Minimap works and looks like PKToolPicker.

## Features

- [x] Floating minimap
- [x] Customization
- [x] Dark theme support
- [x] PKToolPicker API
- [x] Orienation support

![Example](https://github.com/SpectralDragon/Minimap/raw/master/preview.gif)

## Requirements
Minimap is written in Swift 5.1 and is available on iOS 13.

## Usage

For get instance Minimap using `Minimap.shared(for: UIWindow)`

Example:

```swift
if let minimap = Minimap.shared(for: self.view.window) {
    PKToolPicker.shared(for: window)?.addObserver(minimap) // For handling PKToolPicker frame 
    minimap.observeCanvasView(canvasView) // For handling content changing
    minimap.setVisible(!minimap.isVisible, forFirstResponder: canvasView) // Set visible for minimap
    canvasView.becomeFirstResponder()
    
    minimap.tintColor = .green // Set visible zone color
}
```
Minimap will automaticly hidden if responder will resign.

## How it's works?

Minimap subscribe to canvas properties like `contentSize`, `contentOffset` and etc. and present new `MinimapHostWindow` for presenting minimap without adding like subview to your views.
