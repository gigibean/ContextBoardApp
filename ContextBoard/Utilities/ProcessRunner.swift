import Foundation

/// stderr 데이터를 스레드 안전하게 수집하는 헬퍼 클래스입니다.
/// readabilityHandler 콜백은 GCD 프라이빗 큐에서 호출되므로 lock이 필요합니다.
private final class StderrCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    var string: String? {
        lock.lock()
        defer { lock.unlock() }
        return String(data: data, encoding: .utf8)
    }
}

/// CLI 프로세스를 비동기로 실행하는 유틸리티입니다.
/// 주로 Claude CLI 호출에 사용됩니다.
actor ProcessRunner {

    enum ProcessError: LocalizedError {
        case executableNotFound(String)
        case timeout(TimeInterval)
        case executionFailed(String)
        case invalidOutput

        var errorDescription: String? {
            switch self {
            case .executableNotFound(let path):
                return "실행 파일을 찾을 수 없습니다: \(path)"
            case .timeout(let seconds):
                return "프로세스 실행이 \(Int(seconds))초 후 타임아웃되었습니다"
            case .executionFailed(let message):
                return "프로세스 실행 실패: \(message)"
            case .invalidOutput:
                return "프로세스 출력을 파싱할 수 없습니다"
            }
        }
    }

    /// CLI 프로세스를 실행하고 stdout 결과를 반환합니다.
    /// - Parameters:
    ///   - executable: 실행 파일 경로 (예: "/usr/local/bin/claude")
    ///   - arguments: 명령 인수 배열
    ///   - timeout: 최대 대기 시간 (초)
    ///   - environment: 추가 환경 변수
    /// - Returns: stdout 출력 문자열
    func run(
        executable: String,
        arguments: [String],
        timeout: TimeInterval = 30,
        environment: [String: String]? = nil
    ) async throws -> String {
        guard FileManager.default.fileExists(atPath: executable) else {
            throw ProcessError.executableNotFound(executable)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        // 기본 환경 변수에 PATH 포함
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
        if let environment {
            env.merge(environment) { _, new in new }
        }
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // stderr를 비동기로 계속 드레인하여 파이프 버퍼 데드락 방지
        // (Claude CLI는 MCP 도구 호출 시 stderr에 대량 로그를 출력하므로,
        //  64KB 파이프 버퍼가 가득 차면 프로세스가 블로킹되어 데드락 발생)
        let stderrCapture = StderrCapture()
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if !chunk.isEmpty {
                stderrCapture.append(chunk)
            }
        }

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try process.run()
                let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                // readabilityHandler 정리
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                guard process.terminationStatus == 0 else {
                    // Claude CLI는 에러를 stdout에 출력하는 경우가 있으므로 양쪽 모두 확인
                    let stderr = stderrCapture.string ?? ""
                    let stdout = String(data: outputData, encoding: .utf8) ?? ""
                    let errorMessage = stderr.isEmpty ? stdout : stderr
                    throw ProcessError.executionFailed("exit \(process.terminationStatus): \(errorMessage)")
                }

                guard let output = String(data: outputData, encoding: .utf8) else {
                    throw ProcessError.invalidOutput
                }

                return output
            }

            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                process.terminate()
                throw ProcessError.timeout(timeout)
            }

            guard let result = try await group.next() else {
                throw ProcessError.invalidOutput
            }
            group.cancelAll()
            return result
        }
    }
}
