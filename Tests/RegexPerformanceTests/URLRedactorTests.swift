import XCTest
@testable import RegexPerformance

final class URLRedactorTests: XCTestCase {
    
    func testClientRouteRedaction() {
        let parser = RouteParser()
        let redactor = ClientRouteURLRedactor(parser: parser)
        
        // Test that it can redact feature URLs
        let result1 = redactor.redact(urlString: "/feature/123")
        if case .redacted(let redacted) = result1 {
            XCTAssertEqual(redacted, "/feature/:id")
        } else {
            XCTFail("Expected redacted result")
        }
        
        // Test that it handles unknown URLs
        let result2 = redactor.redact(urlString: "/unknown/path")
        if case .notApplicable = result2 {
            // Success
        } else {
            XCTFail("Expected notApplicable result")
        }
    }
    
    func testAggregateRedactor() {
        let parser = RouteParser()
        let clientRouteRedactor = ClientRouteURLRedactor(parser: parser)
        let aggregate = AggregateRedactor(redactors: [clientRouteRedactor])
        
        // Test that aggregate works
        let result1 = aggregate.redact(urlString: "/feature/456")
        if case .redacted(let redacted) = result1 {
            XCTAssertEqual(redacted, "/feature/:id")
        } else {
            XCTFail("Expected redacted result")
        }
        
        // Test that it handles unknown URLs
        let result2 = aggregate.redact(urlString: "/unknown")
        if case .notApplicable = result2 {
            // Success
        } else {
            XCTFail("Expected notApplicable result")
        }
    }
}
