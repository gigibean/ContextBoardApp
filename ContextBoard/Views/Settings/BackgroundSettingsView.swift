import SwiftUI
import SwiftData

/// 보드 배경을 커스터마이징하는 설정 뷰입니다.
struct BackgroundSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [BoardSettings]

    @State private var backgroundStyle: BackgroundStyle = .defaultKawaii
    @State private var solidColorHex: String = "#FFF0F5"
    @State private var gradientColors: [String] = ["#FFE4E1", "#E6E6FA", "#F0FFF0"]

    private var settings: BoardSettings? { allSettings.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("배경 스타일")
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            // 스타일 선택
            Picker("배경 스타일", selection: $backgroundStyle) {
                ForEach(BackgroundStyle.allCases, id: \.self) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: backgroundStyle) { _, newValue in
                saveBackgroundStyle(newValue)
            }

            // 스타일별 설정
            switch backgroundStyle {
            case .solidColor:
                PastelColorPicker(selectedHex: $solidColorHex)
                    .onChange(of: solidColorHex) { _, newValue in
                        saveSolidColor(newValue)
                    }

            case .gradient:
                gradientEditor

            case .image:
                imageSelector

            case .defaultKawaii:
                Text("기본 카와이 배경이 적용됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 미리보기
            previewArea
        }
        .padding(20)
        .onAppear {
            loadSettings()
        }
    }

    // MARK: - Gradient Editor

    private var gradientEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("그라데이션 색상 (최대 3개)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(gradientColors.indices, id: \.self) { index in
                HStack {
                    Circle()
                        .fill(Color(hex: gradientColors[index]))
                        .frame(width: 24, height: 24)

                    TextField("Hex 색상", text: Binding(
                        get: { gradientColors[index] },
                        set: { gradientColors[index] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                }
            }
        }
    }

    // MARK: - Image Selector

    private var imageSelector: some View {
        VStack(spacing: 12) {
            if let data = settings?.backgroundImageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                PastelButton("이미지 선택", icon: "photo", color: "#E6E6FA") {
                    selectImage()
                }

                if settings?.backgroundImageData != nil {
                    PastelButton("제거", icon: "xmark", color: "#F08080") {
                        removeImage()
                    }
                }
            }
        }
    }

    // MARK: - Preview

    private var previewArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("미리보기")
                .font(.caption)
                .foregroundStyle(.secondary)

            BoardBackgroundView(settings: settings)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        guard let settings else { return }
        backgroundStyle = settings.backgroundStyle
        solidColorHex = settings.solidColorHex
        gradientColors = settings.gradientColors
    }

    private func saveBackgroundStyle(_ style: BackgroundStyle) {
        do {
            let s = try BoardSettings.getOrCreate(in: modelContext)
            s.backgroundStyle = style
            try modelContext.save()
        } catch {
            print("[BackgroundSettings] 저장 실패: \(error.localizedDescription)")
        }
    }

    private func saveSolidColor(_ hex: String) {
        do {
            let s = try BoardSettings.getOrCreate(in: modelContext)
            s.solidColorHex = hex
            try modelContext.save()
        } catch {
            print("[BackgroundSettings] 저장 실패: \(error.localizedDescription)")
        }
    }

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try Data(contentsOf: url)
                let s = try BoardSettings.getOrCreate(in: modelContext)
                s.backgroundImageData = data
                s.backgroundStyle = .image
                try modelContext.save()
            } catch {
                print("[BackgroundSettings] 이미지 로드 실패: \(error.localizedDescription)")
            }
        }
    }

    private func removeImage() {
        do {
            let s = try BoardSettings.getOrCreate(in: modelContext)
            s.backgroundImageData = nil
            s.backgroundStyle = .defaultKawaii
            try modelContext.save()
            backgroundStyle = .defaultKawaii
        } catch {
            print("[BackgroundSettings] 이미지 제거 실패: \(error.localizedDescription)")
        }
    }
}
