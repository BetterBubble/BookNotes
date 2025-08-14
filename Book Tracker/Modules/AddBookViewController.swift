
import UIKit
import PhotosUI

final class AddBookViewController: UIViewController {
    
    // MARK: - Types / Constants
    enum AddMode { case toRead, read }
    
    private enum Metrics {
        static let pageInset: CGFloat = 20
        static let fieldHeight: CGFloat = 44
        static let coverSize = CGSize(width: 120, height: 160)
        static let corner: CGFloat = 12
    }
    
    // MARK: - State
    var mode: AddMode = .toRead
    var prefillTitle: String?
    var prefillAuthor: String?
    var prefillNote: String?
    var prefillId: UUID?
    var prefillCoverFilename: String?
    private var selectedCoverFilename: String?
    private let noteTemplate = """
    О чем книга?

    Главные выводы книги?

    Чему меня научила книга?

    Что я изменю в жизни, потому что понял из книги, что это нужно?

    Комментарии:
    
    """
    
    //MARK: - Callback
    var onSaved: ((Book) -> Void)?
    
    //MARK: - UI
    private lazy var titleField: UITextField = {
        let title = UITextField()
        title.placeholder = "Название"
        title.borderStyle = .roundedRect
        title.returnKeyType = .next
        
        title.text = prefillTitle
        
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    private lazy var authorField: UITextField = {
        let author = UITextField()
        author.placeholder = "Автор"
        author.borderStyle = .roundedRect
        author.returnKeyType = .next
        
        author.text = prefillAuthor
        
        author.translatesAutoresizingMaskIntoConstraints = false
        return author
    }()
    
    private lazy var coverView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray5
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.separator.cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var coverButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Добавить обложку", for: .normal)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 8
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(changeCoverTapped), for: .touchUpInside)
        return b
    }()
    
    private lazy var noteTitle: UILabel = {
        let title = UILabel()
        title.text = "Заметка о прочитанном"
        title.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        title.textColor = .lightGray
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    private lazy var noteField: UITextView = {
        let note = UITextView()
        note.isScrollEnabled = true
        note.font = .systemFont(ofSize: 16)
        note.backgroundColor = .secondarySystemBackground
        note.layer.cornerRadius = 8
        note.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        note.clipsToBounds = true
        note.layer.borderWidth = 1
        note.layer.borderColor = UIColor.separator.cgColor
        
        note.text = noteTemplate
        
        note.translatesAutoresizingMaskIntoConstraints = false
        return note
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .onDrag
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1)
        // Устанавливаем заголовок в зависимости от режима
        if mode == .toRead {
            title = prefillId != nil ? "Редактировать книгу" : "Книга к прочтению"
        } else {
            title = prefillId != nil ? "Добавить прочитанную" : "Добавить прочитанную"
        }
        
        setupUI()
        sutupLayout()
        setupButton()
        setupCoverImage()
        setupKeyboardDismiss()
        
        titleField.delegate = self
        authorField.delegate = self
    }
    
    //MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Добавляем все элементы в contentView
        contentView.addSubview(titleField)
        contentView.addSubview(authorField)
        contentView.addSubview(coverView)
        contentView.addSubview(coverButton)
        contentView.addSubview(noteTitle)
        contentView.addSubview(noteField)
    }
    
    private func setupButton() {
        let save = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(saveTapped))
        save.isEnabled = !(prefillTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        navigationItem.rightBarButtonItem = save

        titleField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func setupCoverImage() {
        // префилл обложки при редактировании
        selectedCoverFilename = prefillCoverFilename
        if let name = selectedCoverFilename {
            loadCoverImage(filename: name)
        }
    }
    
    //MARK: - Layout Setup
    private func sutupLayout() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Field
            titleField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleField.heightAnchor.constraint(equalToConstant: 44),
            
            // Author Field
            authorField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 16),
            authorField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            authorField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            authorField.heightAnchor.constraint(equalToConstant: 44),
            
            // Cover Image
            coverView.topAnchor.constraint(equalTo: authorField.bottomAnchor, constant: 24),
            coverView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverView.widthAnchor.constraint(equalToConstant: 120),
            coverView.heightAnchor.constraint(equalToConstant: 160),
            
            // Cover Button
            coverButton.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: 12),
            coverButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverButton.widthAnchor.constraint(equalToConstant: 180),
            coverButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Note Title
            noteTitle.topAnchor.constraint(equalTo: coverButton.bottomAnchor, constant: 32),
            noteTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            noteTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Note Field
            noteField.topAnchor.constraint(equalTo: noteTitle.bottomAnchor, constant: 12),
            noteField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            noteField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            noteField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            noteField.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    //MARK: - Data loading
    private func loadCoverImage(filename: String) {
        let url = coversDirectory().appendingPathComponent(filename)
        if let img = UIImage(contentsOfFile: url.path) {
            coverView.image = img
            coverView.backgroundColor = .clear
        }
    }
    
    //MARK: - Present
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Actions
    @objc private func titleChanged() {
        let nonEmpty = !(titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = nonEmpty
    }
    
    @objc private func saveTapped() {
        let title  = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (authorField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let note = (noteField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            showAlert("Введите название книги")
            return
        }
        
        let id = prefillId ?? UUID()
        let status: BookStatus = (mode == .toRead) ? .toRead : .read
        let book = Book(title: title, author: author, note: note, status: status, id: id, coverFilename: selectedCoverFilename)
        
        // Сохраняем книгу в BookStorage
        var allBooks = BookStorage.shared.load()
        
        if let existingIndex = allBooks.firstIndex(where: { $0.id == book.id }) {
            // Обновляем существующую книгу
            allBooks[existingIndex] = book
        } else {
            // Добавляем новую книгу
            allBooks.append(book)
        }
        
        BookStorage.shared.saved(allBooks)
        
        // Вызываем callback
        onSaved?(book)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func changeCoverTapped() {
        let ac = UIAlertController(title: "Обложка", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            ac.addAction(UIAlertAction(title: "Сделать фото", style: .default) { _ in
                self.presentCamera()
            })
        }
        ac.addAction(UIAlertAction(title: "Выбрать из фото", style: .default) { _ in
            self.presentPhotoPicker()
        })
        if selectedCoverFilename != nil {
            ac.addAction(UIAlertAction(title: "Удалить обложку", style: .destructive) { _ in
                self.selectedCoverFilename = nil
                self.coverView.image = nil
                self.coverView.backgroundColor = .systemGray5
            })
        }
        ac.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(ac, animated: true)
    }

    // MARK: - Alerts
    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: "Внимание", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    //MARK: - Private
    private func applySelected(image: UIImage) {
        // обновим превью
        coverView.image = image
        coverView.backgroundColor = .clear

        // сохраним на диск (jpeg)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            showAlert("Не удалось обработать изображение")
            return
        }
        
        let filename = "cover_\(UUID().uuidString).jpg"
        let url = coversDirectory().appendingPathComponent(filename)
        
        do {
            try FileManager.default.createDirectory(at: coversDirectory(), withIntermediateDirectories: true)
            
            // Удаляем старую обложку, если есть
            if let oldFilename = selectedCoverFilename {
                let oldURL = coversDirectory().appendingPathComponent(oldFilename)
                try? FileManager.default.removeItem(at: oldURL)
            }
            
            try data.write(to: url)
            self.selectedCoverFilename = filename
        } catch {
            print("save cover error:", error)
            showAlert("Ошибка сохранения изображения: \(error.localizedDescription)")
        }
    }

    private func coversDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("covers", isDirectory: true)
    }
    
}

// MARK: - Extension (Delegate)
extension AddBookViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === titleField { authorField.becomeFirstResponder() }
        else { noteField.becomeFirstResponder() }
        return true
    }
}

extension AddBookViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else { return }
        item.loadObject(ofClass: UIImage.self) { [weak self] obj, error in
            guard let self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert("Ошибка загрузки изображения: \(error.localizedDescription)")
                }
                return
            }
            
            guard let image = obj as? UIImage else {
                DispatchQueue.main.async {
                    self.showAlert("Не удалось загрузить изображение")
                }
                return
            }
            DispatchQueue.main.async {
                self.applySelected(image: image)
            }
        }
    }
}

extension AddBookViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = (info[.editedImage] ?? info[ .originalImage ]) as? UIImage
        picker.dismiss(animated: true) {
            if let img = image { self.applySelected(image: img) }
        }
    }
}
