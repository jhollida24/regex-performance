import XCTest
@testable import RegexPerformance

final class URLRedactorTests: XCTestCase {
    
    func testClientRouteRedaction() {
        let parser = RouteParser()
        let redactor = ClientRouteURLRedactor(parser: parser)
        
        // Test that it can redact feature URLs
        XCTAssertTrue(redactor.isCapableOfRedacting(urlString: "/feature/123"))
        XCTAssertEqual(redactor.redact(urlString: "/feature/123"), "/feature/:id")
        
        // Test that it handles unknown URLs
        XCTAssertFalse(redactor.isCapableOfRedacting(urlString: "/unknown/path"))
        XCTAssertEqual(redactor.redact(urlString: "/unknown/path"), "/unknown/path")
    }
    
    func testAggregateRedactor() {
        let parser = RouteParser()
        let clientRouteRedactor = ClientRouteURLRedactor(parser: parser)
        let aggregate = AggregateRedactor(redactors: [clientRouteRedactor])
        
        // Test that aggregate works
        XCTAssertTrue(aggregate.isCapableOfRedacting(urlString: "/feature/456"))
        XCTAssertEqual(aggregate.redact(urlString: "/feature/456"), "/feature/:id")
        
        // Test that it handles unknown URLs
        XCTAssertFalse(aggregate.isCapableOfRedacting(urlString: "/unknown"))
        XCTAssertEqual(aggregate.redact(urlString: "/unknown"), "/unknown")
    }
}
