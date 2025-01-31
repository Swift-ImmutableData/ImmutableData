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

public enum QuakesAction: Hashable, Sendable {
  case ui(_ action: UI)
  case data(_ action: Data)
}

extension QuakesAction {
  public enum UI: Hashable, Sendable {
    case quakeList(_ action: QuakeList)
  }
}

extension QuakesAction.UI {
  public enum QuakeList: Hashable, Sendable {
    case onAppear
    case onTapRefreshQuakesButton(range: RefreshQuakesRange)
    case onTapDeleteSelectedQuakeButton(quakeId: Quake.ID)
    case onTapDeleteAllQuakesButton
  }
}

extension QuakesAction.UI.QuakeList {
  public enum RefreshQuakesRange: Hashable, Sendable {
    case allHour
    case allDay
    case allWeek
    case allMonth
  }
}

extension QuakesAction {
  public enum Data: Hashable, Sendable {
    case persistentSession(_ action: PersistentSession)
  }
}

extension QuakesAction.Data {
  public enum PersistentSession: Hashable, Sendable {
    case localStore(_ action: LocalStore)
    case remoteStore(_ action: RemoteStore)
  }
}

extension QuakesAction.Data.PersistentSession {
  public enum LocalStore: Hashable, Sendable {
    case didFetchQuakes(result: FetchQuakesResult)
  }
}

extension QuakesAction.Data.PersistentSession.LocalStore {
  public enum FetchQuakesResult: Hashable, Sendable {
    case success(quakes: Array<Quake>)
    case failure(error: String)
  }
}

extension QuakesAction.Data.PersistentSession {
  public enum RemoteStore: Hashable, Sendable {
    case didFetchQuakes(result: FetchQuakesResult)
  }
}

extension QuakesAction.Data.PersistentSession.RemoteStore {
  public enum FetchQuakesResult: Hashable, Sendable {
    case success(quakes: Array<Quake>)
    case failure(error: String)
  }
}
