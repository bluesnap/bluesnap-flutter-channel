import Flutter
import UIKit
import XCTest

@testable import bluesnap_sdk

// Unit tests of the Swift side of the plugin, hosted in the example app.
// Run them with `xcodebuild test` (see example/integration_test/README.md).
class RunnerTests: XCTestCase {

  private var engine: FlutterEngine!
  private var plugin: BluesnapSdkPlugin!

  override func setUp() {
    super.setUp()
    engine = FlutterEngine(name: "RunnerTests")
    let registrar = engine.registrar(forPlugin: "RunnerTests")!
    let channel = FlutterMethodChannel(name: "bluesnap_sdk", binaryMessenger: registrar.messenger())
    plugin = BluesnapSdkPlugin(methodChannel: channel, pluginRegistrar: registrar)
  }

  override func tearDown() {
    plugin = nil
    engine = nil
    super.tearDown()
  }

  private func call(_ method: String, _ arguments: Any? = nil) -> Any? {
    var reply: Any?
    let replied = expectation(description: "\(method) replied")
    plugin.handle(FlutterMethodCall(methodName: method, arguments: arguments)) { result in
      reply = result
      replied.fulfill()
    }
    wait(for: [replied], timeout: 1)
    return reply
  }

  func testUnknownMethodIsNotImplemented() {
    XCTAssertTrue(call("getPlatformVersion") as AnyObject === FlutterMethodNotImplemented)
  }

  func testSetSDKRequestBuildsTheCheckoutRequest() throws {
    let reply = call("setSDKRequest", [
      "amount": 20.5,
      "taxAmount": 1.5,
      "currency": "EUR",
      "withEmail": false,
      "withShipping": true,
      "fullBilling": true,
      "activate3DS": true,
    ] as [String: Any])

    XCTAssertNil(reply)
    let request = try XCTUnwrap(plugin.sdkre)
    XCTAssertEqual(request.priceDetails.amount, 20.5)
    XCTAssertEqual(request.priceDetails.taxAmount, 1.5)
    XCTAssertEqual(request.priceDetails.currency, "EUR")
    XCTAssertFalse(request.shopperConfiguration.withEmail)
    XCTAssertTrue(request.shopperConfiguration.withShipping)
    XCTAssertTrue(request.shopperConfiguration.fullBilling)
    XCTAssertTrue(request.activate3DS)
  }

  func testSetSDKRequestRejectsMissingArguments() throws {
    let reply = call("setSDKRequest", ["amount": 20.5] as [String: Any])

    let error = try XCTUnwrap(reply as? FlutterError)
    XCTAssertEqual(error.message, "Invalid parameter")
    XCTAssertNil(plugin.sdkre)
  }

  // The plugin pushes the BlueSnap screens onto the root UINavigationController,
  // so the example app must put the Flutter view inside one (Main.storyboard).
  func testAppShowsFlutterInsideANavigationController() throws {
    let root = try XCTUnwrap(rootViewController() as? UINavigationController)
    XCTAssertTrue(root.viewControllers.first is FlutterViewController)
    XCTAssertTrue(root.isNavigationBarHidden)
  }

  // The window scene may connect after the tests start.
  private func rootViewController() -> UIViewController? {
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
      let root = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
        .first
      if root != nil { return root }
      RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
    return nil
  }
}
