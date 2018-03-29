import UIKit

final class KeyboardTextView: UIView {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
        commonInit()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if #available(iOS 11.0, *) {
            if let window = self.window {
                self.bottomAnchor.constraintLessThanOrEqualToSystemSpacingBelow(window.safeAreaLayoutGuide.bottomAnchor, multiplier: 1.0).isActive = true
            }
        }
    }

    private func loadNib() {
        let nib = UINib.init(nibName: "KeyboardTextView", bundle: nil)
        if let view = nib.instantiate(withOwner: self, options: nil).first as? UIView {
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            let bindings = ["view": view]
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                                          metrics: nil,
                                                                          views: bindings))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                                          metrics: nil,
                                                                          views: bindings))
        }
    }

    private func commonInit() {
        sendButton.layer.borderColor = UIColor.lightGray.cgColor
        sendButton.layer.borderWidth = 0.5
        sendButton.layer.cornerRadius = 8
        sendButton.setTitle("追加", for: .normal)
        textField.placeholder = "タスク"
    }
}
