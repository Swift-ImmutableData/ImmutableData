//
//  Copyright 2024 Rick van Voorden and Bill Fisher
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

//  https://github.com/swiftlang/swift-evolution/blob/main/proposals/0300-continuation.md

final public actor AsyncSequenceTestDouble<Element> : AsyncSequence where Element : Sendable {
  public let iterator: Iterator
  
  public init() {
    self.iterator = Iterator()
  }
}

extension AsyncSequenceTestDouble {
  public nonisolated func makeAsyncIterator() -> Iterator {
    self.iterator
  }
}

extension AsyncSequenceTestDouble {
  final public actor Iterator {
    private var nextQueue = Array<CheckedContinuation<Element?, Never>>()
    private var sendQueue = Array<CheckedContinuation<Void, Never>>()
    private var isCancelled = false
  }
}

extension AsyncSequenceTestDouble.Iterator: AsyncIteratorProtocol {
  public func next() async throws -> Element? {
    if self.sendQueue.isEmpty == false {
      self.sendQueue.removeFirst().resume()
    }
    if Task.isCancelled || self.isCancelled {
      return nil
    }
    return await withTaskCancellationHandler {
      let value = await withCheckedContinuation { continuation in
        self.nextQueue.append(continuation)
        if self.sendQueue.isEmpty == false {
          self.sendQueue.removeFirst().resume()
        }
      }
      if Task.isCancelled || self.isCancelled {
        return nil
      }
      if let value = value {
        return value
      }
      self.isCancelled = true
      defer {
        self.sendQueue.removeFirst().resume()
      }
      return nil
    } onCancel: {
      Task {
        await self.onCancel()
      }
    }
  }
}

extension AsyncSequenceTestDouble.Iterator {
  public func resume(returning element: Element?) async {
    if self.isCancelled {
      return
    }
    if self.nextQueue.isEmpty {
      await withCheckedContinuation { continuation in
        self.sendQueue.append(continuation)
      }
    }
    await withCheckedContinuation { continuation in
      self.sendQueue.append(continuation)
      self.nextQueue.removeFirst().resume(returning: element)
    }
  }
}

extension AsyncSequenceTestDouble.Iterator {
  private func onCancel() {
    if self.nextQueue.isEmpty == false {
      self.nextQueue.removeFirst().resume(returning: nil)
    }
    if self.sendQueue.isEmpty == false {
      self.sendQueue.removeFirst().resume()
    }
    self.isCancelled = true
  }
}
