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

import AnimalsData
import Foundation
import Services

func makeLocalStore() throws -> LocalStore<UUID> {
  if let url = Process().currentDirectoryURL?.appending(
    component: "default.store",
    directoryHint: .notDirectory
  ) {
    return try LocalStore<UUID>(url: url)
  }
  return try LocalStore<UUID>()
}

extension NetworkSession: RemoteStoreNetworkSession {
  
}

func makeRemoteStore() -> RemoteStore<NetworkSession<URLSession>> {
  let session = NetworkSession(urlSession: URLSession.shared)
  return RemoteStore(session: session)
}

func main() async throws {
  let store = makeRemoteStore()
  
  let animals = try await store.fetchAnimalsQuery()
  print(animals)
  
  let categories = try await store.fetchCategoriesQuery()
  print(categories)
}

try await main()

#endif
