import SwiftUI
import Defaults

struct GalleryBoard: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var symbol: String
    var color: Color
    var sounds: [GallerySound]

    init(id: UUID = .init(), title: String, symbol: String, color: Color, sounds: [GallerySound]) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.color = color
        self.sounds = sounds
    }

    public func set<Value>(_ keyPath: WritableKeyPath<Self, Value>, to value: Value) -> Self {
        var object = self
        object[keyPath: keyPath] = value
        return object
    }

    @discardableResult
    func save() -> Board {
        let sounds = self.sounds.map({ $0.save() })
        let board = Board(
            title: self.title,
            symbol: self.symbol,
            color: self.color,
            sounds: sounds.map(\.id),
            galleryID: self.id
        )
        Defaults[.boards].append(board)
        return board
    }

    static let klang: GalleryBoard = GalleryBoard(id: .init(uuidString: "b73e6da0-981c-47d3-bef4-63f1608c5a3b")!,
                                                  title: "Klang",
                                                  symbol: "🎵",
                                                  color: .red,
                                                  sounds: [
                                                    .init(id: .init(uuidString: "51c8f8dc-2764-4e3a-acd0-6e456cd9a5b7")!,
                                                          title: "Wait",
                                                          symbol: "🚦",
                                                          color: .green,
                                                          source: .init(string: "https://unorderly.io")!,
                                                          license: .ccAttribution,
                                                          file: "Klang/wait.mp3")
                                                  ])

    static let animals: GalleryBoard = GalleryBoard(id: .init(uuidString: "e3fd7f0b-9ffb-4f20-85b9-6af4a8dbca5f")!,
                                                    title: "Animals",
                                                    symbol: "😻",
                                                    color: .orange,
                                                    sounds: [
                                                        .init(id: .init(uuidString: "a0b519bb-9d00-4a8b-a9d7-3f56ee6061e8")!,
                                                              title: "Bird",
                                                              symbol: "🐦",
                                                              color: .blue,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/bird.mp3"),
                                                        .init(id: .init(uuidString: "1b6497e4-b334-4ddb-b759-9c02f93a9e7c")!,
                                                              title: "Cat",
                                                              symbol: "🐈",
                                                              color: .orange,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/cat.mp3"),
                                                        .init(id: .init(uuidString: "7adf344e-adb4-4111-b4b0-ac9ae7628762")!,
                                                              title: "Chicken",
                                                              symbol: "🐔",
                                                              color: .red,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/chicken.mp3"),
                                                        .init(id: .init(uuidString: "4cdefb60-ac80-4e04-829e-c034446f4a67")!,
                                                              title: "Cow",
                                                              symbol: "🐄",
                                                              color: .primary,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/cow.mp3"),
                                                        .init(id: .init(uuidString: "7cc49859-42c5-4d2d-b50d-57f6fab5073d")!,
                                                              title: "Dog",
                                                              symbol: "🐕",
                                                              color: .brown,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/dog.mp3"),
                                                        .init(id: .init(uuidString: "a1f1ad4a-e2db-4920-92a3-1ed3521431f4")!,
                                                              title: "Duck",
                                                              symbol: "🦆",
                                                              color: .green,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/duck.mp3"),
                                                        .init(id: .init(uuidString: "f627a4c3-a8ad-4084-8b04-5c60baca8034")!,
                                                              title: "Eagle",
                                                              symbol: "🦅",
                                                              color: .primary,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/eagle.mp3"),
                                                        .init(id: .init(uuidString: "a6623ac4-60ea-4c06-9041-df4bcec23495")!,
                                                              title: "Elephant",
                                                              symbol: "🐘",
                                                              color: .gray,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/elephant.mp3"),
                                                        .init(id: .init(uuidString: "b8f19638-8d0f-46a7-ae20-7f453fbe2e90")!,
                                                              title: "Frog",
                                                              symbol: "🐸",
                                                              color: .green,
                                                              source: URL(string: "https://notificationsounds.com")!,
                                                              license: .ccAttribution,
                                                              file: "Animals/frog.mp3"),
                                                        .init(id: .init(uuidString: "7ff8d6c2-cf8b-45ee-a5ac-39859a200464")!,
                                                              title: "Horse",
                                                              symbol: "🐎",
                                                              color: .brown,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/horse.mp3"),
                                                        .init(id: .init(uuidString: "91f3ca8d-a1b7-4e0b-b566-8b488d31614f")!,
                                                              title: "Lion",
                                                              symbol: "🦁",
                                                              color: .orange,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/lion.mp3"),
                                                        .init(id: .init(uuidString: "8f062b2b-48a3-4a3e-a517-2715b17404ea")!,
                                                              title: "Mouse",
                                                              symbol: "🐭",
                                                              color: .gray,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/mouse.mp3"),
                                                        .init(id: .init(uuidString: "6321694f-cfea-4e49-a020-d6453f00b399")!,
                                                              title: "Pig",
                                                              symbol: "🐷",
                                                              color: .pink,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/pig.mp3"),
                                                        .init(id: .init(uuidString: "a9b8c8e3-ae1b-443c-a06a-d3c2f2a3a934")!,
                                                              title: "Seagulls",
                                                              symbol: "🌊",
                                                              color: .blue,
                                                              source: URL(string: "https://notificationsounds.com")!,
                                                              license: .ccAttribution,
                                                              file: "Animals/seagulls.mp3"),
                                                        .init(id: .init(uuidString: "2c2f59ae-9e4b-4b5c-9945-ee8dde345c8b")!,
                                                              title: "Sheep",
                                                              symbol: "🐑",
                                                              color: .primary,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/sheep.mp3"),
                                                        .init(id: .init(uuidString: "513c1f8b-6f14-4a48-a4e4-a6f69a899f8c")!,
                                                              title: "Snake",
                                                              symbol: "🐍",
                                                              color: .green,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/snake.mp3"),
                                                        .init(id: .init(uuidString: "25e0d607-3b10-48e6-8b79-de0c63fc47f9")!,
                                                              title: "Tiger",
                                                              symbol: "🐅",
                                                              color: .orange,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/tiger.mp3"),
                                                        .init(id: .init(uuidString: "1b14d06d-75d8-4f12-8f37-1e975f2f5df3")!,
                                                              title: "Wolf",
                                                              symbol: "🐺",
                                                              color: .gray,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/wolf.mp3"),
                                                        .init(id: .init(uuidString: "0757d267-bd73-4b7a-a9c3-91415f26020c")!,
                                                              title: "Dinosaur",
                                                              symbol: "🦖",
                                                              color: .green,
                                                              source: URL(string: "https://freesound.org")!,
                                                              license: .cc0,
                                                              file: "Animals/dinosaur.mp3")
                                                    ])


    static let all: [GalleryBoard] = [klang, animals]
}
