import AppKit
import SwiftUI

// The Mac app's single screen, drawn to look like a Newton OS application.
// Uses only macOS 11 SwiftUI APIs so the app runs on Big Sur and builds in Xcode 13.

struct ContentView: View {
    @AppStorage("gameID") private var gameID = allGames[0].id
    @AppStorage("fullName") private var fullName = ""
    @State private var regCode = ""
    @State private var copiedCode: String?
    /// The window's fixed content size
    static let size = CGSize(width: 470, height: 330)

    @State private var pickerOpen: Bool
    @State private var aboutOpen: Bool

    /// The flags let previews show the picker list or About box already open.
    init(pickerOpen: Bool = false, aboutOpen: Bool = false) {
        _pickerOpen = State(initialValue: pickerOpen)
        _aboutOpen = State(initialValue: aboutOpen)
    }

    private var game: Game { allGames.first { $0.id == gameID } ?? allGames[0] }
    private var input: String { game.input == .name ? fullName : regCode }

    private var result: Result<String, Error>? {
        guard game.input == .none || !input.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return Result { try game.compute(input) }
    }

    private var unlockCode: String? {
        if case .success(let code) = result { return code }
        return nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                titleBar
                VStack(alignment: .leading, spacing: 16) {
                    gamePicker
                    if game.input != .none { inputField }
                    Text(game.hint)
                        .font(Newton.text(11))
                        .foregroundColor(Newton.faded)
                        .fixedSize(horizontal: false, vertical: true)
                    resultArea
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                Spacer(minLength: 0)
                statusBar
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Newton.ink, lineWidth: 3))
            .padding(6)

            if pickerOpen { pickerList }
            if aboutOpen { aboutBox }
        }
        // Width fixed, height flexible: on macOS 13+ SwiftUI adds the hidden
        // title bar's height to a fixed-height window and snaps back to that.
        // The window hook sets the exact size instead, the same on every macOS.
        .frame(width: Self.size.width)
        .frame(minHeight: Self.size.height - 50, maxHeight: .infinity)
        .background(Newton.screen)
        .background(NewtonWindowConfigurator(contentSize: Self.size))
        .ignoresSafeArea()      // also fill the hidden title bar's area
        .foregroundColor(Newton.ink)
        .preferredColorScheme(.light)
        .onExitCommand { pickerOpen = false; aboutOpen = false }
    }

    // MARK: - Pieces

    private var titleBar: some View {
        VStack(spacing: 0) {
            Text("Newton Unlock")
                .font(Newton.bold(15))
                .padding(.top, 9)
                .padding(.bottom, 7)
            Rectangle().fill(Newton.ink).frame(height: 1)
            Rectangle().fill(Color.clear).frame(height: 2)
            Rectangle().fill(Newton.ink).frame(height: 1)
        }
    }

    /// Newton "diamond" picker: label and current value; tapping opens the list.
    private var gamePicker: some View {
        Button(action: { pickerOpen.toggle() }) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\u{25C6}").font(Newton.text(11))
                Text("Game").font(Newton.bold(13))
                Text(game.title).font(Newton.text(15))
                if !game.publisher.isEmpty {
                    Text(game.publisher).font(Newton.text(11)).foregroundColor(Newton.faded)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var inputField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(game.input == .name ? "Name" : "Reg. Code").font(Newton.bold(13))
            Group {
                if game.input == .name {
                    TextField("", text: $fullName)
                } else {
                    TextField("", text: $regCode)
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .font(Newton.text(16))
            .foregroundColor(Newton.ink)
            .overlay(DottedLine().offset(y: 4), alignment: .bottom)
        }
    }

    private var resultArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Unlock Code").font(Newton.bold(13))
            Group {
                switch result {
                case .none:
                    Text(game.input == .name ? "Write a name above." : "Write a registration code above.")
                        .font(Newton.text(13))
                        .foregroundColor(Newton.faded)
                case .failure(let error):
                    Text(error.localizedDescription)
                        .font(Newton.text(13))
                        .fixedSize(horizontal: false, vertical: true)
                case .success(let code):
                    Text(code)
                        .font(Newton.bold(24))
                        .selectableIfAvailable()
                }
            }
            .padding(.leading, 12)
            .frame(minHeight: 32, alignment: .leading)
        }
    }

    /// Newton status bar: info button, action buttons, close box on the right.
    private var statusBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Newton.ink).frame(height: 2)
            HStack(spacing: 10) {
                Button(action: { aboutOpen = true }) {
                    Text("i").font(.custom("Georgia-BoldItalic", size: 14)).frame(width: 10)
                }
                .buttonStyle(NewtonButtonStyle())
                .help("About Newton Unlock")

                Button(copiedCode != nil && copiedCode == unlockCode ? "Copied" : "Copy") {
                    guard let code = unlockCode else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copiedCode = code
                }
                .buttonStyle(NewtonButtonStyle())
                .disabled(unlockCode == nil)
                .keyboardShortcut(.defaultAction)

                Spacer()

                NewtonCloseBox { NSApplication.shared.terminate(nil) }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
        }
    }

    /// Pop-up list in the Newton style: bordered box, offset shadow, check mark
    /// on the current item, inverted highlight under the pointer.
    private var pickerList: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.001)                       // click outside to dismiss
                .onTapGesture { pickerOpen = false }
            GamePickerList(selectedID: gameID) { id in
                gameID = id
                pickerOpen = false
            }
            .offset(x: 34, y: 80)
        }
    }

    private var aboutBox: some View {
        ZStack {
            Color.black.opacity(0.001).onTapGesture { aboutOpen = false }
            VStack(alignment: .leading, spacing: 10) {
                Text("Newton Unlock").font(Newton.bold(14))
                Text("Works out the unlock codes for Newton games from a registration code or owner name.")
                    .font(Newton.text(12))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Written by Matt Hare and AI agent Claude").font(Newton.text(12))
                Text("Version 1.0").font(Newton.text(11)).foregroundColor(Newton.faded)
                HStack {
                    Spacer()
                    Button("OK") { aboutOpen = false }.buttonStyle(NewtonButtonStyle())
                }
            }
            .padding(16)
            .frame(width: 290)
            .modifier(NewtonFloater(radius: 8, border: 3))
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}

private extension View {
    /// Text selection needs macOS 12; on Big Sur the Copy button covers it.
    @ViewBuilder func selectableIfAvailable() -> some View {
        if #available(macOS 12.0, *) {
            textSelection(.enabled)
        } else {
            self
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        ContentView(pickerOpen: true)
        ContentView(aboutOpen: true)
    }
}
