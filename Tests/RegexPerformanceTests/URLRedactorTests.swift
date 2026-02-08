import XCTest
@testable import RegexPerformance

final class URLRedactorTests: XCTestCase {
    func testClientRouteRedaction() {
        let patterns: [(pattern: String, parameterNames: [String])] = [
            ("^/feature/([^/]+)$", ["id"])
        ]
        let parser = RouteParser(patterns: patterns)
        let redactor = ClientRouteURLRedactor(parser: parser)
        
        let result = redactor.redact(urlString: "https://example.com/feature/123")
        
        if case .redacted(let redactedString) = result {
            XCTAssertTrue(redactedString.contains("redacted"))
        } else {
            XCTFail("Expected .redacted result")
        }
    }
    
    func testClientRouteNotApplicable() {
        let patterns: [(pattern: String, parameterNames: [String])] = [
            ("^/feature/([^/]+)$", ["id"])
        ]
        let parser = RouteParser(patterns: patterns)
        let redactor = ClientRouteURLRedactor(parser: parser)
        
        let result = redactor.redact(urlString: "https://example.com/other/path")
        
        if case .notApplicable = result {
            // Success
        } else {
            XCTFail("Expected .notApplicable result")
        }
    }
    
    func testAggregateRedactor() {
        let patterns: [(pattern: String, parameterNames: [String])] = [
            ("^/feature/([^/]+)$", ["id"])
        ]
        let parser = RouteParser(patterns: patterns)
        let clientRedactor = ClientRouteURLRedactor(parser: parser)
        let aggregate = AggregateRedactor(redactors: [clientRedactor])
        
        let result = aggregate.redact(urlString: "https://example.com/feature/123")
        
        if case .redacted(let redactedString) = result {
            XCTAssertTrue(redactedString.contains("redacted"))
        } else {
            XCTFail("Expected .redacted result")
        }
    }
}
