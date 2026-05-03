import Foundation
#if canImport(WebKit)
import WebKit
#endif

@MainActor
public protocol JavaScriptEvaluating: AnyObject {
    func evaluateJavaScript(_ javaScriptString: String) async throws -> Any?
}

#if canImport(WebKit)
extension WKWebView: JavaScriptEvaluating {}
#endif

@MainActor
public final class WebPlayerController: PlayerControlling {
    private let evaluator: JavaScriptEvaluating

    public init(evaluator: JavaScriptEvaluating) {
        self.evaluator = evaluator
    }

    public func perform(_ command: PlayerCommand) async throws {
        _ = try await evaluator.evaluateJavaScript(command.javaScript)
    }
}
