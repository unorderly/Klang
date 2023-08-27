//
//  Queue.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import Foundation

actor ConcurrentQueue {
    var running: [UUID: Task<Void, Error>] = [:]
    var setup: () async throws -> Void
    var teardown: () async throws -> Void

    init(setup: @escaping () async throws -> Void, teardown: @escaping () async throws -> Void) {
        self.setup = setup
        self.teardown = teardown
    }
    nonisolated func add(_ task: @escaping () async throws -> Void) async throws {
        let uuid = UUID()
        let task = Task {
            try await task()
        }
        try await self.start(task: task, with: uuid)
        do {
            try await task.value
            try await self.endTask(with: uuid)
        } catch {
            try await self.endTask(with: uuid)
            throw error
        }
    }

    private func start(task: Task<Void, Error>, with uuid: UUID) async throws {
        if self.running.isEmpty {
            try await self.setup()
        }
        self.running[uuid] = task
    }

    private func endTask(with uuid: UUID) async throws {
        guard self.running[uuid] != nil else {
            return
        }
        self.running[uuid] = nil
        if self.running.isEmpty {
            try await self.teardown()
        }
    }

    func cancelAll() {
        self.running.values.forEach({ $0.cancel() })
        self.running.removeAll()
    }
}
