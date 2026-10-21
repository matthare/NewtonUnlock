import SwiftUI
import UIKit

// iOS counterpart of the Mac app's Newton-style screen. The games, unlock logic
// and Newton style pieces come from the Shared folder, which both targets compile.

struct ContentView: View {
    @AppStorage("gameID") private var gameID = allGames[0].id
    @AppStorage("fullName") private var fullName = ""
    @State private var regCode = ""
    @State private var copiedCode: String?
    @State private var pickerOpen: Bool
    @State private var aboutOpen: Bool
    @FocusState private var editing: Bool

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
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    titleBar
                    VStack(alignment: .leading, spacing: 18) {
                        gamePicker
                        if game.input != .none { inputField }
                        Text(game.hint)
                            .font(Newton.text(13))
                            .foregroundColor(Newton.faded)
                            .fixedSize(horizontal: false, vertical: true)
                        resultArea
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    Spacer(minLength: 0)
                    statusBar
                }
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Newton.ink, lineWidth: 3))
                .padding(6)

                if pickerOpen { pickerList(width: geo.size.width) }
                if aboutOpen { aboutBox(size: geo.size) }
            }
        }
        .background(Newton.screen.ignoresSafeArea())
        .foregroundColor(Newton.ink)
        .preferredColorScheme(.light)
    }

    // MARK: - Pieces

    private var titleBar: some View {
        VStack(spacing: 0) {
            Text("Newton Unlock")
                .font(Newton.bold(17))
                .padding(.top, 10)
                .padding(.bottom, 8)
            Rectangle().fill(Newton.ink).frame(height: 1)
            Rectangle().fill(Color.clear).frame(height: 2)
            Rectangle().fill(Newton.ink).frame(height: 1)
        }
    }

    /// Newton "diamond" picker: label and current value; tapping opens the list.
    private var gamePicker: some View {
        Button(action: { editing = false; pickerOpen.toggle() }) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\u{25C6}").font(Newton.text(12))
                Text("Game").font(Newton.bold(15))
                Text(game.title).font(Newton.text(18)).lineLimit(1)
                if !game.publisher.isEmpty {
                    Text(game.publisher).font(Newton.text(12)).foregroundColor(Newton.faded).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var inputField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(game.input == .name ? "Name" : "Reg. Code").font(Newton.bold(15))
            Group {
                if game.input == .name {
                    TextField("", text: $fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                } else {
                    TextField("", text: $regCode)
                        .keyboardType(.numberPad)
                }
            }
            .focused($editing)
            .font(Newton.text(19))
            .foregroundColor(Newton.ink)
            .overlay(DottedLine().offset(y: 4), alignment: .bottom)
        }
    }

    private var resultArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Unlock Code").font(Newton.bold(15))
            Group {
                switch result {
                case .none:
                    Text(game.input == .name ? "Write a name above." : "Write a registration code above.")
                        .font(Newton.text(15))
                        .foregroundColor(Newton.faded)
                case .failure(let error):
                    Text(error.localizedDescription)
                        .font(Newton.text(15))
                        .fixedSize(horizontal: false, vertical: true)
                case .success(let code):
                    Text(code)
                        .font(Newton.bold(30))
                        .textSelection(.enabled)
                }
            }
            .padding(.leading, 12)
            .frame(minHeight: 38, alignment: .leading)
        }
    }

    /// Newton status bar: info button and actions. iOS apps don't quit, so the
    /// close box's place holds a Done button while the keyboard is up.
    private var statusBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Newton.ink).frame(height: 2)
            HStack(spacing: 12) {
                Button(action: { editing = false; aboutOpen = true }) {
                    Text("i").font(.custom("Georgia-BoldItalic", size: 17)).frame(width: 14)
                }
                .buttonStyle(NewtonButtonStyle())

                Button(copiedCode != nil && copiedCode == unlockCode ? "Copied" : "Copy") {
                    guard let code = unlockCode else { return }
                    UIPasteboard.general.string = code
                    copiedCode = code
                }
                .buttonStyle(NewtonButtonStyle())
                .disabled(unlockCode == nil)

                Spacer()

                if editing {
                    Button("Done") { editing = false }.buttonStyle(NewtonButtonStyle())
                }
            }
            .font(Newton.text(15))
            .padding(.horizontal, 12)
            .frame(height: 46)
        }
    }

    private func pickerList(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.001)                       // tap outside to dismiss
                .onTapGesture { pickerOpen = false }
            GamePickerList(selectedID: gameID, columnWidth: min(170, (width - 50) / 2)) { id in
                gameID = id
                pickerOpen = false
            }
            .offset(x: 22, y: 100)
        }
    }

    private func aboutBox(size: CGSize) -> some View {
        ZStack {
            Color.black.opacity(0.001).onTapGesture { aboutOpen = false }
            VStack(alignment: .leading, spacing: 12) {
                Text("Newton Unlock").font(Newton.bold(17))
                Text("Works out the unlock codes for Newton games from a registration code or owner name.")
                    .font(Newton.text(15))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Written by Matt Hare and AI agent Claude").font(Newton.text(15))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Version 1.0").font(Newton.text(13)).foregroundColor(Newton.faded)
                HStack {
                    Spacer()
                    Button("OK") { aboutOpen = false }.buttonStyle(NewtonButtonStyle())
                }
            }
            .padding(18)
            .frame(width: min(320, size.width - 40))
            .modifier(NewtonFloater(radius: 8, border: 3))
        }
        .frame(width: size.width, height: size.height)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        ContentView(pickerOpen: true)
        ContentView(aboutOpen: true)
    }
}
