
import UIKit

final class ToReadBookCell: UITableViewCell {
    
    // MARK: - Constants (метрики/цвета)
    private enum Metrics {
        static let cardRadius: CGFloat = 12
        static let coverW: CGFloat = 50
        static let coverH: CGFloat = 70
        static let vSpacing: CGFloat = 12
        static let hSpacing: CGFloat = 12
    }
    
    // MARK: - UI
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        title.textColor = .label
        title.numberOfLines = 2
        return title
    }()
    
    private lazy var authorLabel: UILabel = {
        let author = UILabel()
        author.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        author.textColor = .secondaryLabel
        author.numberOfLines = 1
        return author
    }()
    
    private lazy var noteLabel: UILabel = {
        let note = UILabel()
        note.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        note.textColor = .darkGray
        note.numberOfLines = 3
        return note
    }()
    
    private lazy var cardView: UIView = {
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = Metrics.cardRadius
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.1
        card.layer.shadowRadius = 4
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()
    
    private lazy var coverImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = 6
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        image.tintColor = .systemGray3
        image.backgroundColor = .systemGray5
        image.image = UIImage(systemName: "book.closed.fill")
        return image
    }()
    
    private lazy var textStack: UIStackView = {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, authorLabel, noteLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        return textStack
    }()
    
    private lazy var contentStack: UIStackView = {
        let mainStack = UIStackView(arrangedSubviews: [coverImageView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        return mainStack
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        authorLabel.text = nil
        noteLabel.text = nil
        coverImageView.image = UIImage(systemName: "book.closed.fill")
        coverImageView.backgroundColor = .systemGray5
    }
    
    // MARK: - Configuration
    func configure(with book: Book) {
        titleLabel.text = book.title
        authorLabel.text = book.author
        noteLabel.text = book.note.isEmpty ? "Нет заметок" : book.note
    }
    
    // MARK: - Private
    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(cardView)
        cardView.addSubview(contentStack)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            // Отступы карточки от краев ячейки
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.hSpacing),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.hSpacing),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Размер иконки
            coverImageView.widthAnchor.constraint(equalToConstant: Metrics.coverW),
            coverImageView.heightAnchor.constraint(equalToConstant: Metrics.coverH),
            
            // Отступы элементов внтури карточки
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Metrics.hSpacing),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -Metrics.hSpacing),
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Metrics.vSpacing),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -Metrics.vSpacing)
        ])
    }
}
