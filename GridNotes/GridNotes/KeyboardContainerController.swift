//
//  KeyboardContainerController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/17/21.
//

import UIKit


protocol InterfaceChanging {
    func interfaceDidGetSelected(interface: Interface, state: AppState)
}

protocol InterfaceDelegating {
    var interfaceDelegate: InterfaceChanging? { get set }
}


class KeyboardContainerController: UIViewController, InterfaceChanging {

    var childController: (UIViewController & InterfaceDelegating)
    
    func interfaceDidGetSelected(interface: Interface, state: AppState) {
        switch interface {
        case .grid:
            if type(of: childController) != GridKeyboardViewController.self {
                let child = GridKeyboardViewController(state: state)
                _swapToNewChildVC(child: child)
            }
        case .ring:
            if type(of: childController) != RingKeyboardViewController.self {
                let child = RingKeyboardViewController(state: state)
                _swapToNewChildVC(child: child)
            }
        }
    }
    
    init(initialState: AppState) {
        switch initialState.interface {
        case .grid:
            childController = GridKeyboardViewController(state: initialState)
        case .ring:
            childController = RingKeyboardViewController(state: initialState)
        }
        super.init(nibName: nil, bundle: nil)
        childController.interfaceDelegate = self
    }

    // MARK: - Internals
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(childController.view)
        addChild(childController)
        childController.didMove(toParent: self)
    }

    private func _swapToNewChildVC(child newChild: UIViewController & InterfaceDelegating) {
        childController.willMove(toParent: nil)
        childController.removeFromParent()
        childController.view.removeFromSuperview()

        view.addSubview(newChild.view)
        view.topAnchor.constraint(equalTo: newChild.view.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: newChild.view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: newChild.view.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: newChild.view.bottomAnchor).isActive = true
        addChild(newChild)
        newChild.didMove(toParent: self)
        childController = newChild
        childController.interfaceDelegate = self
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
