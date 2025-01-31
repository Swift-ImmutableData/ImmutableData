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

public enum QuakesFilter {
  
}

extension QuakesFilter {
  public static func filterQuakes() -> @Sendable (QuakesState, QuakesAction) -> Bool {
    { oldState, action in
      switch action {
      case .ui(.quakeList(.onTapDeleteSelectedQuakeButton)):
        return true
      case .ui(.quakeList(.onTapDeleteAllQuakesButton)):
        return true
      case .data(.persistentSession(.localStore(.didFetchQuakes(.success)))):
        return true
      case .data(.persistentSession(.remoteStore(.didFetchQuakes(.success)))):
        return true
      default:
        return false
      }
    }
  }
}
