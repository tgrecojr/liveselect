import AppKit

@MainActor
protocol SelectionOverlayDelegate: AnyObject {
    func overlay(_ window: SelectionOverlayWindow, didSelectRectInScreen rect: CGRect)
    func overlayDidCancel(_ window: SelectionOverlayWindow)
}

final class SelectionOverlayWindow: NSWindow {
    weak var selectionDelegate: SelectionOverlayDelegate?
    let targetScreen: NSScreen

    init(screen: NSScreen) {
        self.targetScreen = screen
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true

        let view = SelectionOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onSelectionComplete = { [weak self] rectInView in
            guard let self else { return }
            let rectInScreen = self.convertViewRectToScreen(rectInView)
            self.selectionDelegate?.overlay(self, didSelectRectInScreen: rectInScreen)
        }
        view.onCancel = { [weak self] in
            guard let self else { return }
            self.selectionDelegate?.overlayDidCancel(self)
        }
        contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func present() {
        makeKeyAndOrderFront(nil)
        if let view = contentView {
            makeFirstResponder(view)
        }
    }

    private func convertViewRectToScreen(_ rect: CGRect) -> CGRect {
        let origin = NSPoint(x: rect.origin.x, y: rect.origin.y)
        let screenOrigin = convertPoint(toScreen: origin)
        return CGRect(origin: screenOrigin, size: rect.size)
    }
}

final class SelectionOverlayView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var dragStart: NSPoint?
    private var currentPoint: NSPoint?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        if let selection = currentSelectionRect() {
            context.setFillColor(NSColor.black.withAlphaComponent(0.35).cgColor)
            let outer = NSBezierPath(rect: bounds)
            outer.append(NSBezierPath(rect: selection))
            outer.windingRule = .evenOdd
            outer.fill()

            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(1)
            context.stroke(selection)
        } else {
            context.setFillColor(NSColor.black.withAlphaComponent(0.18).cgColor)
            context.fill(bounds)
        }
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        currentPoint = dragStart
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        if let rect = currentSelectionRect(), rect.width > 2, rect.height > 2 {
            onSelectionComplete?(rect)
        } else {
            onCancel?()
        }
        dragStart = nil
        currentPoint = nil
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    private func currentSelectionRect() -> CGRect? {
        guard let start = dragStart, let current = currentPoint else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }
}
