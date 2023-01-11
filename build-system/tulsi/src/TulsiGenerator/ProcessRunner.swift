

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Darwin
import Foundation


public final class ProcessRunner {

  
  public struct CompletionInfo {
    
    public let process: Process

    
    public let commandlineString: String
    
    public let stdout: Data
    
    public let stderr: Data

    
    public var terminationStatus: Int32 {
      return process.terminationStatus
    }
  }

  
  final class TimedProcessRunnerObserver: NSObject {
    
    private var processObserver: NSKeyValueObservation?

    
    
    
    
    private var pendingLogHandles = Dictionary<Process, LocalizedMessageLogger.LogSessionHandle>()

    
    
    
    
    private var pendingLogHandlesLock = os_unfair_lock()

    
    
    
    
    
    
    
    
    private func accessPendingLogHandles<T>(usePendingLogHandles: (inout Dictionary<Process, LocalizedMessageLogger.LogSessionHandle>) throws -> T) rethrows -> T {
      os_unfair_lock_lock(&pendingLogHandlesLock)
      defer {
        os_unfair_lock_unlock(&pendingLogHandlesLock)
      }

      return try usePendingLogHandles(&pendingLogHandles)
    }

    
    fileprivate func startLoggingProcessTime(process: Process,
                                             loggingIdentifier: String,
                                             messageLogger: LocalizedMessageLogger) {
      let logSessionHandle = messageLogger.startProfiling(loggingIdentifier)
      accessPendingLogHandles { pendingLogHandles in
        pendingLogHandles[process] = logSessionHandle
      }
      processObserver = process.observe(\.isRunning, options: .new) {
        [unowned self] process, change in
        guard change.newValue == true else { return }
        self.accessPendingLogHandles { pendingLogHandles in
          pendingLogHandles[process]?.resetStartTime()
        }
      }
    }

    
    fileprivate func stopLogging(process: Process, messageLogger: LocalizedMessageLogger) {
      if let logHandle = self.pendingLogHandles[process] {
        messageLogger.logProfilingEnd(logHandle)
        processObserver?.invalidate()
        accessPendingLogHandles { pendingLogHandles in
          _ = pendingLogHandles.removeValue(forKey: process)
        }
      }
    }
  }


  public typealias CompletionHandler = (CompletionInfo) -> Void

  private static var defaultInstance: ProcessRunner = {
    ProcessRunner()
  }()

  
  private var pendingProcesses = Set<Process>()
  private let processReader: ProcessOutputReader


  
  private let timedProcessRunnerObserver = TimedProcessRunnerObserver()


  
  
  static func createProcess(_ launchPath: String,
                            arguments: [String],
                            environment: [String: String]? = nil,
                            messageLogger: LocalizedMessageLogger? = nil,
                            loggingIdentifier: String? = nil,
                            terminationHandler: @escaping CompletionHandler) -> Process {
    return defaultInstance.createProcess(launchPath,
                                         arguments: arguments,
                                         environment: environment,
                                         messageLogger: messageLogger,
                                         loggingIdentifier: loggingIdentifier,
                                         terminationHandler: terminationHandler)
  }

  
  
  static func launchProcessSync(_ launchPath: String,
                                arguments: [String],
                                environment: [String: String]? = nil,
                                messageLogger: LocalizedMessageLogger? = nil,
                                loggingIdentifier: String? = nil) -> CompletionInfo {
    let semaphore = DispatchSemaphore(value: 0)
    var completionInfo: CompletionInfo! = nil
    let process = defaultInstance.createProcess(launchPath,
                                                arguments: arguments,
                                                environment: environment,
                                                messageLogger: messageLogger,
                                                loggingIdentifier: loggingIdentifier) {
      processCompletionInfo in
        completionInfo = processCompletionInfo
        semaphore.signal()
    }

    process.launch()
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    return completionInfo
  }

  

  private init() {
    processReader = ProcessOutputReader()
    processReader.start()
  }

  deinit {
    processReader.stop()
  }

  private func createProcess(_ launchPath: String,
                             arguments: [String],
                             environment: [String: String]? = nil,
                             messageLogger: LocalizedMessageLogger? = nil,
                             loggingIdentifier: String? = nil,
                             terminationHandler: @escaping CompletionHandler) -> Process {
    let process = Process()
    process.launchPath = launchPath
    process.arguments = arguments
    if let environment = environment {
      process.environment = environment
    }
    
    let commandlineArguments = arguments.map { $0.escapingForShell }.joined(separator: " ")
    let commandlineRunnableString = "\(launchPath.escapingForShell) \(commandlineArguments)"

    
    if let messageLogger = messageLogger {
      timedProcessRunnerObserver.startLoggingProcessTime(process: process,
                                                         loggingIdentifier: (loggingIdentifier ?? launchPath),
                                                         messageLogger: messageLogger)
      messageLogger.infoMessage("Running \(commandlineRunnableString)")
    }

    let dispatchGroup = DispatchGroup()
    let notificationCenter = NotificationCenter.default
    func registerAndStartReader(_ fileHandle: FileHandle, outputData: NSMutableData) -> NSObjectProtocol {
      let observer = notificationCenter.addObserver(forName: NSNotification.Name.NSFileHandleReadToEndOfFileCompletion,
                                                    object: fileHandle,
                                                    queue: nil) { (notification: Notification) in
        defer { dispatchGroup.leave() }
        if let err = notification.userInfo?["NSFileHandleError"] as? NSNumber {
          assertionFailure("Read from pipe failed with error \(err)")
        }
        guard let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data else {
          assertionFailure("Unexpectedly received no data in read handler")
          return
        }
        outputData.append(data)
      }

      dispatchGroup.enter()

      
      
      
      let selector = #selector(FileHandle.readToEndOfFileInBackgroundAndNotify as (FileHandle) -> () -> Void)
      fileHandle.perform(selector, on: processReader.thread, with: nil, waitUntilDone: true)
      return observer
    }

    let stdoutData = NSMutableData()
    process.standardOutput = Pipe()
    let stdoutObserver = registerAndStartReader((process.standardOutput! as AnyObject).fileHandleForReading,
                                                outputData: stdoutData)
    let stderrData = NSMutableData()
    process.standardError = Pipe()
    let stderrObserver = registerAndStartReader((process.standardError! as AnyObject).fileHandleForReading,
                                                outputData: stderrData)

    process.terminationHandler = { (process: Process) -> Void in
      
      
      assert(!Thread.isMainThread,
             "Process termination handler unexpectedly called on main thread.")
      _ = dispatchGroup.wait(timeout: DispatchTime.distantFuture)

      
      if let messageLogger = messageLogger {
        self.timedProcessRunnerObserver.stopLogging(process: process, messageLogger: messageLogger)
      }

      terminationHandler(CompletionInfo(process: process,
                                        commandlineString: commandlineRunnableString,
                                        stdout: stdoutData as Data,
                                        stderr: stderrData as Data))

      Thread.doOnMainQueue {
        notificationCenter.removeObserver(stdoutObserver)
        notificationCenter.removeObserver(stderrObserver)
        assert(self.pendingProcesses.contains(process), "terminationHandler called with unexpected process")
        self.pendingProcesses.remove(process)
      }
    }

    Thread.doOnMainQueue {
      self.pendingProcesses.insert(process)
    }
    return process
  }


  

  
  private class ProcessOutputReader: NSObject {
    lazy var thread: Thread = { [unowned self] in
      let value = Thread(target: self, selector: #selector(threadMain(_:)), object: nil)
      value.name = "com.google.Tulsi.ProcessOutputReader"
      return value
    }()

    private var continueRunning = false

    func start() {
      assert(!thread.isExecuting, "Start called twice without a stop")
      thread.start()
    }

    func stop() {
      perform(#selector(ProcessOutputReader.stopThread),
                        on:thread,
                        with:nil,
                        waitUntilDone: false)
    }

    

    @objc
    private func threadMain(_ object: AnyObject) {
      let runLoop = RunLoop.current
      
      runLoop.add(NSMachPort(), forMode: RunLoop.Mode.default)

      while !thread.isCancelled {
        runLoop.run(mode: RunLoop.Mode.default, before: Date.distantFuture)
      }
    }

    @objc
    private func stopThread() {
      thread.cancel()
    }
  }
}
