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

public enum QuakesReducer {
  @Sendable public static func reduce(
    state: QuakesState,
    action: QuakesAction
  ) throws -> QuakesState {
    switch action {
    case .ui(.quakeList(action: let action)):
      return try self.reduce(state: state, action: action)
    case .data(.persistentSession(action: let action)):
      return try self.reduce(state: state, action: action)
    }
  }
}

extension QuakesReducer {
  private static func reduce(
    state: QuakesState,
    action: QuakesAction.UI.QuakeList
  ) throws -> QuakesState {
    switch action {
    case .onAppear:
      return self.onAppear(state: state)
    case .onTapRefreshQuakesButton:
      return self.onTapRefreshQuakesButton(state: state)
    case .onTapDeleteSelectedQuakeButton(quakeId: let quakeId):
      return try self.deleteSelectedQuake(state: state, quakeId: quakeId)
    case .onTapDeleteAllQuakesButton:
      return self.deleteAllQuakes(state: state)
    }
  }
}

extension QuakesReducer {
  private static func onAppear(state: QuakesState) -> QuakesState {
    if state.quakes.status == nil {
      var state = state
      state.quakes.status = .waiting
      return state
    }
    return state
  }
}

extension QuakesReducer {
  private static func onTapRefreshQuakesButton(state: QuakesState) -> QuakesState {
    if state.quakes.status != .waiting {
      var state = state
      state.quakes.status = .waiting
      return state
    }
    return state
  }
}

extension QuakesReducer {
  package struct Error: Swift.Error {
    package enum Code: Hashable, Sendable {
      case quakeNotFound
    }
    
    package let code: Self.Code
  }
}

extension QuakesReducer {
  private static func deleteSelectedQuake(
    state: QuakesState,
    quakeId: Quake.ID
  ) throws -> QuakesState {
    guard let _ = state.quakes.data[quakeId] else {
      throw Error(code: .quakeNotFound)
    }
    var state = state
    state.quakes.data[quakeId] = nil
    return state
  }
}

extension QuakesReducer {
  private static func deleteAllQuakes(state: QuakesState) -> QuakesState {
    var state = state
    state.quakes.data = [:]
    return state
  }
}

extension QuakesReducer {
  private static func reduce(
    state: QuakesState,
    action: QuakesAction.Data.PersistentSession
  ) throws -> QuakesState {
    switch action {
    case .localStore(.didFetchQuakes(result: let result)):
      return self.didFetchQuakes(state: state, result: result)
    case .remoteStore(.didFetchQuakes(result: let result)):
      return self.didFetchQuakes(state: state, result: result)
    }
  }
}

extension QuakesReducer {
  private static func didFetchQuakes(
    state: QuakesState,
    result: QuakesAction.Data.PersistentSession.LocalStore.FetchQuakesResult
  ) -> QuakesState {
    var state = state
    switch result {
    case .success(quakes: let quakes):
      var data = state.quakes.data
      for quake in quakes {
        data[quake.id] = quake
      }
      state.quakes.data = data
      state.quakes.status = .success
    case .failure(error: let error):
      state.quakes.status = .failure(error: error)
    }
    return state
  }
}

extension QuakesReducer {
  private static func didFetchQuakes(
    state: QuakesState,
    result: QuakesAction.Data.PersistentSession.RemoteStore.FetchQuakesResult
  ) -> QuakesState {
    var state = state
    switch result {
    case .success(quakes: let quakes):
      var data = state.quakes.data
      for quake in quakes {
        if .zero < quake.magnitude {
          data[quake.id] = quake
        } else {
          data[quake.id] = nil
        }
      }
      state.quakes.data = data
      state.quakes.status = .success
    case .failure(error: let error):
      state.quakes.status = .failure(error: error)
    }
    return state
  }
}
