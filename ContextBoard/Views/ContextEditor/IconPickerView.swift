import SwiftUI

/// 아이콘을 선택하는 시트 뷰입니다.
/// SF Symbol, 번들 아이콘, 커스텀 이미지 중 선택할 수 있습니다.
struct IconPickerView: View {
    @Binding var selectedIconType: IconType
    @Binding var selectedSFSymbol: String
    @Binding var customIconData: Data?
    let onDone: () -> Void

    @State private var searchText = ""

    /// SF Symbol 기본 목록
    private let sfSymbols: [String] = [
        "ticket.fill", "airplane.departure", "airplane.arrival",
        "building.2.fill", "bed.double.fill", "car.fill",
        "bus.fill", "tram.fill", "ferry.fill",
        "ladybug.fill", "ant.fill", "sparkles",
        "star.fill", "heart.fill", "flame.fill",
        "bolt.fill", "shield.fill", "lock.fill",
        "paintbrush.fill", "pencil", "doc.text.fill",
        "folder.fill", "gearshape.fill", "wrench.fill",
        "cart.fill", "creditcard.fill", "banknote.fill",
        "magnifyingglass", "globe", "link",
        "person.fill", "person.2.fill", "bell.fill",
        "bubble.left.fill", "phone.fill", "envelope.fill",
        "camera.fill", "photo.fill", "film",
        "music.note", "play.fill", "gamecontroller.fill",
    ]

    var filteredSymbols: [String] {
        if searchText.isEmpty { return sfSymbols }
        return sfSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Text("아이콘 선택")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Button("완료") { onDone() }
                    .keyboardShortcut(.return)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // 탭 선택
            Picker("아이콘 타입", selection: $selectedIconType) {
                ForEach(IconType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            // 콘텐츠
            switch selectedIconType {
            case .sfSymbol:
                sfSymbolGrid

            case .bundledKawaii:
                bundledIconGrid

            case .customImage:
                customImagePicker
            }

            Spacer()
        }
        .frame(width: 400, height: 420)
    }

    // MARK: - SF Symbol Grid

    private var sfSymbolGrid: some View {
        VStack(spacing: 8) {
            TextField("아이콘 검색...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 20)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button {
                            selectedSFSymbol = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedSFSymbol == symbol
                                              ? Color.accentColor.opacity(0.2)
                                              : Color.gray.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedSFSymbol == symbol
                                                ? Color.accentColor
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .help(symbol)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Bundled Icon Grid

    private var bundledIconGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(IconManager.bundledIcons, id: \.sfSymbol) { icon in
                    Button {
                        selectedSFSymbol = icon.sfSymbol
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icon.sfSymbol)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                            Text(icon.label)
                                .font(.system(size: 10))
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSFSymbol == icon.sfSymbol
                                      ? Color.accentColor.opacity(0.2)
                                      : Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedSFSymbol == icon.sfSymbol
                                        ? Color.accentColor
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Custom Image Picker

    private var customImagePicker: some View {
        VStack(spacing: 16) {
            if let data = customIconData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }

            PastelButton("이미지 선택", icon: "photo", color: "#E6E6FA") {
                Task {
                    if let data = await IconManager.pickImage() {
                        customIconData = data
                    }
                }
            }

            if customIconData != nil {
                PastelButton("이미지 제거", icon: "xmark", color: "#F08080") {
                    customIconData = nil
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    @Previewable @State var iconType: IconType = .sfSymbol
    @Previewable @State var sfSymbol = "ticket.fill"
    @Previewable @State var customData: Data? = nil

    IconPickerView(
        selectedIconType: $iconType,
        selectedSFSymbol: $sfSymbol,
        customIconData: $customData,
        onDone: {}
    )
}
