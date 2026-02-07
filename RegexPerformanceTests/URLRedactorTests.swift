import XCTest
@testable import RegexPerformance

final class URLRedactorTests: XCTestCase {
    func testClientRouteRedaction() {
        let redactor = ClientRouteURLRedactor()
        
        // Test redaction with applicable URL
        let result1 = redactor.redact(urlString: "/feature/123")
        if case .redacted(let redacted) = result1 {
            XCTAssertEqual(redacted, "/feature/:id")
        } else {
            XCTFail("Expected redacted result")
        }
        
        // Test redaction with non-applicable URL
        let result2 = redactor.redact(urlString: "/unknown/path")
        if case .notApplicable = result2 {
            // Success
        } else {
            XCTFail("Expected notApplicable result")
        }
    }
    
    func testAggregateRedactor() {
        let aggregate = AggregateRedactor(redactors: [
            ClientRouteURLRedactor()
        ])
        
        // Test redaction with applicable URL
        let result = aggregate.redact(urlString: "/feature/456")
        if case .redacted(let redacted) = result {
            XCTAssertEqual(redacted, "/feature/:id")
        } else {
            XCTFail("Expected redacted result")
        }
        
        // Test redaction with non-applicable URL
        let result2 = aggregate.redact(urlString: "/unknown/path")
        if case .notApplicable = result2 {
            // Success
        } else {
            XCTFail("Expected notApplicable result")
        }
    }
}
