//
//  GridKeyboardViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


class GridKeyboardViewController: UIViewController, KeyRowDelegate {

    var rows: [KeyRow] = [KeyRow(), KeyRow(), KeyRow(), KeyRow(), KeyRow(), KeyRow(), KeyRow()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        let guide = view.layoutMarginsGuide
        for row in rows {
            view.addSubview(row)
            guide.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
            guide.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
        }
        guide.topAnchor.constraint(equalTo: rows.first!.topAnchor).isActive = true
        guide.bottomAnchor.constraint(equalTo: rows.last!.bottomAnchor).isActive = true
        for i in [0,1,2,3,4,5] {
            rows[i].bottomAnchor.constraint(equalTo: rows[i+1].topAnchor).isActive = true
        }
        for i in [1,2,3,4,5,6] {
            rows[i].heightAnchor.constraint(equalTo: rows[0].heightAnchor).isActive = true
        }
        for i in [6,5,4,3,2,1,0] {
            rows[i].noteOffset = ((6-i) * 12) + 24
        }
        for i in [0,1,2,3,4,5,6] {
            rows[i].delegate = self
        }

        initAudio()
    }
    
    func keyDidGetPressed(note: Int) {
        startNote(note: UInt8(note))
    }
    
    func keyDidGetReleased(note: Int) {
        endNote(note: UInt8(note))
    }
}


protocol KeyRowDelegate {
    func keyDidGetPressed(note: Int)
    func keyDidGetReleased(note: Int)
}


class KeyRow: UIView {
    var delegate: KeyRowDelegate? = nil
    
    var noteOffset: Int = 0
    
    let key1 = UIButton()
    let key2 = UIButton()
    let key3 = UIButton()
    let key4 = UIButton()
    let key5 = UIButton()
    let key6 = UIButton()
    let key7 = UIButton()
    let key8 = UIButton()
    let key9 = UIButton()
    let key10 = UIButton()
    let key11 = UIButton()
    let key12 = UIButton()

    var keys: [UIButton] {
        return [key1, key2, key3, key4, key5, key6, key7, key8, key9, key10, key11, key12]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        for k in keys {
            k.translatesAutoresizingMaskIntoConstraints = false
            addSubview(k)
            k.layer.borderWidth = 1
            k.layer.borderColor = UIColor.blue.cgColor
            k.addTarget(self, action: #selector(keyDidGetPressed(key:)), for: .touchDown)
            k.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchUpInside)
            k.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchDragExit)
            k.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchCancel)
        }
        
        for i in [0,1,2,3,4,5,6,7,8,9,10,11] {
            keys[i].tag = i
        }
        
        setNeedsUpdateConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var hasSetUpConstraints: Bool = false
    override func updateConstraints() {
        super.updateConstraints()
        if !hasSetUpConstraints {
            hasSetUpConstraints = true

            for k in keys {
                topAnchor.constraint(equalTo: k.topAnchor).isActive = true
                bottomAnchor.constraint(equalTo: k.bottomAnchor).isActive = true
            }

            leadingAnchor.constraint(equalTo: key1.leadingAnchor).isActive = true
            for i in [0,1,2,3,4,5,6,7,8,9,10] {
                keys[i+1].leadingAnchor.constraint(equalTo: keys[i].trailingAnchor).isActive = true
            }
            trailingAnchor.constraint(equalTo: key12.trailingAnchor).isActive = true

            for k in keys {
                key1.widthAnchor.constraint(equalTo: k.widthAnchor).isActive = true
            }
        }
    }

    @objc func keyDidGetPressed(key: UIButton) {
        key.backgroundColor = UIColor.yellow
        delegate?.keyDidGetPressed(note: noteOffset + key.tag)
    }
    
    @objc func keyDidGetReleased(key: UIButton) {
        key.backgroundColor = UIColor.clear
        delegate?.keyDidGetReleased(note: noteOffset + key.tag)
    }
}
