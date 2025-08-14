//
//  DetailBookViewController.swift
//  Book Tracker
//
//  Created by Александр Шульга on 06.08.2025.
//

import UIKit

final class DetailBookViewController: UIViewController {
    
    // MARK: - Constants (метрики/цвета)
    private enum Metrics {
        static let pageInset: CGFloat = 20
        static let cardInset: CGFloat = 24
        static let coverCardSize = CGSize(width: 180, height: 260)
        static let separatorH: CGFloat = 1
    }
    
    var book: Book?
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - UI
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Карточка для обложки
    private lazy var coverCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Карточка для информации о книге
    private lazy var infoCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.08
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemOrange
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Разделитель
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Заголовок для заметок
    private lazy var notesHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "📝 Мои заметки"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Карточка для заметок
    private lazy var notesCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.06
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        title = "Детали книги"
        
        setupUI()
        setupLayout()
        configureWithBook()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем размер градиента при изменении размера экрана
        gradientLayer?.frame = view.bounds
    }
    
    // MARK: - Configuration
    private func configureWithBook() {
        guard let book = book else { return }
        
        titleLabel.text = book.title
        authorLabel.text = book.author
        
        // Красиво форматируем заметки
        if book.note.isEmpty {
            noteLabel.text = "Заметки к этой книге пока не добавлены.\nВы можете добавить их при редактировании."
            noteLabel.textColor = .tertiaryLabel
            noteLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        } else {
            noteLabel.text = book.note
            noteLabel.textColor = .secondaryLabel
            noteLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
        
        // Загружаем обложку с красивым placeholder
        if let coverFilename = book.coverFilename {
            loadCoverImage(filename: coverFilename)
        } else {
            setupPlaceholderCover()
        }
    }
    
    // MARK: - Private
    private func setupUI() {
        // Добавляем основные элементы
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Добавляем карточки и элементы
        contentView.addSubview(coverCardView)
        coverCardView.addSubview(coverImageView)
        
        contentView.addSubview(infoCardView)
        infoCardView.addSubview(titleLabel)
        infoCardView.addSubview(authorLabel)
        infoCardView.addSubview(separatorView)
        
        contentView.addSubview(notesCardView)
        notesCardView.addSubview(notesHeaderLabel)
        notesCardView.addSubview(noteLabel)
        
    }
    
    private func setupLayout() {
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
            
            // Cover Card
            coverCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Metrics.pageInset),
            coverCardView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coverCardView.widthAnchor.constraint(equalToConstant: Metrics.coverCardSize.width),
            coverCardView.heightAnchor.constraint(equalToConstant: Metrics.coverCardSize.height),
            
            // Cover Image
            coverImageView.topAnchor.constraint(equalTo: coverCardView.topAnchor, constant: 12),
            coverImageView.leadingAnchor.constraint(equalTo: coverCardView.leadingAnchor, constant: 12),
            coverImageView.trailingAnchor.constraint(equalTo: coverCardView.trailingAnchor, constant: -12),
            coverImageView.bottomAnchor.constraint(equalTo: coverCardView.bottomAnchor, constant: -12),
            
            // Info Card
            infoCardView.topAnchor.constraint(equalTo: coverCardView.bottomAnchor, constant: Metrics.cardInset),
            infoCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.pageInset),
            infoCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.pageInset),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: infoCardView.topAnchor, constant: Metrics.cardInset),
            titleLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: Metrics.cardInset),
            titleLabel.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -Metrics.cardInset),
            
            // Author
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorLabel.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: Metrics.cardInset),
            authorLabel.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -Metrics.cardInset),
            
            // Separator
            separatorView.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: Metrics.pageInset),
            separatorView.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: Metrics.cardInset),
            separatorView.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -Metrics.cardInset),
            separatorView.heightAnchor.constraint(equalToConstant: Metrics.separatorH),
            separatorView.bottomAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: -Metrics.pageInset),
            
            // Notes Card
            notesCardView.topAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: Metrics.pageInset),
            notesCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.pageInset),
            notesCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.pageInset),
            notesCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Metrics.pageInset),
            
            // Notes Header
            notesHeaderLabel.topAnchor.constraint(equalTo: notesCardView.topAnchor, constant: Metrics.cardInset),
            notesHeaderLabel.leadingAnchor.constraint(equalTo: notesCardView.leadingAnchor, constant: Metrics.cardInset),
            notesHeaderLabel.trailingAnchor.constraint(equalTo: notesCardView.trailingAnchor, constant: -Metrics.cardInset),
            
            // Notes Content
            noteLabel.topAnchor.constraint(equalTo: notesHeaderLabel.bottomAnchor, constant: 16),
            noteLabel.leadingAnchor.constraint(equalTo: notesCardView.leadingAnchor, constant: Metrics.cardInset),
            noteLabel.trailingAnchor.constraint(equalTo: notesCardView.trailingAnchor, constant: -Metrics.cardInset),
            noteLabel.bottomAnchor.constraint(equalTo: notesCardView.bottomAnchor, constant: -Metrics.cardInset)
        ])
    }
    
    private func setupGradientBackground() {
        // Создаем красивый градиентный фон
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 1.0, green: 0.8, blue: 0.6, alpha: 1).cgColor,
            UIColor(red: 0.95, green: 0.85, blue: 0.7, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        
        self.gradientLayer = gradient
    }
    
    private func setupPlaceholderCover() {
        coverImageView.subviews.forEach { $0.removeFromSuperview() }
        // Создаем красивый placeholder
        coverImageView.backgroundColor = .systemGray6
        coverImageView.image = UIImage(systemName: "book.closed.fill")
        coverImageView.tintColor = .systemGray4
        coverImageView.contentMode = .scaleAspectFit
        
        // Добавляем подпись
        let placeholderLabel = UILabel()
        placeholderLabel.text = "Обложка\nне добавлена"
        placeholderLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        placeholderLabel.textColor = .systemGray3
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 2
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        coverImageView.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.centerXAnchor.constraint(equalTo: coverImageView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor, constant: Metrics.pageInset)
        ])
    }
    
    private func loadCoverImage(filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let coversPath = documentsPath.appendingPathComponent("covers")
        let imageURL = coversPath.appendingPathComponent(filename)
        
        if let image = UIImage(contentsOfFile: imageURL.path) {
            coverImageView.image = image
            coverImageView.backgroundColor = .clear
            coverImageView.contentMode = .scaleAspectFill
        } else {
            setupPlaceholderCover()
        }
    }
}
