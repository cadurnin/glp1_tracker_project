import SwiftUI

struct WeeklyNotesView: View {
    @Binding var notes: String
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)

            Text("Any notes for the week?")
                .font(.title2.bold())

            TextEditor(text: $notes)
                .frame(height: 160)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button {
                onNext()
            } label: {
                Text("Save Weekly Check-In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
