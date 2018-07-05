import UIKit
import Instantiate
import InstantiateStandard

final class TaskDetailViewController: UIViewController {
    // StoryboardInstantiatable
    typealias Dependency = Void

    override func viewDidLoad() {
        navigationItem.title = "詳細"
        let closeButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.close))
        closeButton.tintColor = UIColor.black
        closeButton.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 17, weight: .light)], for: .normal)
        navigationItem.leftBarButtonItem = closeButton
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.save))
        saveButton.tintColor = UIColor.black
        saveButton.setTitleTextAttributes([.foregroundColor: UIColor.lightGray, .font: UIFont.systemFont(ofSize: 17, weight: .light)], for: .disabled)
        navigationItem.rightBarButtonItem = saveButton
    }

    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func save() {
        close()
    }
}

extension TaskDetailViewController: StoryboardInstantiatable {
    func inject(_ dependency: Void) {}
}
