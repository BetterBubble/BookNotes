import UIKit

final class BookCell: UICollectionViewCell {
    
    //MARK: - UI
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.image = UIImage(systemName: "book") // Placeholder
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.font = .systemFont(ofSize: 14, weight: .medium)
        title.textAlignment = .center
        title.numberOfLines = 2
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    //MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(systemName: "book")
        titleLabel.text = nil
    }
    
    //MARK: - UI Setup
    private func setupUI() {
        // Настройка внешнего вида
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        contentView.clipsToBounds = true

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
    }
    
    //MARK: - Layout Setup
    private func setupLayout() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    //MARK: - Configuration
    func configure(with book: Book) {
        titleLabel.text = book.title
        
        // Загружаем обложку книги
        if let coverFilename = book.coverFilename {
            loadCoverImage(filename: coverFilename)
        } else {
            imageView.image = UIImage(systemName: "book")
        }
    }
    
    //MARK: - Data load
    private func loadCoverImage(filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let coversPath = documentsPath.appendingPathComponent("covers")
        let imageURL = coversPath.appendingPathComponent(filename)
        
        if let image = UIImage(contentsOfFile: imageURL.path) {
            imageView.image = image
        } else {
            imageView.image = UIImage(systemName: "book")
        }
    }
}
