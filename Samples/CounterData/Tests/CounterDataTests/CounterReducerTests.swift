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
import Testing

@Suite final actor CounterReducerTests {
  
}

extension CounterReducerTests {
  @Test(
    arguments: [-1, 0, 1]
  ) func didTapIncrementButton(value: Int) {
    let state = CounterReducer.reduce(
      state: CounterState(value),
      action: .didTapIncrementButton
    )
    #expect(state.value == (value + 1))
  }
}

extension CounterReducerTests {
  @Test(
    arguments: [-1, 0, 1]
  ) func didTapDecrementButton(value: Int) {
    let state = CounterReducer.reduce(
      state: CounterState(value),
      action: .didTapDecrementButton
    )
    #expect(state.value == (value - 1))
  }
}
