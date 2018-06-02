import UIKit
import RxSwift
import RxCocoa

final class MemoViewController: UIViewController {
    private var viewModel: MemoViewModel! {
        didSet {
            navigationItem.title = viewModel.title
            saveMemoId()
            tableView.reloadData()
        }
    }
    private var accessoryView: KeyboardTextView!
    private let disposeBag = DisposeBag()

    private var editingIndex: IndexPath?

    let animator = ZoomInAnimator()

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var shadowView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO gestureをセットする
        shadowView.isHidden = true

        let defaults = UserDefaults.standard
        if let id = defaults.value(forKey: "memoId") as? String {
            viewModel = MemoViewModel(from: id)
        } else {
            viewModel = MemoViewModel(from: "")
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset.bottom = 50
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension

        tableView.registerNib(type: TaskCell.self)

        accessoryView = KeyboardTextView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        accessoryView.delegate = self

        bind()

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 30, weight: .black),
            NSAttributedStringKey.foregroundColor: UIColor.black
        ]
        setupNavigationItems()

        // キーボードイベント検知
        NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillShow, object: nil)
            .bind { [unowned self] notification in
                self.keyboardWillShow(notification)
            }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(NSNotification.Name.UIKeyboardWillHide, object: nil)
            .bind { [unowned self] notification in
                self.keyboardWillHide(notification)
            }
            .disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        editingIndex = nil
        viewModel.reload()
        navigationItem.title = viewModel.title
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        accessoryView.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var inputAccessoryView: UIView? {
        return accessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private func bind() {
        accessoryView.tapAction = { [weak self] (text: String) in
            if let index = self?.editingIndex {
                self?.editTask(at: index, title: text)
            } else {
                self?.addTask(title: text)
            }
        }
    }

    private func saveMemoId() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "memoId")
        defaults.setValue(viewModel.memoId, forKey: "memoId")
    }

    private func clearMemoId() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "memoId")
    }

    private func addTask(title: String, completion: (() -> Void) = {}) {
        guard title.isNotEmpty else { return }

        tableView.beginUpdates()
        viewModel.addTask(title: title)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.reloadSections([0], with: .automatic)
        tableView.endUpdates()
        completion()
    }

    private func editTask(at indexPath: IndexPath, title: String) {
        guard title.isNotEmpty else { return }
        viewModel.editTask(at: indexPath.row, title: title)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    @objc private func tapTrashButton() {
        accessoryView.isHidden = true
        accessoryView.hideKeyboard()
        editingIndex = nil
        shadowView.isHidden = true

        let alert = UIAlertController(title: "削除しますか？", message: nil, preferredStyle: .actionSheet)
        let deleteAll = UIAlertAction(title: "メモごと削除する", style: .default, handler: {[unowned self] _ in
            self.viewModel.delete()
            self.clearMemoId()
            self.showMemoList()
        })
        let deleteDone = UIAlertAction(title: "チェック済タスクを削除する", style: .default, handler: {[unowned self] _ in
            self.viewModel.deleteDone()
            self.tableView.reloadData()
            self.accessoryView.isHidden = false
        })
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel, handler: {[unowned self] _ in
           self.accessoryView.isHidden = false
        })
        alert.addAction(deleteAll)
        alert.addAction(deleteDone)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }

    @objc private func showMemoList() {
        accessoryView.isHidden = true
        let vc = MemoCollectionViewController(with: { memo in
            self.viewModel = memo
        })
        accessoryView.hideKeyboard()
        let navi = UINavigationController(rootViewController: vc)
        navi.transitioningDelegate = self
        navigationController?.present(navi, animated: true, completion: nil)
    }

    @objc private func showSettings() {
        accessoryView.isHidden = true
        accessoryView.hideKeyboard()
        editingIndex = nil
        shadowView.isHidden = true

        let vm = MemoSettingsViewModel(from: viewModel.memoId)
        let vc = MemoSettingsViewController(with: vm)
        let navi = UINavigationController(rootViewController: vc)
        navigationController?.present(navi, animated: true, completion: nil)
    }

    private func setupNavigationItems() {
        var barItems: [UIBarButtonItem] = []

        let trashButton = UIButton()
        trashButton.addTarget(self, action: #selector(self.tapTrashButton), for: .touchUpInside)
        trashButton.setImage(UIImage(named: "ic_delete")?.withRenderingMode(.alwaysTemplate), for: .normal)
        trashButton.tintColor = UIColor.black
        let trash = UIBarButtonItem(customView: trashButton)
        barItems.append(trash)

        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 11
        barItems.append(space)

        let settingButton = UIButton()
        settingButton.addTarget(self, action: #selector(self.showSettings), for: .touchUpInside)
        settingButton.setImage(UIImage(named: "ic_setting")?.withRenderingMode(.alwaysTemplate), for: .normal)
        settingButton.tintColor = UIColor.black
        let setting = UIBarButtonItem(customView: settingButton)
        barItems.append(setting)
        navigationItem.rightBarButtonItems = barItems
    }

    @IBAction func tapListButton(_ sender: Any) {
        showMemoList()
    }

    func keyboardWillShow(_ notification: Notification) {
        guard let indexPath = editingIndex,
            let cell = tableView.cellForRow(at: indexPath) else { return }
        if let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue, let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue {

            tableView.contentInset = UIEdgeInsets.zero
            tableView.scrollIndicatorInsets = UIEdgeInsets.zero

            let convertedKeyboardFrame = tableView.convert(keyboardFrame, from: nil)

            let offsetY: CGFloat = cell.frame.maxY - convertedKeyboardFrame.minY - accessoryView.frame.height
            if offsetY > 0 {
                UIView.beginAnimations("ResizeForKeyboard", context: nil)
                UIView.setAnimationDuration(animationDuration)

                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: offsetY, right: 0)
                tableView.contentInset = contentInsets
                tableView.scrollIndicatorInsets = contentInsets
                tableView.contentOffset = CGPoint(x: 0, y: tableView.contentOffset.y + offsetY)

                UIView.commitAnimations()
            }
        }
    }

    func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
}

extension MemoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfTasks
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let task = viewModel.task(at: indexPath.row) else { return UITableViewCell() }
        let cell = TaskCell.dequeue(from: tableView, for: indexPath, with: task)
        cell.tapAction = {[weak self] (text: String) -> Void in
            let index = self?.tableView.indexPath(for: cell)
            self?.tableView.selectRow(at: index, animated: true, scrollPosition: .bottom)
            self?.editingIndex = indexPath
            self?.accessoryView.title = text
            self?.accessoryView.textField.returnKeyType = .done
            self?.accessoryView.showKeyboard()
        }
        return cell
    }
}

extension MemoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TaskCell else { return }
        accessoryView.hideKeyboard()
        cell.toggleTask()
        viewModel.toggleDone(at: indexPath.row)
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        accessoryView.hideKeyboard()
        return "削除"
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, viewModel.numberOfTasks > indexPath.row {
            tableView.beginUpdates()
            viewModel.deleteTask(at: indexPath.row)
            tableView.reloadSections([0], with: .automatic)
            tableView.endUpdates()
        }
    }
}

extension MemoViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        shadowView.isHidden = false

        guard viewModel.numberOfTasks > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        shadowView.isHidden = true
        resetEditing()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        if let index = editingIndex {
            editTask(at: index, title: text)
            textField.returnKeyType = .next
            textField.resignFirstResponder()
            resetEditing()
        } else {
            addTask(title: text)
            textField.text = ""
        }

        return true
    }

    private func resetEditing() {
        editingIndex = nil
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: true)
        }
        accessoryView.hideKeyboard()
    }
}

extension MemoViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
