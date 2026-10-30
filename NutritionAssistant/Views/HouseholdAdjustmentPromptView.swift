import SwiftUI

/// Compact modal matching the approved mockup: serving change, question, proposed household change, No / Yes.
/// Tapping the dimmed background dismisses it and returns to the form.
struct HouseholdAdjustmentPromptView: View {
    let adjustment: HouseholdMeasurementAdjustment
    let onUpdate: () -> Void
    let onKeep: () -> Void
    let onDismiss: () -> Void

    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func measure(_ quantity: Double) -> String {
        "\(number(quantity)) \(MeasurementUnitFormatter.display(name: adjustment.measurement, quantity: quantity))"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                Text("Serving Value Changed")
                    .font(.headline)
                    .padding(14)

                Divider()
                Text("\(number(adjustment.oldServingSize)) \(adjustment.servingUnit)  →  \(number(adjustment.newServingSize)) \(adjustment.servingUnit)")
                    .padding(14)

                Divider()
                Text("Would you also like to change the household measurement?")
                    .multilineTextAlignment(.center)
                    .padding(14)

                Divider()
                Text("\(measure(adjustment.oldAmount))  →  \(measure(adjustment.newAmount))")
                    .fontWeight(.semibold)
                    .padding(14)

                Divider()
                HStack(spacing: 0) {
                    Button(action: onKeep) {
                        Text("No,\ndo not update")
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    Divider().frame(height: 56)
                    Button(action: onUpdate) {
                        Text("Yes,\nUpdate")
                            .multilineTextAlignment(.center)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 32)
            .contentShape(Rectangle())
            .onTapGesture { } // taps on the card must not reach the dismiss layer
        }
        .transition(.opacity)
    }
}

#Preview {
    HouseholdAdjustmentPromptView(
        adjustment: HouseholdMeasurementAdjustment(
            oldServingSize: 20, newServingSize: 40, servingUnit: "g",
            measurement: "scoop", oldAmount: 1, newAmount: 2
        ),
        onUpdate: {}, onKeep: {}, onDismiss: {}
    )
}
