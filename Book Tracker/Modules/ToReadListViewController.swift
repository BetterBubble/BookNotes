
import UIKit

final class ToReadListViewController: UIViewController {
    
    // MARK: - Constants (метрики/цвета)
    private enum ReuseID { static let toReadCell = "ToReadBookCell" }
    private enum Metrics {
        static let viewBackgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1)
    }
    
    // MARK: - Data
    private var books: [Book] = []
    private var toReadBooks: [Book] {
        books.filter { $0.status == .toRead }
    }
    
    // MARK: - State
    private var isAdding = false
    private var headerFormView: UIView?
    private var tapGesture: UITapGestureRecognizer?
    private var editingBook: Book?
    
    // MARK: - Navigation
    weak var mainNavigationController: UINavigationController?

    // MARK: - UI
    private lazy var headerTitle: UILabel = {
        let title = UILabel()
        title.text = "Хочу прочитать"
        title.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        title.textAlignment = .center
        title.textColor = .darkGray
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.register(ToReadBookCell.self, forCellReuseIdentifier: ReuseID.toReadCell)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton()
        
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        
        button.setImage(image, for: .normal)
        button.tintColor = .darkGray
        button.backgroundColor = .systemOrange
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 28
        button.addTarget(self, action: #selector(addBook), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Metrics.viewBackgroundColor
        loadBooks()
        setupHeaderTitle()
        setupTableView()
        setupAddButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBooks() // Обновляем данные при возвращении на экран
    }
    
    // MARK: - Setup UI
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ToReadBookCell.self, forCellReuseIdentifier: ReuseID.toReadCell)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.tableHeaderView?.backgroundColor = .clear
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerTitle.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupHeaderTitle() {
        view.addSubview(headerTitle)
        
        NSLayoutConstraint.activate([
            headerTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            headerTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    private func setupAddButton() {
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor)
            
        ])
        view.bringSubviewToFront(addButton) // на всякий случай поверх tableView
        tableView.contentInset.bottom += 76 // чтобы FAB не перекрывал последнюю строку
    }
    
    // MARK: - Data Loading
    private func loadBooks() {
        books = BookStorage.shared.load()
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func addBook() {
        // 1) Развернуть sheet, если контроллер представлен как sheet
        expandSheetIfNeeded()
        // 2) Уже показано? — выходим
        guard !isAdding else { return }
        // 3) Очищаем режим редактирования (создаем новую книгу)
        editingBook = nil
        // 4) Показываем форму с анимацией
        showHeaderForm()
    }
    
    @objc private func commitAddFromHeader() {
        guard let header = headerFormView else { return }
        
        guard let titleField = header.viewWithTag(100) as? UITextField,
              let authorField = header.viewWithTag(101) as? UITextField,
              let noteView = header.viewWithTag(102) as? UITextView else { return }
        
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let author = authorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Обрабатываем заметки с учетом placeholder
        var note = ""
        if noteView.textColor != .placeholderText && !noteView.text.isEmpty {
            note = noteView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !title.isEmpty else {
            showAlert("Введите название книги")
            return
        }

        if let editingBook = editingBook {
            // Режим редактирования
            let updatedBook = Book(title: title, author: author, note: note, status: .toRead, id: editingBook.id, coverFilename: editingBook.coverFilename)
            
            // Находим и обновляем книгу
            if let index = books.firstIndex(where: { $0.id == editingBook.id }) {
                books[index] = updatedBook
                BookStorage.shared.saved(books)
                loadBooks() // Обновляем всю таблицу
            }
        } else {
            // Режим создания новой книги
            let book = Book(title: title, author: author, note: note, status: .toRead, id: UUID(), coverFilename: nil)
            books.append(book)
            BookStorage.shared.saved(books)
            
            // Обновляем таблицу с анимацией
            let newIndexPath = IndexPath(row: toReadBooks.count - 1, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
        
        hideHeaderForm()
    }
    
    @objc private func handleTapOutsideForm() {
        if isAdding {
            hideHeaderForm()
        }
    }
    
    // MARK: - Form (Header) Presentation
    private func showHeaderForm() {
        isAdding = true
        
        // Создаем форму
        let formView = makeHeaderFormView()
        headerFormView = formView
        
        // Устанавливаем начальную высоту 0 для анимации
        formView.frame.size.height = 0
        tableView.tableHeaderView = formView
        
        // Анимируем появление
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseInOut]) {
            self.layoutHeaderToFit()
        }
        
        // Настройки для скрытия формы
        tableView.keyboardDismissMode = .onDrag
        setupTapGesture()
    }
    
    private func makeHeaderFormView() -> UIView {
        let title = UITextField()
        title.placeholder = "Название"
        title.borderStyle = .roundedRect
        title.returnKeyType = .next
        title.tag = 100 // Для поиска поля
        title.delegate = self

        let author = UITextField()
        author.placeholder = "Автор"
        author.borderStyle = .roundedRect
        author.returnKeyType = .next
        author.tag = 101 // Для поиска поля
        author.delegate = self

        let note = UITextView()
        note.isScrollEnabled = false
        note.font = .systemFont(ofSize: 16)
        note.backgroundColor = .secondarySystemBackground
        note.layer.cornerRadius = 8
        note.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        note.tag = 102 // Для поиска поля
        note.delegate = self

        // Предзаполняем данные если редактируем книгу
        if let editingBook = editingBook {
            title.text = editingBook.title
            author.text = editingBook.author
            if !editingBook.note.isEmpty {
                note.text = editingBook.note
                note.textColor = .label
            } else {
                note.text = "Заметки (необязательно)"
                note.textColor = .placeholderText
            }
        } else {
            note.text = "Заметки (необязательно)"
            note.textColor = .placeholderText
        }

        let addBtn = UIButton(type: .system)
        // Меняем текст кнопки в зависимости от режима
        addBtn.setTitle(editingBook != nil ? "Исправить" : "Добавить", for: .normal)
        addBtn.backgroundColor = .systemBlue
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.layer.cornerRadius = 8
        addBtn.addTarget(self, action: #selector(commitAddFromHeader), for: .touchUpInside)

        // Верстаем через стек
        let stack = UIStackView(arrangedSubviews: [title, author, note, addBtn])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        // Контейнер для tableHeaderView
        let container = UIView()
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Сохраним, чтобы взять значения при сохранении
        container.accessibilityElements = [title, author, note] // простой способ достать позже
        return container
    }
    
    private func hideHeaderForm() {
        guard isAdding, let formView = headerFormView else { return }
        
        // Анимируем скрытие
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            formView.frame.size.height = 0
            self.tableView.tableHeaderView = formView
        } completion: { _ in
            self.isAdding = false
            self.headerFormView = nil
            self.tableView.tableHeaderView = nil
            self.editingBook = nil // Очищаем режим редактирования
            self.removeTapGesture()
        }
    }
    
    private func layoutHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let size = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        )
        if header.frame.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header // переустановить, чтобы таблица учла высоту
        }
    }
    
    private func expandSheetIfNeeded() {
        // Проверяем, представлен ли контроллер как sheet
        if let sheet = navigationController?.sheetPresentationController ?? sheetPresentationController {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = .large
            }
        }
    }
    
    // MARK: - Gestures
    private func setupTapGesture() {
        removeTapGesture() // Удаляем предыдущий, если есть
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideForm))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        tapGesture = gesture
    }
    
    private func removeTapGesture() {
        if let gesture = tapGesture {
            view.removeGestureRecognizer(gesture)
            tapGesture = nil
        }
    }
    
    // MARK: - Alerts
    private func showAlert(_ message: String) {
        let ac = UIAlertController(title: "Внимание", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    //MARK: - Animation
    private func emitPaper(from sourceView: UIView, in container: UIView) {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .point
        emitter.emitterSize = .zero

        // позиция — из центра удаляемой ячейки
        let origin = container.convert(sourceView.bounds, from: sourceView).center
        emitter.emitterPosition = origin

        // текстура «листочка»: маленький белый прямоугольник
        let paperImage = UIGraphicsImageRenderer(size: CGSize(width: 6, height: 8)).image { ctx in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 6, height: 8), cornerRadius: 1).fill()
            UIColor(white: 0, alpha: 0.08).setStroke()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 6, height: 8)).stroke()
        }

        let cell = CAEmitterCell()
        cell.contents = paperImage.cgImage
        cell.birthRate = 180
        cell.lifetime = 2.0
        cell.lifetimeRange = 0.5
        cell.velocity = 180
        cell.velocityRange = 100
        cell.emissionRange = .pi // во все стороны
        cell.scale = 1
        cell.scaleRange = 0.4
        cell.spin = 2
        cell.spinRange = 2
        cell.alphaSpeed = -0.6
        cell.yAcceleration = 220 // гравитация

        emitter.emitterCells = [cell]
        container.layer.addSublayer(emitter)

        // короткий «пшик»: выключаем рождение частиц через 0.15с, удаляем через 2.5с
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { emitter.removeFromSuperlayer() }
    }
}

// MARK: - Extension
extension ToReadListViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if isAdding { hideHeaderForm() }
    }
}

extension ToReadListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        toReadBooks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let book = toReadBooks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.toReadCell, for: indexPath)
        guard let cell = cell as? ToReadBookCell else { fatalError("Wrong cell type") }
        cell.configure(with: book)
        return cell
    }
    
    //Делегат Свайпов
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let book = toReadBooks[indexPath.row]
        
        let deleteImage = UIImage(systemName: "trash")
        let addImage = UIImage(systemName: "checkmark.circle")
        
        //Удилить
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, done in
            guard let self else { return }
            //Найти индекс в общем массиве
            if let i = self.books.firstIndex(where: { $0.id == book.id }) {
                // тактильная отдача
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if let cell = tableView.cellForRow(at: indexPath) {
                    emitPaper(from: cell.contentView, in: view)
                }
                // маленькая задержка, чтобы эмиттер успел родить частицы
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.books.remove(at: i)
                    BookStorage.shared.saved(self.books)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
            done(true)
        }
        delete.image = deleteImage
        
        // Добавить в прочитанное
        let add = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, done in
            guard let self else { return }
            
            // Сразу удаляем ячейку из UI (оптимистичное обновление)
            if let i = self.books.firstIndex(where: { $0.id == book.id }) {
                self.books.remove(at: i)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            // Создаем AddBookViewController
            let vc = AddBookViewController()
            vc.mode = .read
            vc.prefillTitle = book.title
            vc.prefillAuthor = book.author
            vc.prefillNote = book.note
            vc.prefillCoverFilename = book.coverFilename
            vc.prefillId = book.id
            
            vc.onSaved = { [weak self] savedBook in
                guard let self else { return }
                // Книга уже сохранена в AddBookViewController
                // Обновляем BookListViewController если есть ссылка
                if let mainNav = self.mainNavigationController,
                   let bookListVC = mainNav.topViewController as? BookListViewController {
                    bookListVC.loadBooks()
                }
            }
            
            // Сворачиваем sheet и открываем AddBookViewController в главном navigation controller
            self.dismiss(animated: true) {
                // После закрытия sheet открываем AddBookViewController
                if let mainNav = self.mainNavigationController {
                    mainNav.pushViewController(vc, animated: true)
                }
            }
            
            done(true)
        }
        add.image = addImage
        add.backgroundColor = UIColor.systemBlue
        
        let config = UISwipeActionsConfiguration(actions: [delete, add])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Убираем выделение ячейки
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Если форма уже показана, скрываем её
        if isAdding {
            hideHeaderForm()
            return
        }
        
        // Устанавливаем книгу для редактирования
        let book = toReadBooks[indexPath.row]
        editingBook = book
        
        // Показываем форму с предзаполненными данными
        showHeaderForm()
    }
}

extension ToReadListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Gesture recognizer должен работать только когда форма показана
        guard isAdding, let formView = headerFormView else { 
            // Если форма не показана, не перехватываем тапы - пусть работают ячейки
            return false 
        }
        
        let touchPoint = touch.location(in: view)
        let formFrame = formView.convert(formView.bounds, to: view)
        
        // Не скрываем форму, если тап по ней самой
        return !formFrame.contains(touchPoint)
    }
}

extension ToReadListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let formView = headerFormView else { return false }
        
        switch textField.tag {
        case 100: // title field
            if let authorField = formView.viewWithTag(101) as? UITextField {
                authorField.becomeFirstResponder()
            }
        case 101: // author field
            if let noteView = formView.viewWithTag(102) as? UITextView {
                noteView.becomeFirstResponder()
            }
        default:
            textField.resignFirstResponder()
        }
        
        return true
    }
}

extension ToReadListViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Заметки (необязательно)"
            textView.textColor = .placeholderText
        }
    }
}

private extension CGRect { var center: CGPoint { CGPoint(x: midX, y: midY) } }
