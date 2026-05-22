import AppKit
import SwiftUI

/// 스티커 아이콘을 관리하는 서비스입니다.
/// SF Symbol, 번들 아이콘, 커스텀 이미지를 통합 관리합니다.
@MainActor
final class IconManager {

    /// 번들된 카와이 기본 아이콘 목록
    static let bundledIcons: [(name: String, sfSymbol: String, label: String)] = [
        ("airplane", "airplane.departure", "항공"),
        ("hotel", "building.2.fill", "숙박"),
        ("bug", "ladybug.fill", "버그 수정"),
        ("sparkle", "sparkles", "새 기능"),
        ("paintbrush", "paintbrush.fill", "디자인"),
        ("gear", "gearshape.fill", "인프라"),
        ("document", "doc.text.fill", "문서"),
        ("lightning", "bolt.fill", "성능"),
        ("shield", "shield.fill", "보안"),
        ("heart", "heart.fill", "UX 개선"),
        ("cart", "cart.fill", "결제"),
        ("magnifier", "magnifyingglass", "검색"),
    ]

    /// URL 도메인 패턴으로 자동 아이콘을 결정합니다.
    static func suggestIcon(for urlString: String) -> String {
        let lowered = urlString.lowercased()

        if lowered.contains("github.com") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lowered.contains("figma.com") {
            return "paintbrush.fill"
        } else if lowered.contains("atlassian.net") || lowered.contains("jira") {
            return "ticket.fill"
        } else if lowered.contains("confluence") {
            return "doc.text.fill"
        } else if lowered.contains("slack.com") {
            return "bubble.left.and.bubble.right.fill"
        } else if lowered.contains("notion.so") {
            return "note.text"
        } else {
            return "globe"
        }
    }

    /// 커스텀 이미지 데이터를 NSImage로 변환합니다.
    static func imageFromData(_ data: Data) -> NSImage? {
        NSImage(data: data)
    }

    /// NSImage를 PNG 데이터로 변환합니다.
    static func pngData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    /// 파일 선택 패널을 열어 이미지를 선택합니다.
    static func pickImage() async -> Data? {
        await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.png, .jpeg, .heic]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.message = "스티커 아이콘으로 사용할 이미지를 선택하세요"

            panel.begin { response in
                guard response == .OK, let url = panel.url else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let data = try Data(contentsOf: url)
                    // 아이콘 크기로 리사이즈 (128x128)
                    if let image = NSImage(data: data) {
                        let resized = Self.resizeImage(image, to: NSSize(width: 128, height: 128))
                        continuation.resume(returning: Self.pngData(from: resized))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// 이미지를 지정된 크기로 리사이즈합니다.
    private static func resizeImage(_ image: NSImage, to targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
}
