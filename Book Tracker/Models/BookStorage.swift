
//Модель

import Foundation

//Структура книги
enum BookStatus: String, Codable {case toRead, read }

struct Book: Codable {
    var title: String
    var author: String
    var note: String
    var status: BookStatus
    var id: UUID
    var coverFilename: String? // имя файла обложки в Documents (или nil)
}

//Хранилище
final class BookStorage {
    //Синголтон
    //Один-единственный экземпляр класса BookStorage и храним его
    //  в статическом свойстве shared.
    //Это паттерн Singleton — когда у нас есть только один объект,
    //  который управляет данными в приложении.
    //  Мы хотим, чтобы в любой части кода, где нужно загрузить или
    //  сохранить книги, использовался тот же самый экземпляр, а не создавались новые.
    static let shared = BookStorage()
    private init() {}

    private let key = "books_storage_v1"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    //функция для Загрузки книг
    func load() -> [Book] {
        guard let data = defaults.data(forKey: key) else { return [] }
        
        do {
            return try decoder.decode([Book].self, from: data)
        } catch {
            print("Decode error:", error)
            return []
        }
    }
    
    //функция для Сохранения книг
    func saved(_ books: [Book]) {
        do {
            let data = try encoder.encode(books)
            defaults.set(data, forKey: key)
            
            // Очищаем неиспользуемые обложки
            cleanupUnusedCovers(books: books)
        } catch {
            print("Encode error:", error)
        }
    }
    
    // Очистка неиспользуемых изображений обложек
    private func cleanupUnusedCovers(books: [Book]) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let coversPath = documentsPath.appendingPathComponent("covers")
        
        guard FileManager.default.fileExists(atPath: coversPath.path) else { return }
        
        do {
            let allCoverFiles = try FileManager.default.contentsOfDirectory(atPath: coversPath.path)
            let usedCoverFilenames = Set(books.compactMap { $0.coverFilename })
            
            for filename in allCoverFiles {
                if !usedCoverFilenames.contains(filename) {
                    let fileURL = coversPath.appendingPathComponent(filename)
                    try? FileManager.default.removeItem(at: fileURL)
                    print("Removed unused cover: \(filename)")
                }
            }
        } catch {
            print("Error cleaning up covers: \(error)")
        }
    }
}
