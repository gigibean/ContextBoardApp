import SwiftUI

/// 파스텔 색상을 선택하는 뷰입니다.
struct PastelColorPicker: View {
    @Binding var selectedHex: String

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("액센트 색상")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(PastelColors.presets, id: \.hex) { preset in
                    colorChip(preset)
                }
            }
        }
    }

    private func colorChip(_ preset: (name: String, hex: String)) -> some View {
        Button {
            selectedHex = preset.hex
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: preset.hex))
                    .frame(width: 32, height: 32)

                if selectedHex == preset.hex {
                    Circle()
                        .stroke(Color.primary, lineWidth: 2.5)
                        .frame(width: 32, height: 32)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .buttonStyle(.plain)
        .help(preset.name)
    }
}

#Preview {
    @Previewable @State var color = "#FFB6C1"
    PastelColorPicker(selectedHex: $color)
        .padding(20)
        .frame(width: 300)
}
