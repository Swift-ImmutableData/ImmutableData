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
import Vapor

extension LocalStore {
  fileprivate func response(request: RemoteRequest) throws -> RemoteResponse {
    RemoteResponse(
      query: try self.response(query: request.query),
      mutation: try self.response(mutation: request.mutation)
    )
  }
}

extension LocalStore {
  private func response(query: Array<RemoteRequest.Query>?) throws -> Array<RemoteResponse.Query>? {
    try query?.map { query in try self.response(query: query) }
  }
}

extension LocalStore {
  private func response(mutation: Array<RemoteRequest.Mutation>?) throws -> Array<RemoteResponse.Mutation>? {
    try mutation?.map { mutation in try self.response(mutation: mutation) }
  }
}

extension LocalStore {
  private func response(query: RemoteRequest.Query) throws -> RemoteResponse.Query {
    switch query {
    case .animals:
      let animals = try self.fetchAnimalsQuery()
      return .animals(animals: animals)
    case .categories:
      let categories = try self.fetchCategoriesQuery()
      return .categories(categories: categories)
    }
  }
}

extension LocalStore {
  private func response(mutation: RemoteRequest.Mutation) throws -> RemoteResponse.Mutation {
    switch mutation {
    case .addAnimal(name: let name, diet: let diet, categoryId: let categoryId):
      let animal = try self.addAnimalMutation(name: name, diet: diet, categoryId: categoryId)
      return .addAnimal(animal: animal)
    case .updateAnimal(animalId: let animalId, name: let name, diet: let diet, categoryId: let categoryId):
      let animal = try self.updateAnimalMutation(animalId: animalId, name: name, diet: diet, categoryId: categoryId)
      return .updateAnimal(animal: animal)
    case .deleteAnimal(animalId: let animalId):
      let animal = try self.deleteAnimalMutation(animalId: animalId)
      return .deleteAnimal(animal: animal)
    case .reloadSampleData:
      let (animals, categories) = try self.reloadSampleDataMutation()
      return .reloadSampleData(animals: animals, categories: categories)
    }
  }
}

func makeLocalStore() throws -> LocalStore<UUID> {
  if let url = Process().currentDirectoryURL?.appending(
    component: "default.store",
    directoryHint: .notDirectory
  ) {
    return try LocalStore<UUID>(url: url)
  }
  return try LocalStore<UUID>()
}

func main() async throws {
  let localStore = try makeLocalStore()
  let app = try await Application.make(.detect())
  app.post("animals", "api") { request in
    let response = Response()
    let remoteRequest = try request.content.decode(RemoteRequest.self)
    print(remoteRequest)
    let remoteResponse = try await localStore.response(request: remoteRequest)
    print(remoteResponse)
    try response.content.encode(remoteResponse, as: .json)
    return response
  }
  try await app.execute()
  try await app.asyncShutdown()
}

try await main()

#endif
