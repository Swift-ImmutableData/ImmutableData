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

import CounterData
import ImmutableData
import ImmutableUI
import SwiftUI

//  https://developer.apple.com/forums/thread/763442

@MainActor public struct Content {
  @SelectValue private var value
  
  @Dispatch private var dispatch
  
  public init() {
    
  }
}

extension Content : View {
  public var body: some View {
    VStack {
      Button("Increment") {
        self.didTapIncrementButton()
      }
      Text("Value: \(self.value)")
      Button("Decrement") {
        self.didTapDecrementButton()
      }
    }
    .frame(
      minWidth: 256,
      minHeight: 256
    )
  }
}

extension Content {
  private func didTapIncrementButton() {
    do {
      try self.dispatch(.didTapIncrementButton)
    } catch {
      print(error)
    }
  }
}

extension Content {
  private func didTapDecrementButton() {
    do {
      try self.dispatch(.didTapDecrementButton)
    } catch {
      print(error)
    }
  }
}

#Preview {
  Content()
}

#Preview {
  @Previewable @State var store = ImmutableData.Store(
    initialState: CounterState(),
    reducer: CounterReducer.reduce
  )
  
  Provider(store) {
    Content()
  }
}

fileprivate struct CounterError : Swift.Error {
  let state: CounterState
  let action: CounterAction
}

#Preview {
  @Previewable @State var store = ImmutableData.Store(
    initialState: CounterState(),
    reducer: { (state: CounterState, action: CounterAction) -> (CounterState) in
      throw CounterError(
        state: state,
        action: action
      )
    }
  )
  
  Provider(store) {
    Content()
  }
}
