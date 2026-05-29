import SwiftUI

struct InjectionEntryView: View {
    var state: CheckInState
    let lastInjection: InjectionLog?

    private let doses: [(label: String, mg: Double)] = [
        ("0.25 mg", 0.25),
        ("0.5 mg", 0.5),
        ("1.0 mg", 1.0),
        ("1.7 mg", 1.7),
        ("2.4 mg", 2.4),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon + question
                VStack(spacing: 14) {
                    Image(systemName: "syringe.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)

                    Text("Did you inject today?")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    if let last = lastInjection {
                        let daysAgo = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 0
                        Text("Last injection: \(daysAgo == 0 ? "today" : "\(daysAgo)d ago") · \(last.doseLabel)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Yes / No
                HStack(spacing: 16) {
                    QuestionnaireButton(
                        label: "No",
                        icon: "xmark",
                        isSelected: state.isInjectionDay == false,
                        selectedColor: .secondary,
                        style: .muted
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            state.isInjectionDay = false
                        }
                    }

                    QuestionnaireButton(
                        label: "Yes",
                        icon: "checkmark",
                        isSelected: state.isInjectionDay == true,
                        selectedColor: .green,
                        style: .accent
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            state.isInjectionDay = true
                        }
                    }
                }

                // Dose + site note (shows if Yes)
                if state.isInjectionDay {
                    VStack(spacing: 16) {
                        Text("What dose?")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Dose cards in a 3-column-ish wrap
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(doses, id: \.mg) { dose in
                                let selected = state.doseMg == dose.mg
                                Button {
                                    state.doseMg = dose.mg
                                    state.doseLabel = dose.label
                                } label: {
                                    Text(dose.label)
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            selected
                                                ? Color.green.opacity(0.15)
                                                : Color(.secondarySystemGroupedBackground),
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(selected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                        )
                                        .foregroundStyle(selected ? Color.green : Color.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Site note
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.circle")
                                .foregroundStyle(.secondary)
                            TextField("Injection site note (optional)", text: Binding(
                                get: { state.injectionSiteNote },
                                set: { state.injectionSiteNote = $0 }
                            ))
                            .font(.subheadline)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            // Next
            VStack(spacing: 0) {
                Divider()
                Button {
                    state.step = .weight
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
            .background(.ultraThinMaterial)
        }
    }
}

