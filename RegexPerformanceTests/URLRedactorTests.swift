import XCTest
@testable import RegexPerformance

final class URLRedactorTests: XCTestCase {
    func testClientRouteRedaction() {
        let redactor = ClientRouteURLRedactor()
        
        XCTAssertTrue(redactor.isCapableOfRedacting(urlString: "/feature/123"))
        XCTAssertEqual(redactor.redact(urlString: "/feature/123"), "/feature/:id")
    }
    
    func testAggregateRedactor() {
        let aggregate = AggregateRedactor(redactors: [
            ClientRouteURLRedactor()
        ])
        
        XCTAssertTrue(aggregate.isCapableOfRedacting(urlString: "/feature/456"))
        XCTAssertEqual(aggregate.redact(urlString: "/feature/456"), "/feature/:id")
    }
}
