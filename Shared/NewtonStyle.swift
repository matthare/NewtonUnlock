import SwiftUI
#if os(macOS)
import AppKit
#endif

// Newton OS look-alike pieces shared by the Mac and iOS apps: LCD colours,
// fonts, buttons, the close box, dotted input lines, the game picker list and
// (Mac only) the window set-up. Written against the macOS 11 / iOS 15 SwiftUI
// APIs so the apps still run on Big Sur and build in Xcode 13.

enum Newton {
    /// MessagePad 2000-style grey-green LCD and its dark "ink"
    static let screen = Color(red: 0.80, green: 0.83, blue: 0.76)
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.08)
    static let faded = Color(red: 0.09, green: 0.10, blue: 0.08).opacity(0.62)

    /// Geneva is the nearest Mac font to the Newton's Espy Sans. It has no bold
    /// weight, so bold text uses Verdana Bold, a close relative. iOS has no
    /// Geneva, so it uses Verdana throughout (a point smaller, as it runs wide).
    #if os(macOS)
    static func text(_ size: CGFloat) -> Font { .custom("Geneva", size: size) }
    #else
    static func text(_ size: CGFloat) -> Font { .custom("Verdana", size: size - 1) }
    #endif
    static func bold(_ size: CGFloat) -> Font { .custom("Verdana-Bold", size: size) }
}

/// Rounded black-outlined button that inverts while pressed, like Newton buttons.
struct NewtonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        NewtonButtonBody(configuration: configuration)
    }

    private struct NewtonButtonBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled
        #if os(macOS)
        private let fontSize: CGFloat = 13, verticalPadding: CGFloat = 3
        #else
        private let fontSize: CGFloat = 17, verticalPadding: CGFloat = 6     // finger-sized
        #endif

        var body: some View {
            let pressed = configuration.isPressed
            configuration.label
                .font(Newton.text(fontSize))
                .padding(.horizontal, 10)
                .padding(.vertical, verticalPadding)
                .foregroundColor(pressed ? Newton.screen : Newton.ink)
                .background(RoundedRectangle(cornerRadius: 7).fill(pressed ? Newton.ink : Newton.screen))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Newton.ink, lineWidth: 1.5))
                .opacity(isEnabled ? 1 : 0.35)
                .contentShape(RoundedRectangle(cornerRadius: 7))
        }
    }
}

/// The Newton OS 2 close box: a small rounded square with an X.
struct NewtonCloseBox: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) { EmptyView() }
            .buttonStyle(CloseBoxStyle())
            .help("Close")
    }

    private struct CloseBoxStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            let pressed = configuration.isPressed
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(pressed ? Newton.ink : Newton.screen)
                RoundedRectangle(cornerRadius: 3).stroke(Newton.ink, lineWidth: 1.5)
                Path { p in
                    p.move(to: CGPoint(x: 4.5, y: 4.5)); p.addLine(to: CGPoint(x: 11.5, y: 11.5))
                    p.move(to: CGPoint(x: 11.5, y: 4.5)); p.addLine(to: CGPoint(x: 4.5, y: 11.5))
                }
                .stroke(pressed ? Newton.screen : Newton.ink, lineWidth: 1.5)
            }
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
        }
    }
}

/// The dotted baseline Newton draws under writable fields.
struct DottedLine: View {
    var body: some View {
        GeometryReader { g in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: g.size.width, y: 0.5))
            }
            .stroke(Newton.ink, style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
        }
        .frame(height: 1)
    }
}

/// A floating Newton box: thick rounded border with a solid offset shadow.
struct NewtonFloater: ViewModifier {
    var radius: CGFloat = 6
    var border: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius).fill(Newton.screen))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Newton.ink, lineWidth: border))
            .background(RoundedRectangle(cornerRadius: radius).fill(Newton.ink).offset(x: 3, y: 3))
    }
}

/// The game list that drops down from the "◆ Game" picker: two columns so all
/// the games fit, a check mark on the current one, inverted highlight.
struct GamePickerList: View {
    let selectedID: String
    var columnWidth: CGFloat = 168
    let pick: (String) -> Void
    @State private var hoveredID: String?

    private var columns: [[Game]] {
        let half = (allGames.count + 1) / 2
        return [Array(allGames[..<half]), Array(allGames[half...])]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<columns.count, id: \.self) { c in
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(columns[c]) { g in row(g) }
                }
                .frame(width: columnWidth)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 3)
        .modifier(NewtonFloater())
    }

    private func row(_ g: Game) -> some View {
        let hot = hoveredID == g.id
        return HStack(spacing: 4) {
            Text(g.id == selectedID ? "\u{2713}" : "")
                .font(Newton.bold(12))
                .frame(width: 14)
            Text(g.title).font(Newton.text(14)).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .frame(height: rowHeight)
        .foregroundColor(hot ? Newton.screen : Newton.ink)
        .background(hot ? Newton.ink : Color.clear)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside { hoveredID = g.id } else if hoveredID == g.id { hoveredID = nil }
        }
        .onTapGesture { pick(g.id) }
    }

    #if os(macOS)
    private let rowHeight: CGFloat = 21
    #else
    private let rowHeight: CGFloat = 30      // finger-sized
    #endif
}

#if os(macOS)
/// Turns the hosting NSWindow into a plain Newton "screen": no title bar,
/// no traffic lights, fixed size, draggable by its background.
struct NewtonWindowConfigurator: NSViewRepresentable {
    /// The content's fixed size; the window is fitted to it.
    let contentSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let hook = WindowHook()
        hook.contentSize = contentSize
        return hook
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    /// Configures the window as soon as this view is placed in it. (Waiting a
    /// run-loop turn instead is unreliable: on newer macOS the view may not be
    /// in its window yet.)
    private final class WindowHook: NSView {
        var contentSize = CGSize.zero

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window = window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.remove(.resizable)
            for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                window.standardWindowButton(button)?.isHidden = true
            }
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(Newton.screen)
            // macOS 13+ gives SwiftUI windows a default (or remembered) size
            // bigger than the content, while macOS 11-12 fit the content. Fit it
            // here, once SwiftUI has finished sizing the window. (The hosting
            // view's fittingSize is zero on newer macOS, so the size is passed in.)
            let size = contentSize
            // The content runs under the hidden title bar, so the whole window
            // frame is the content: set the frame, not the content size (which
            // would add the title bar's height).
            DispatchQueue.main.async { [weak window] in
                guard let window = window, size.width > 0, size.height > 0,
                      window.frame.size != size else { return }
                window.setFrame(NSRect(origin: window.frame.origin, size: size), display: true)
                window.center()
            }
        }
    }
}
#endif
