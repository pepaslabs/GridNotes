//
//  KeyboardContainerController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/17/21.
//

import UIKit


/// Protocol for switching between grid / ring user interfaces.
protocol InterfaceChanging {
    func interfaceDidGetSelected(interface: Interface, state: AppState)
}

protocol InterfaceDelegating {
    var interfaceDelegate: InterfaceChanging? { get set }
}


/// A container controller which contains either a grid piano or a ring piano.
class KeyboardContainerController: UIViewController {

    init(initialState: AppState) {
        switch initialState.interface {
        case .grid:
            _childController = GridKeyboardViewController(state: initialState)
        case .ring:
            _childController = RingKeyboardViewController(state: initialState)
        }
        super.init(nibName: nil, bundle: nil)
        _childController.interfaceDelegate = self
    }

    // MARK: - Internals

    /// The contained grid or ring piano view controller.
    private var _childController: (UIViewController & InterfaceDelegating)
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(_childController.view)
        addChild(_childController)
        _childController.didMove(toParent: self)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension KeyboardContainerController: InterfaceChanging {
    
    /// Switch between the grid / ring user interfaces.
    func interfaceDidGetSelected(interface: Interface, state: AppState) {
        
        func swapToNewChildVC(child newChild: UIViewController & InterfaceDelegating) {
            // Remove the old VC.
            _childController.willMove(toParent: nil)
            _childController.removeFromParent()
            _childController.view.removeFromSuperview()

            // Add the new VC.
            view.addSubview(newChild.view)
            view.topAnchor.constraint(equalTo: newChild.view.topAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: newChild.view.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: newChild.view.trailingAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: newChild.view.bottomAnchor).isActive = true
            addChild(newChild)
            newChild.didMove(toParent: self)
            _childController = newChild
            _childController.interfaceDelegate = self
        }
        
        switch interface {
        case .grid:
            if type(of: _childController) != GridKeyboardViewController.self {
                let child = GridKeyboardViewController(state: state)
                swapToNewChildVC(child: child)
            }
        case .ring:
            if type(of: _childController) != RingKeyboardViewController.self {
                let child = RingKeyboardViewController(state: state)
                swapToNewChildVC(child: child)
            }
        }
    }
}
