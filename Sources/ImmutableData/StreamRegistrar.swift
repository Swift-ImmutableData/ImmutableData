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

@MainActor final class StreamRegistrar<Element> : Sendable where Element : Sendable {
  private var count = 0
  private var dictionary = Dictionary<Int, AsyncStream<Element>.Continuation>()
  
  deinit {
    for continuation in self.dictionary.values {
      continuation.finish()
    }
  }
}

extension StreamRegistrar {
  func makeStream() -> AsyncStream<Element> {
    self.count += 1
    return self.makeStream(id: self.count)
  }
}

extension StreamRegistrar {
  func yield(_ element: Element) {
    for continuation in self.dictionary.values {
      continuation.yield(element)
    }
  }
}

extension StreamRegistrar {
  private func makeStream(id: Int) -> AsyncStream<Element> {
    let (stream, continuation) = AsyncStream.makeStream(of: Element.self)
    continuation.onTermination = { [weak self] termination in
      guard let self = self else { return }
      Task {
        await self.removeContinuation(id: id)
      }
    }
    self.dictionary[id] = continuation
    return stream
  }
}

extension StreamRegistrar {
  private func removeContinuation(id: Int) {
    self.dictionary[id] = nil
  }
}
