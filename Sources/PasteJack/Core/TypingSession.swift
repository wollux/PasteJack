import Combine
import CoreGraphics

/// Orchestrates a full typing session with progress, cancellation, and error handling.
@MainActor
final class TypingSession: ObservableObject {

    enum State: Equatable {
        case idle
        case countdown(remaining: Int)
        case typing(progress: Double, current: Int, total: Int)
        case completed
        case cancelled
        case error(String)
    }

    @Published var state: State = .idle

    private let engine = KeystrokeEngine()
    private var task: Task<Void, Never>?

    /// The text that was typed in the last completed session (for history).
    private(set) var lastTypedText: String?

    /// Start typing the given text with configurable delay per character.
    func start(
        text: String,
        delayMicroseconds: UInt32,
        countdownSeconds: Int,
        adaptiveSpeed: Bool = false,
        lineDelayMicroseconds: UInt32 = 0
    ) {
        cancel()

        let characters = Array(text)
        let total = characters.count

        task = Task { [weak self] in
            guard let self else { return }

            // Countdown phase — gives user time to focus the target window
            for i in stride(from: countdownSeconds, through: 1, by: -1) {
                self.state = .countdown(remaining: i)
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { self.state = .cancelled; return }
            }

            // Typing phase
            var currentDelay = delayMicroseconds

            for (index, char) in characters.enumerated() {
                if Task.isCancelled { self.state = .cancelled; return }

                self.state = .typing(
                    progress: Double(index + 1) / Double(total),
                    current: index + 1,
                    total: total
                )

                if let control = ControlCharMapping.map[char] {
                    if adaptiveSpeed {
                        currentDelay = self.engine.typeControlCharacterAdaptive(
                            control.keyCode,
                            modifiers: control.modifiers,
                            baseDelay: delayMicroseconds,
                            currentDelay: currentDelay
                        )
                    } else {
                        self.engine.typeControlCharacter(
                            control.keyCode,
                            modifiers: control.modifiers,
                            delay: delayMicroseconds
                        )
                    }
                    // Extra delay after newline
                    if (char == "\n" || char == "\r") && lineDelayMicroseconds > 0 {
                        usleep(lineDelayMicroseconds)
                    }
                } else if ControlCharMapping.isControlCharacter(char) {
                    continue
                } else {
                    if adaptiveSpeed {
                        currentDelay = self.engine.typeCharacterAdaptive(
                            char,
                            baseDelay: delayMicroseconds,
                            currentDelay: currentDelay
                        )
                    } else {
                        self.engine.typeCharacter(char, delay: delayMicroseconds)
                    }
                }
            }

            self.lastTypedText = text
            self.state = .completed
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if state != .idle {
            state = .cancelled
        }
    }

    func reset() {
        cancel()
        state = .idle
    }

    var isActive: Bool {
        switch state {
        case .countdown, .typing:
            return true
        default:
            return false
        }
    }
}
