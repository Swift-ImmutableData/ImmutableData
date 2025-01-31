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

#if os(macOS)

import Foundation
import QuakesData
import Services

extension NetworkSession: RemoteStoreNetworkSession {
  
}

func makeLocalStore() throws -> LocalStore {
  if let url = Process().currentDirectoryURL?.appending(
    component: "default.store",
    directoryHint: .notDirectory
  ) {
    return try LocalStore(url: url)
  }
  return try LocalStore()
}

func makeRemoteStore() -> RemoteStore<NetworkSession<URLSession>> {
  let session = NetworkSession(urlSession: URLSession.shared)
  return RemoteStore(session: session)
}

func main() async throws {
  let localStore = try makeLocalStore()
  let remoteStore = makeRemoteStore()
  
  let localQuakes = try await localStore.fetchLocalQuakesQuery()
  print(localQuakes)
  
  let remoteQuakes = try await remoteStore.fetchRemoteQuakesQuery(range: .allHour)
  print(remoteQuakes)
}

try await main()

#endif
