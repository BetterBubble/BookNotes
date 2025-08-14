import UIKit

final class BookListViewController: UIViewController {
    
    // MARK: - Constants
    private enum Metrics {
        static let viewBackgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1)
    }
    
    // MARK: - Data
    private var books: [Book] = []
    private var readBooks: [Book] {
        books.filter { $0.status == .read }
    }
    
    //MARK: - UI
    private lazy var toReadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "list.bullet.rectangle.portrait.fill"), for: .normal)
        button.tintColor = .darkGray
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 32, weight: .regular),
            forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(pushToReadPage), for: .touchUpInside)
        return button
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .darkGray
        button.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 32, weight: .regular),
            forImageIn: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addTarget(self, action: #selector(pushToAddBookPage), for: .touchUpInside)
        return button
    }()
    
    private lazy var headerTitle: UILabel = {
        let title = UILabel()
        title.text = "Моя библиотека"
        title.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        title.textAlignment = .center
        title.textColor = .darkGray
        return title
    }()
    
    private lazy var stackHeader: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [toReadButton, headerTitle, addButton])
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        //Настраиваем лэйаут внутри стэка. Включаем поддержку внутренних отступов
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        return stack
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [stackHeader, collectionView])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var collectionView: UICollectionView = {
        //Настройка Layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        //Настройка Коллекции
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: "BookCell")
        
        //Переход на детальную страницу
        collectionView.delegate = self
        return collectionView
    }()
    
    //MARK: - Actions
    @objc private func pushToReadPage() {
        let toReadListViewController = ToReadListViewController()
        toReadListViewController.mainNavigationController = navigationController // Передаем ссылку
        
        // Оборачиваем в navigation controller для возможности push
        let navController = UINavigationController(rootViewController: toReadListViewController)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    @objc private func pushToAddBookPage() {
        let addBookViewController = AddBookViewController()
        addBookViewController.mode = .read
        
        addBookViewController.onSaved = { [weak self] savedBook in
            // Книга уже сохранена в AddBookViewController, просто обновляем UI
            self?.loadBooks()
        }
        
        navigationController?.pushViewController(addBookViewController, animated: true)
    }

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadBooks()
        setupUI()
        setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 16
            let width = view.bounds.width
            let itemWidth = (width - spacing * 3) / 2
            flow.itemSize = CGSize(width: itemWidth, height: itemWidth + 40)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBooks() // Обновляем данные при возвращении на экран
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateVisibleCells()
    }
    
    //MARK: UI Setup
    private func setupUI() {
        view.backgroundColor = Metrics.viewBackgroundColor
        view.addSubview(mainStackView)
    }
    
    //MARK: Layout Setup
    private func setupLayout() {
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    //MARK: Data load
    func loadBooks() {
        books = BookStorage.shared.load()
        collectionView.reloadData()
        animateVisibleCells()
    }
    
    //MARK: Animation
    
    private func animateVisibleCells() {
        let cells = collectionView.visibleCells
        for (i, cell) in cells.enumerated() {
            let delay = 0.01 * Double(i)

            // начальное состояние
            cell.layer.opacity = 0
            cell.layer.transform = CATransform3DConcat(
                CATransform3DMakeScale(0.92, 0.92, 1),
                CATransform3DMakeTranslation(0, 14, 0)
            )

            // пружина по scale+position
            let spring = CASpringAnimation(keyPath: "transform")
            spring.damping = 12
            spring.stiffness = 180
            spring.mass = 1
            spring.initialVelocity = 0.6
            spring.fromValue = cell.layer.transform
            spring.toValue = CATransform3DIdentity
            spring.beginTime = CACurrentMediaTime() + delay
            spring.fillMode = .forwards
            spring.isRemovedOnCompletion = true
            spring.duration = spring.settlingDuration

            // плавный fade-in
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0
            fade.toValue = 1
            fade.duration = 0.18
            fade.beginTime = spring.beginTime

            // финальные значения на слое
            cell.layer.opacity = 1
            cell.layer.transform = CATransform3DIdentity

            cell.layer.add(spring, forKey: "springIn")
            cell.layer.add(fade, forKey: "fadeIn")
        }
    }
}


//MARK: Extension (Delegate / DataSource)
//Делегат для перехода на детальную страницу
extension BookListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let book = readBooks[indexPath.item]
        let detailVC = DetailBookViewController()
        detailVC.book = book
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// Подключаем dataSource
extension BookListViewController: UICollectionViewDataSource {
    //Колличество элементов
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        readBooks.count
    }
    
    //Содержание элементов
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCell", for: indexPath) as! BookCell
        let book = readBooks[indexPath.item]
        cell.configure(with: book)
        return cell
    }
}
