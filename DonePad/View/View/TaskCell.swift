import UIKit
import Instantiate
import InstantiateStandard

final class TaskCell: UITableViewCell {
    typealias Dependency = Task

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var deadlineLabel: UILabel!
    @IBOutlet weak var deadlineLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var warningImageView: UIImageView!

    private let doneImage = UIImage(named: "ic_done")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    private let boxImage = UIImage(named: "ic_checkbox")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
    private let warningImage = UIImage(named: "ic_warning")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)

    private var done: Bool = false {
        didSet {
            if done {
                check()
            } else {
                uncheck()
            }
        }
    }

    private let formatter = DateFormatter()

    func toggleTask() {
        setSelected(true, animated: true)
        done = !done
        setSelected(false, animated: true)
    }

    private func check() {
        if let attributedText = titleLabel.attributedText {
            let stringAttributes: [NSAttributedStringKey: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .strikethroughStyle: 2,
                .foregroundColor: UIColor.lightGray
            ]
            let string = NSAttributedString(string: attributedText.string, attributes: stringAttributes)
            titleLabel.attributedText = string
        }

        iconView.image = doneImage
        iconView.tintColor = UIColor.lightGray
        deadlineLabel.textColor = UIColor(red: 0.298, green: 0.298, blue: 0.298, alpha: 0.85)
        warningImageView.isHidden = true
    }

    private func uncheck() {
        if let attributedText = titleLabel.attributedText {
            let stringAttributes: [NSAttributedStringKey: Any] = [
                .font: UIFont.systemFont(ofSize: 20)
            ]
            let string = NSAttributedString(string: attributedText.string, attributes: stringAttributes)
            titleLabel.attributedText = string
        }

        iconView.image = boxImage
        iconView.tintColor = UIColor.gray
    }
}

extension TaskCell: Reusable, NibType {
    func inject(_ dependency: Task) {
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/M/d(EEE) HH:mm"
        titleLabel.text = dependency.title
        warningImageView.isHidden = true
        warningImageView.image = warningImage
        warningImageView.tintColor = UIColor.red
        if let deadline = dependency.deadline {
            let calendar = Calendar.current
            if calendar.isDate(Date(), inSameDayAs: deadline) {
                formatter.dateFormat = "HH:mm"
                deadlineLabel.text = "今日 " + formatter.string(from: deadline)
            } else {
                deadlineLabel.text = formatter.string(from: deadline)
            }
            deadlineLabel.isHidden = false
            deadlineLabelHeight.constant = 18
            if deadline.timeIntervalSinceNow < 0 && !dependency.done {
                deadlineLabel.textColor = UIColor.red
                warningImageView.isHidden = false
            }
        } else {
            deadlineLabel.isHidden = true
            deadlineLabelHeight.constant = 0
            deadlineLabel.textColor = UIColor(red: 0.298, green: 0.298, blue: 0.298, alpha: 0.85)
        }
        done = dependency.done
    }
}
