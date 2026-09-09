//
//  Queue.swift
//  WidgetSoundboard
//
//  Created by Leo Mehlig on 18.08.23.
//

import Foundation

/// Runs tasks concurrently, while making sure a shared resource — the audio session — is set up
/// before the first task starts and torn down again once the last one has finished.
///
/// The queue has to survive tasks that go wrong, because it guards a process wide resource: if a
/// task were to keep its slot after it failed or was frozen, ``setup`` would never run again and
/// no sound would play until the app is force quit.
actor ConcurrentQueue<Context> {
    /// Tasks that have reserved a slot, but haven't started yet because the queue is still setting
    /// up. They count as running, so that a task finishing in the meantime doesn't tear the queue
    /// down while the setup is still in flight.
    private var reserved: Set<UUID> = []

    private var running: [UUID: Task<Void, Error>] = [:]

    /// Whether ``setup`` ran successfully and ``teardown`` still has to run.
    private var isSetUp: Bool = false

    private var setupTask: Task<Void, Error>?
    private var teardownTask: Task<Void, Never>?

    private let setup: (Context) async throws -> Void
    private let teardown: () async throws -> Void

    init(setup: @escaping (Context) async throws -> Void,
         teardown: @escaping () async throws -> Void) {
        self.setup = setup
        self.teardown = teardown
    }

    var isIdle: Bool {
        self.reserved.isEmpty && self.running.isEmpty
    }

    /// Runs `task`, setting the queue up for `context` first, if it isn't set up already.
    ///
    /// Throws when the setup fails or when `task` throws. A failing teardown is not reported,
    /// since the task itself did run to completion at that point.
    nonisolated func add(context: Context, _ task: @escaping () async throws -> Void) async throws {
        let id = UUID()
        try await self.reserve(id, for: context)
        // The task is only started once the setup succeeded, so a failing setup can't leave a task
        // running that the queue has lost track of.
        let runningTask = Task { try await task() }
        await self.register(runningTask, for: id)
        do {
            try await runningTask.value
        } catch {
            await self.finish(id)
            throw error
        }
        await self.finish(id)
    }

    func cancelAll() async {
        let tasks = Array(self.running.values)
        self.running.removeAll()
        self.reserved.removeAll()
        for task in tasks {
            task.cancel()
        }
        await self.tearDownIfIdle()
    }

    private func reserve(_ id: UUID, for context: Context) async throws {
        self.reserved.insert(id)
        do {
            try await self.setUpIfNeeded(for: context)
        } catch {
            self.reserved.remove(id)
            await self.tearDownIfIdle()
            throw error
        }
    }

    private func register(_ task: Task<Void, Error>, for id: UUID) {
        guard self.reserved.remove(id) != nil else {
            // ``cancelAll`` ran while the queue was still setting up.
            task.cancel()
            return
        }
        self.running[id] = task
    }

    private func finish(_ id: UUID) async {
        self.reserved.remove(id)
        self.running[id] = nil
        await self.tearDownIfIdle()
    }

    private func setUpIfNeeded(for context: Context) async throws {
        // Wait for a teardown that is still in flight, so that the session isn't deactivated right
        // after it was activated for this task.
        if let teardownTask = self.teardownTask {
            await teardownTask.value
        }
        if let setupTask = self.setupTask {
            // Another task is already setting the queue up, so wait for that instead of setting it
            // up a second time.
            try await setupTask.value
            return
        }
        guard !self.isSetUp else {
            return
        }
        let setupTask = Task { try await self.setup(context) }
        self.setupTask = setupTask
        defer { self.setupTask = nil }
        try await setupTask.value
        self.isSetUp = true
    }

    private func tearDownIfIdle() async {
        guard self.isIdle, self.isSetUp, self.setupTask == nil, self.teardownTask == nil else {
            return
        }
        self.isSetUp = false
        let teardownTask = Task {
            do {
                try await self.teardown()
            } catch {
                // Deactivating the audio session can fail while other audio is still winding down,
                // which is not a failure of the sound that just played. Reporting it would show an
                // error for a sound the user actually heard.
                print("Failed to tear down queue: \(error)")
            }
        }
        self.teardownTask = teardownTask
        await teardownTask.value
        self.teardownTask = nil
    }
}
