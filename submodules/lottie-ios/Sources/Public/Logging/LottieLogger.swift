






public final class LottieLogger {

  

  public init(
    assert: @escaping Assert = Swift.assert,
    assertionFailure: @escaping AssertionFailure = Swift.assertionFailure,
    warn: @escaping Warn = { message, _, _ in
      #if DEBUG
      
      print(message())
      #endif
    })
  {
    _assert = assert
    _assertionFailure = assertionFailure
    _warn = warn
  }

  

  
  public typealias Assert = (
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String,
    _ fileID: StaticString,
    _ line: UInt)
    -> Void

  
  public typealias AssertionFailure = (
    _ message: @autoclosure () -> String,
    _ fileID: StaticString,
    _ line: UInt)
    -> Void

  
  public typealias Warn = (
    _ message: @autoclosure () -> String,
    _ fileID: StaticString,
    _ line: UInt)
    -> Void

  
  
  
  public static var shared = LottieLogger()

  
  public func assert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = String(),
    fileID: StaticString = #fileID,
    line: UInt = #line)
  {
    _assert(condition(), message(), fileID, line)
  }

  
  public func assertionFailure(
    _ message: @autoclosure () -> String = String(),
    fileID: StaticString = #fileID,
    line: UInt = #line)
  {
    _assertionFailure(message(), fileID, line)
  }

  
  public func warn(
    _ message: @autoclosure () -> String = String(),
    fileID: StaticString = #fileID,
    line: UInt = #line)
  {
    _warn(message(), fileID, line)
  }

  

  private let _assert: Assert
  private let _assertionFailure: AssertionFailure
  private let _warn: Warn

}



extension LottieLogger {
  
  
  public static var printToConsole: LottieLogger {
    LottieLogger(
      assert: { condition, message, _, _ in
        if !condition() {
          print(message())
        }
      },
      assertionFailure: { message, _, _ in
        print(message())
      })
  }
}
