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

import AsyncSequenceTestUtils
import Testing

final fileprivate actor AsyncListenerTestDouble<Element> where Element : Sendable {
  var values = Array<Element>()
}

extension AsyncListenerTestDouble {
  func listen<Sequence>(to sequence: Sequence) async rethrows where Sequence : AsyncSequence, Sequence : Sendable, Sequence.Element == Element {
    var iterator = sequence.makeAsyncIterator()
    while let value = try await iterator.next() {
      self.values.append(value)
    }
  }
}

final fileprivate actor ListenerTestDouble<Element> where Element : Sendable {
  var listener: AsyncListenerTestDouble<Element>?
  var task: Task<Void, any Error>?
  
  deinit {
    self.task?.cancel()
  }
}

extension ListenerTestDouble {
  func listen<Sequence>(to sequence: Sequence) where Sequence : AsyncSequence, Sequence : Sendable, Sequence.Element == Element {
    self.listener = AsyncListenerTestDouble<Element>()
    self.task?.cancel()
    self.task = Task { [listener] in
      try await listener?.listen(to: sequence)
    }
  }
}

extension ListenerTestDouble {
  var values: Array<Element> {
    get async {
      guard let listener = self.listener else { fatalError() }
      return await listener.values
    }
  }
}

@Suite final actor AsyncSequenceTestDoubleTests {
  
}

extension AsyncSequenceTestDoubleTests {
  @Test func asyncListenerFinished() async throws {
    let listener = AsyncListenerTestDouble<Int>()
    do {
      let sequence = AsyncSequenceTestDouble<Int>()
      
      let task = Task {
        try await listener.listen(to: sequence)
      }
      
      await sequence.iterator.resume(returning: 1)
      #expect(await listener.values == [1])
      
      await sequence.iterator.resume(returning: 2)
      #expect(await listener.values == [1, 2])
      
      await sequence.iterator.resume(returning: nil)
      
      await sequence.iterator.resume(returning: 3)
      #expect(await listener.values == [1, 2])
      
      try await task.value
    }
    
    #expect(await listener.values == [1, 2])
  }
}

extension AsyncSequenceTestDoubleTests {
  @Test func asyncListenerCancelled() async throws {
    let listener = AsyncListenerTestDouble<Int>()
    do {
      let sequence = AsyncSequenceTestDouble<Int>()
      
      let task = Task {
        try await listener.listen(to: sequence)
      }
      
      await sequence.iterator.resume(returning: 1)
      #expect(await listener.values == [1])
      
      await sequence.iterator.resume(returning: 2)
      #expect(await listener.values == [1, 2])
      
      task.cancel()
      
      await sequence.iterator.resume(returning: 3)
      #expect(await listener.values == [1, 2])
      
      try await task.value
    }
    
    #expect(await listener.values == [1, 2])
  }
}

extension AsyncSequenceTestDoubleTests {
  @Test func listenerFinished() async throws {
    let listener = ListenerTestDouble<Int>()
    do {
      let sequence = AsyncSequenceTestDouble<Int>()
      
      await listener.listen(to: sequence)
      
      await sequence.iterator.resume(returning: 1)
      #expect(await listener.values == [1])
      
      await sequence.iterator.resume(returning: 2)
      #expect(await listener.values == [1, 2])
    }
    do {
      let sequence = AsyncSequenceTestDouble<Int>()

      await listener.listen(to: sequence)
      
      await sequence.iterator.resume(returning: 1)
      #expect(await listener.values == [1])
      
      await sequence.iterator.resume(returning: 2)
      #expect(await listener.values == [1, 2])
      
      await sequence.iterator.resume(returning: nil)
      
      await sequence.iterator.resume(returning: 3)
      #expect(await listener.values == [1, 2])
      
      try await listener.task?.value
    }
    
    #expect(await listener.values == [1, 2])
  }
}

extension AsyncSequenceTestDoubleTests {
  @Test func listenerCancelled() async throws {
    let listener = ListenerTestDouble<Int>()
    do {
      let sequence = AsyncSequenceTestDouble<Int>()
      
      await listener.listen(to: sequence)
      
      await sequence.iterator.resume(returning: 1)
      #expect(await listener.values == [1])
      
      await sequence.iterator.resume(returning: 2)
      #expect(await listener.values == [1, 2])
    }
    do {
      let sequence = AsyncSequenceTestDouble<Int>()

      await listener.listen(to: sequence)
      
      await sequence.iterator.resume(returning: 1)
      #expect(await listener.values == [1])
      
      await sequence.iterator.resume(returning: 2)
      #expect(await listener.values == [1, 2])
      
      await listener.task?.cancel()
      
      await sequence.iterator.resume(returning: 3)
      #expect(await listener.values == [1, 2])
      
      try await listener.task?.value
    }
    
    #expect(await listener.values == [1, 2])
  }
}
