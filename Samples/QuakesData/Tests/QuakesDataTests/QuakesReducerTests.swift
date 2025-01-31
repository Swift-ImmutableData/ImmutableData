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

import Collections
import Foundation
import QuakesData
import Testing

@Suite final actor QuakesReducerTests {
  private static let state = QuakesState(
    quakes: QuakesState.Quakes(
      data: TreeDictionary(
        Quake(
          quakeId: "1",
          magnitude: 0.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "2",
          magnitude: 1.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "3",
          magnitude: 2.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "4",
          magnitude: 3.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "5",
          magnitude: 4.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "6",
          magnitude: 5.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "7",
          magnitude: 6.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        ),
        Quake(
          quakeId: "8",
          magnitude: 7.5,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        )
      )
    )
  )
}

extension QuakesReducerTests {
  @Test func uiListOnAppear() throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .ui(
        .quakeList(
          .onAppear
        )
      )
    )
    #expect(state.quakes.data == Self.state.quakes.data)
    #expect(state.quakes.status == .waiting)
  }
}

extension QuakesReducerTests {
  @Test(
    arguments: [
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allHour,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allDay,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allWeek,
      QuakesAction.UI.QuakeList.RefreshQuakesRange.allMonth,
    ]
  ) func uiListOnTapRefreshQuakesButton(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .ui(
        .quakeList(
          .onTapRefreshQuakesButton(
            range: range
          )
        )
      )
    )
    #expect(state.quakes.data == Self.state.quakes.data)
    #expect(state.quakes.status == .waiting)
  }
}

extension QuakesReducerTests {
  @Test(arguments: Self.state.quakes.data.values) func onTapDeleteSelectedQuakeButton(quake: Quake) throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .ui(
        .quakeList(
          .onTapDeleteSelectedQuakeButton(
            quakeId: quake.id
          )
        )
      )
    )
    #expect(state.quakes.data == {
      var data = Self.state.quakes.data
      data[quake.id] = nil
      return data
    }())
    #expect(state.quakes.status == nil)
  }
}

extension QuakesReducerTests {
  @Test(arguments: Self.state.quakes.data.values) func onTapDeleteSelectedQuakeButtonThrows(quake: Quake) throws {
    var state = Self.state
    state.quakes.data[quake.id] = nil
    #expect {
      let _ = try QuakesReducer.reduce(
        state: state,
        action: .ui(
          .quakeList(
            .onTapDeleteSelectedQuakeButton(
              quakeId: quake.id
            )
          )
        )
      )
    } throws: { error in
      let error = try #require(
        error as? QuakesReducer.Error
      )
      return error.code == .quakeNotFound
    }
  }
}

extension QuakesReducerTests {
  @Test func onTapDeleteAllQuakesButton() throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .ui(
        .quakeList(
          .onTapDeleteAllQuakesButton
        )
      )
    )
    #expect(state.quakes.data == [:])
    #expect(state.quakes.status == nil)
  }
}

extension QuakesReducerTests {
  @Test func dataPersistentSessionLocalStoreDidFetchQuakesSuccess() throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .localStore(
            .didFetchQuakes(
              result: .success(
                quakes: [
                  Quake(
                    quakeId: "quakeId",
                    magnitude: 1.0,
                    time: Date(timeIntervalSince1970: 0.0),
                    updated: Date(timeIntervalSince1970: 0.0),
                    name: "name",
                    longitude: -125,
                    latitude: 35
                  )
                ]
              )
            )
          )
        )
      )
    )
    #expect(state.quakes.data == {
      var data = Self.state.quakes.data
      data["quakeId"] = Quake(
        quakeId: "quakeId",
        magnitude: 1.0,
        time: Date(timeIntervalSince1970: 0.0),
        updated: Date(timeIntervalSince1970: 0.0),
        name: "name",
        longitude: -125,
        latitude: 35
      )
      return data
    }())
    #expect(state.quakes.status == .success)
  }
}

extension QuakesReducerTests {
  @Test func dataPersistentSessionLocalStoreDidFetchQuakesFailure() throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .localStore(
            .didFetchQuakes(
              result: .failure(
                error: "error"
              )
            )
          )
        )
      )
    )
    #expect(state.quakes.data == Self.state.quakes.data)
    #expect(state.quakes.status == .failure(error: "error"))
  }
}

extension QuakesReducerTests {
  @Test func dataPersistentSessionRemoteStoreDidFetchQuakesSuccess() throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .remoteStore(
            .didFetchQuakes(
              result: .success(
                quakes: [
                  Quake(
                    quakeId: "1",
                    magnitude: 1.0,
                    time: Date(timeIntervalSince1970: 1.0),
                    updated: Date(timeIntervalSince1970: 2.0),
                    name: "name",
                    longitude: -125,
                    latitude: 35
                  ),
                  Quake(
                    quakeId: "2",
                    magnitude: 0.0,
                    time: Date(timeIntervalSince1970: 1.0),
                    updated: Date(timeIntervalSince1970: 1.0),
                    name: "West of California",
                    longitude: -125,
                    latitude: 35
                  ),
                  Quake(
                    quakeId: "quakeId",
                    magnitude: 1.0,
                    time: Date(timeIntervalSince1970: 0.0),
                    updated: Date(timeIntervalSince1970: 0.0),
                    name: "name",
                    longitude: -125,
                    latitude: 35
                  )
                ]
              )
            )
          )
        )
      )
    )
    #expect(state.quakes.data == {
      var data = Self.state.quakes.data
      data["1"] = Quake(
        quakeId: "1",
        magnitude: 1.0,
        time: Date(timeIntervalSince1970: 1.0),
        updated: Date(timeIntervalSince1970: 2.0),
        name: "name",
        longitude: -125,
        latitude: 35
      )
      data["2"] = nil
      data["quakeId"] = Quake(
        quakeId: "quakeId",
        magnitude: 1.0,
        time: Date(timeIntervalSince1970: 0.0),
        updated: Date(timeIntervalSince1970: 0.0),
        name: "name",
        longitude: -125,
        latitude: 35
      )
      return data
    }())
    #expect(state.quakes.status == .success)
  }
}

extension QuakesReducerTests {
  @Test func dataPersistentSessionRemoteStoreDidFetchQuakesFailure() throws {
    let state = try QuakesReducer.reduce(
      state: Self.state,
      action: .data(
        .persistentSession(
          .remoteStore(
            .didFetchQuakes(
              result: .failure(
                error: "error"
              )
            )
          )
        )
      )
    )
    #expect(state.quakes.data == Self.state.quakes.data)
    #expect(state.quakes.status == .failure(error: "error"))
  }
}
