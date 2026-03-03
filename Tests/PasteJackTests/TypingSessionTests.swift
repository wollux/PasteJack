import Testing
@testable import PasteJack

@Suite("TypingSession Tests")
struct TypingSessionTests {

    @Test("Initial state is idle")
    @MainActor
    func initialStateIsIdle() {
        let session = TypingSession()
        #expect(session.state == .idle)
    }

    @Test("Session is not active when idle")
    @MainActor
    func notActiveWhenIdle() {
        let session = TypingSession()
        #expect(!session.isActive)
    }

    @Test("Cancel from idle stays idle")
    @MainActor
    func cancelFromIdleStaysIdle() {
        let session = TypingSession()
        session.cancel()
        // cancel from idle sets state to cancelled only if it was not idle
        #expect(session.state == .idle)
    }

    @Test("Reset returns to idle")
    @MainActor
    func resetReturnsToIdle() {
        let session = TypingSession()
        session.reset()
        #expect(session.state == .idle)
    }

    @Test("State equality works correctly")
    func stateEquality() {
        #expect(TypingSession.State.idle == TypingSession.State.idle)
        #expect(TypingSession.State.completed == TypingSession.State.completed)
        #expect(TypingSession.State.cancelled == TypingSession.State.cancelled)
        #expect(TypingSession.State.countdown(remaining: 3) == TypingSession.State.countdown(remaining: 3))
        #expect(TypingSession.State.countdown(remaining: 3) != TypingSession.State.countdown(remaining: 2))
        #expect(TypingSession.State.error("foo") == TypingSession.State.error("foo"))
        #expect(TypingSession.State.error("foo") != TypingSession.State.error("bar"))
    }

    @Test("Typing state reports progress correctly")
    func typingStateProgress() {
        let state = TypingSession.State.typing(progress: 0.5, current: 50, total: 100)
        #expect(state == .typing(progress: 0.5, current: 50, total: 100))
    }
}
