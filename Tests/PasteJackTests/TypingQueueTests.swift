import Foundation
import Testing
@testable import PasteJack

@Suite("TypingQueue Tests")
struct TypingQueueTests {

    @Test("addText adds an item")
    @MainActor func addText() {
        let queue = TypingQueue()
        queue.addText("hello")
        #expect(queue.items.count == 1)
        #expect(queue.items[0].text == "hello")
    }

    @Test("addText ignores empty strings")
    @MainActor func addTextEmpty() {
        let queue = TypingQueue()
        queue.addText("")
        #expect(queue.items.isEmpty)
    }

    @Test("addEmpty adds an item with empty text")
    @MainActor func addEmpty() {
        let queue = TypingQueue()
        queue.addEmpty()
        #expect(queue.items.count == 1)
        #expect(queue.items[0].text == "")
    }

    @Test("remove removes the correct item")
    @MainActor func removeById() {
        let queue = TypingQueue()
        queue.addText("first")
        queue.addText("second")
        let idToRemove = queue.items[0].id
        queue.remove(id: idToRemove)
        #expect(queue.items.count == 1)
        #expect(queue.items[0].text == "second")
    }

    @Test("move reorders items")
    @MainActor func moveItems() {
        let queue = TypingQueue()
        queue.addText("a")
        queue.addText("b")
        queue.addText("c")
        queue.move(from: IndexSet(integer: 0), to: 3) // move "a" to end
        #expect(queue.items[0].text == "b")
        #expect(queue.items[1].text == "c")
        #expect(queue.items[2].text == "a")
    }

    @Test("clear removes all items and resets state")
    @MainActor func clearQueue() {
        let queue = TypingQueue()
        queue.addText("hello")
        queue.addText("world")
        queue.clear()
        #expect(queue.items.isEmpty)
        #expect(queue.currentIndex == -1)
        #expect(queue.isRunning == false)
    }

    @Test("stop sets isRunning to false")
    @MainActor func stopQueue() {
        let queue = TypingQueue()
        queue.isRunning = true
        queue.stop()
        #expect(queue.isRunning == false)
    }

    @Test("QueueItem default separator is tab")
    func defaultSeparator() {
        let item = QueueItem(text: "test")
        #expect(item.separator == "tab")
    }

    @Test("QueueItem preview truncates and strips newlines")
    func previewTruncation() {
        let longText = String(repeating: "x", count: 100)
        let item = QueueItem(text: longText)
        #expect(item.preview.count == 60)

        let multiline = QueueItem(text: "line1\nline2")
        #expect(!multiline.preview.contains("\n"))
        #expect(multiline.preview.contains("line1 line2"))
    }
}
