import SwiftUI

struct WeeklyNotesView: View {
    @Binding var notes: String
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Any notes for the week?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            TextEditor(text: $notes)
                .frame(height: 180)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.3)))
                .overlay(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("How did the week go? Any observations…")
                            .foregroundStyle(.secondary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }

            VStack(spacing: 12) {
                Button {
                    onNext()
                } label: {
                    Text("Done").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip") { notes = ""; onNext() }
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}
