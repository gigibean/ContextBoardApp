import Testing
import Foundation
@testable import ContextBoard

@Suite("ContextItem 모델 테스트")
struct ContextItemTests {

    @Test("기본 초기화 값 확인")
    func testDefaultInit() {
        let item = ContextItem()

        #expect(!item.id.uuidString.isEmpty)
        #expect(item.type == .webURL)
        #expect(item.label.isEmpty)
        #expect(item.isEnabled)
        #expect(item.sortOrder == 0)
    }

    @Test("웹 URL 아이템 resolvedURL")
    func testWebURLResolvedURL() {
        let item = ContextItem(
            type: .webURL,
            label: "Jira",
            urlString: "https://example.atlassian.net/browse/PROJ-1234"
        )

        let url = item.resolvedURL
        #expect(url != nil)
        #expect(url?.absoluteString == "https://example.atlassian.net/browse/PROJ-1234")
    }

    @Test("딥 링크 아이템 resolvedURL")
    func testDeepLinkResolvedURL() {
        let item = ContextItem(
            type: .deepLink,
            label: "VS Code",
            urlString: "vscode://file/Users/dev/project"
        )

        let url = item.resolvedURL
        #expect(url != nil)
        #expect(url?.scheme == "vscode")
    }

    @Test("파일 아이템 resolvedURL")
    func testFileResolvedURL() {
        let item = ContextItem(
            type: .file,
            label: "설계 문서",
            filePath: "/Users/test/documents/design.pdf"
        )

        let url = item.resolvedURL
        #expect(url != nil)
        #expect(url?.isFileURL == true)
    }

    @Test("빈 URL 아이템은 nil 반환")
    func testEmptyURLReturnsNil() {
        let item = ContextItem(type: .webURL, label: "빈 아이템")
        #expect(item.resolvedURL == nil)
    }
}
