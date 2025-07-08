import Foundation

enum FileCache {
    private static func fileURL(for name: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent(name)
    }

    static func save<T: Encodable>(_ value: T, as fileName: String) {
        let url = fileURL(for: fileName)
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("FileCache save error for \(fileName): \(error)")
        }
    }

    static func load<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        let url = fileURL(for: fileName)
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("FileCache load error for \(fileName): \(error)")
            return nil
        }
    }
}
