//
//  WidgetSoundboardTests.swift
//  WidgetSoundboardTests
//
//  Created by Leo Mehlig on 07.06.23.
//

import XCTest
import AVFoundation
@testable import Klang

final class WidgetSoundboardTests: XCTestCase {

    // MARK: - Audio Session Configuration

    func testOverlaySoundsMixWithOtherAudio() throws {
        let configuration = AudioPlayer.Configuration(isOverlay: true)
        XCTAssertEqual(configuration.mode, .voicePrompt)
        XCTAssertTrue(configuration.options.contains(.duckOthers))
        XCTAssertTrue(configuration.options.contains(.interruptSpokenAudioAndMixWithOthers))
        XCTAssertTrue(configuration.options.contains(.mixWithOthers),
                      "Both options imply mixWithOthers, which is what plays the sound over other audio")
    }

    func testDefaultSoundsInterruptOtherAudio() throws {
        let configuration = AudioPlayer.Configuration(isOverlay: false)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertTrue(configuration.options.isEmpty)
    }

    // MARK: - Queue

    /// A sound whose session couldn't be activated must not leave anything behind, otherwise the
    /// session is never set up again and no sound plays until the app is force quit.
    func testFailingSetupDoesNotStartTheTaskAndIsRetried() async throws {
        let session = TestSession(shouldFailSetup: true)
        let queue = ConcurrentQueue<Bool>(setup: { try await session.setUp(for: $0) },
                                          teardown: { try await session.tearDown() })

        do {
            try await queue.add(context: true) { await session.run() }
            XCTFail("Expected the setup to fail")
        } catch {
            // Expected.
        }

        var taskCount = await session.taskCount
        XCTAssertEqual(taskCount, 0, "The sound must not play when the session couldn't be activated")
        var teardownCount = await session.teardownCount
        XCTAssertEqual(teardownCount, 0, "There is nothing to tear down after a failed setup")
        var isIdle = await queue.isIdle
        XCTAssertTrue(isIdle, "A failed setup must not leave a slot behind")

        await session.setShouldFailSetup(false)
        try await queue.add(context: true) { await session.run() }

        let setupCount = await session.setupCount
        XCTAssertEqual(setupCount, 2, "A failed setup has to be retried for the next sound")
        taskCount = await session.taskCount
        XCTAssertEqual(taskCount, 1)
        teardownCount = await session.teardownCount
        XCTAssertEqual(teardownCount, 1)
        isIdle = await queue.isIdle
        XCTAssertTrue(isIdle)
    }

    /// Deactivating the session can fail while other audio is still winding down. The sound did
    /// play at that point, so this must not be reported as a playback error.
    func testFailingTeardownIsNotReportedToTheCaller() async throws {
        let session = TestSession(shouldFailTeardown: true)
        let queue = ConcurrentQueue<Bool>(setup: { try await session.setUp(for: $0) },
                                          teardown: { try await session.tearDown() })

        try await queue.add(context: true) { await session.run() }

        let isIdle = await queue.isIdle
        XCTAssertTrue(isIdle)
    }

    func testFailingTaskReleasesTheSession() async throws {
        let session = TestSession()
        let queue = ConcurrentQueue<Bool>(setup: { try await session.setUp(for: $0) },
                                          teardown: { try await session.tearDown() })

        do {
            try await queue.add(context: true) { throw TestError.taskFailed }
            XCTFail("Expected the task to fail")
        } catch {
            // Expected.
        }

        let isIdle = await queue.isIdle
        XCTAssertTrue(isIdle, "A failed sound must not keep its slot in the queue")
        let teardownCount = await session.teardownCount
        XCTAssertEqual(teardownCount, 1, "The session has to be released after a failed sound")
    }

    func testSessionIsSetUpOnceWhileAnotherSoundIsStillPlaying() async throws {
        let session = TestSession()
        let gate = Gate()
        let queue = ConcurrentQueue<Bool>(setup: { try await session.setUp(for: $0) },
                                          teardown: { try await session.tearDown() })

        let playing = Task {
            try await queue.add(context: true) {
                await session.run()
                await gate.wait()
            }
        }

        while await session.taskCount < 1 {
            try await Task.sleep(for: .milliseconds(5))
        }

        try await queue.add(context: true) { await session.run() }

        var setupCount = await session.setupCount
        XCTAssertEqual(setupCount, 1, "The session is already active, so it must not be set up again")
        var teardownCount = await session.teardownCount
        XCTAssertEqual(teardownCount, 0, "The session has to stay active while a sound is playing")

        await gate.open()
        try await playing.value

        setupCount = await session.setupCount
        XCTAssertEqual(setupCount, 1)
        teardownCount = await session.teardownCount
        XCTAssertEqual(teardownCount, 1, "The session is released once the last sound finished")
        let isIdle = await queue.isIdle
        XCTAssertTrue(isIdle)
    }

    func testSetupReceivesTheContextOfTheSound() async throws {
        let session = TestSession()
        let queue = ConcurrentQueue<Bool>(setup: { try await session.setUp(for: $0) },
                                          teardown: { try await session.tearDown() })

        try await queue.add(context: true) { await session.run() }
        try await queue.add(context: false) { await session.run() }

        let contexts = await session.contexts
        XCTAssertEqual(contexts, [true, false], "Every sound configures the session for itself")
    }
}

private enum TestError: Error {
    case setupFailed
    case teardownFailed
    case taskFailed
}

/// Stands in for the audio session, recording how often it was set up and torn down.
private actor TestSession {
    private(set) var setupCount = 0
    private(set) var teardownCount = 0
    private(set) var taskCount = 0
    private(set) var contexts: [Bool] = []

    private var shouldFailSetup: Bool
    private var shouldFailTeardown: Bool

    init(shouldFailSetup: Bool = false, shouldFailTeardown: Bool = false) {
        self.shouldFailSetup = shouldFailSetup
        self.shouldFailTeardown = shouldFailTeardown
    }

    func setUp(for context: Bool) throws {
        self.setupCount += 1
        if self.shouldFailSetup {
            throw TestError.setupFailed
        }
        self.contexts.append(context)
    }

    func tearDown() throws {
        self.teardownCount += 1
        if self.shouldFailTeardown {
            throw TestError.teardownFailed
        }
    }

    func run() {
        self.taskCount += 1
    }

    func setShouldFailSetup(_ shouldFail: Bool) {
        self.shouldFailSetup = shouldFail
    }
}

/// Lets a test hold a task in the queue until it opens the gate.
private actor Gate {
    private var isOpen = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !self.isOpen else { return }
        await withCheckedContinuation { continuation in
            self.waiting.append(continuation)
        }
    }

    func open() {
        self.isOpen = true
        let waiting = self.waiting
        self.waiting = []
        for continuation in waiting {
            continuation.resume()
        }
    }
}
