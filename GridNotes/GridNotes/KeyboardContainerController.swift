//
//  KeyboardContainerController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/17/21.
//

import UIKit


protocol InterfaceChanging {
    func interfaceDidGetSelected(interface: UserInterface, state: AppState)
}

protocol InterfaceDelegating {
    var interfaceDelegate: InterfaceChanging? { get set }
}


// MARK: - KeyboardContainerController

class KeyboardContainerController: UIViewController, InterfaceChanging {

    var childController: (UIViewController & InterfaceDelegating)
    
    func interfaceDidGetSelected(interface: UserInterface, state: AppState) {
        switch interface {
        case .grid:
            if type(of: childController) != GridKeyboardViewController.self {
                let child = GridKeyboardViewController(state: state)
                _swapTo(newChildVC: child)
            }
        case .ring:
            if type(of: childController) != RingKeyboardViewController.self {
                let child = RingKeyboardViewController(state: state)
                _swapTo(newChildVC: child)
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

    private func _swapTo(newChildVC: UIViewController & InterfaceDelegating) {
        childController.willMove(toParent: nil)
        childController.removeFromParent()
        childController.view.removeFromSuperview()

        view.addSubview(newChildVC.view)
        newChildVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: newChildVC.view.topAnchor),
            view.leadingAnchor.constraint(equalTo: newChildVC.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: newChildVC.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: newChildVC.view.bottomAnchor),
        ])
        addChild(newChildVC)
        newChildVC.didMove(toParent: self)
        childController = newChildVC
        childController.interfaceDelegate = self
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
