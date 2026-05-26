import SwiftUI

struct InjectionEntryView: View {
    @Binding var isInjectionDay: Bool
    @Binding var dose: Double
    @Binding var time: Date
    @Binding var siteNote: String
    let onNext: () -> Void

    private let doseOptions: [Double] = [0.25, 0.5, 1.0, 1.7, 2.0]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                Text("Was today an injection day?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                HStack(spacing: 20) {
                    Button {
                        isInjectionDay = false
                        onNext()
                    } label: {
                        Text("No")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button { isInjectionDay = true } label: {
                        Text("Yes")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .opacity(isInjectionDay ? 1.0 : 0.45)
                }
                .padding(.horizontal)

                if isInjectionDay {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dose").font(.headline)
                            Picker("Dose", selection: $dose) {
                                ForEach(doseOptions, id: \.self) { d in
                                    Text("\(d, specifier: "%.2f") mg").tag(d)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time").font(.headline)
                            DatePicker("Injection time", selection: $time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Injection site note (optional)").font(.headline)
                            TextField("e.g. Left abdomen", text: $siteNote)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            onNext()
                        } label: {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .animation(.easeInOut, value: isInjectionDay)
    }
}
