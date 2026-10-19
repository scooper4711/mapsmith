import SwiftUI

/// A number field that passes on what is typed only once typing pauses, or on Return, so a value
/// such as 150 isn't acted on at 1 and 15 along the way.
struct DeferredNumberField: View {
    static let pause = Duration.milliseconds(600)

    let title: String
    /// The value set elsewhere; nil shows the prompt.
    let value: Double?
    let prompt: String
    let commit: (Double?) -> Void
    @State private var draft: Double?

    var body: some View {
        TextField(title, value: $draft, format: .number.precision(.fractionLength(0...2)), prompt: Text(prompt))
            .onSubmit { commitDraft() }
            .onChange(of: value, initial: true) { draft = value }
            .task(id: draft) {
                guard draft != value else { return }
                try? await Task.sleep(for: Self.pause)
                if !Task.isCancelled { commitDraft() }
            }
    }

    private func commitDraft() {
        if draft != value { commit(draft) }
    }
}
