import XCTest
@testable import RegexPerformance

final class URLRedactorTests: XCTestCase {
    func testClientRouteRedaction() {
        let patterns: [(pattern: String, parameterNames: [String])] = [
            ("^/feature/([^/]+)$", ["id"])
        ]
        let parser = RouteParser(patterns: patterns)
        let redactor = ClientRouteURLRedactor(parser: parser)
        
        XCTAssertTrue(redactor.isCapableOfRedacting(urlString: "https://example.com/feature/123"))
        
        let redacted = redactor.redact(urlString: "https://example.com/feature/123")
        XCTAssertTrue(redacted.contains("redacted"))
    }
    
    func testAggregateRedactor() {
        let patterns: [(pattern: String, parameterNames: [String])] = [
            ("^/feature/([^/]+)$", ["id"])
        ]
        let parser = RouteParser(patterns: patterns)
        let clientRedactor = ClientRouteURLRedactor(parser: parser)
        let aggregate = AggregateRedactor(redactors: [clientRedactor])
        
        XCTAssertTrue(aggregate.isCapableOfRedacting(urlString: "https://example.com/feature/123"))
        
        let redacted = aggregate.redact(urlString: "https://example.com/feature/123")
        XCTAssertTrue(redacted.contains("redacted"))
    }
}
