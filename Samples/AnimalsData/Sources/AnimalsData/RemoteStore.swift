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

import Foundation

package struct RemoteRequest: Hashable, Codable, Sendable {
  package let query: Array<Query>?
  package let mutation: Array<Mutation>?
  
  package init(
    query: Array<Query>? = nil,
    mutation: Array<Mutation>? = nil
  ) {
    self.query = query
    self.mutation = mutation
  }
}

extension RemoteRequest {
  package enum Query: Hashable, Codable, Sendable {
    case categories
    case animals
  }
}

extension RemoteRequest {
  package enum Mutation: Hashable, Codable, Sendable {
    case addAnimal(
      name: String,
      diet: Animal.Diet,
      categoryId: String
    )
    case updateAnimal(
      animalId: String,
      name: String,
      diet: Animal.Diet,
      categoryId: String
    )
    case deleteAnimal(animalId: String)
    case reloadSampleData
  }
}

extension RemoteRequest {
  fileprivate init(query: Query) {
    self.init(
      query: [
        query
      ]
    )
  }
}

extension RemoteRequest {
  fileprivate init(mutation: Mutation) {
    self.init(
      mutation: [
        mutation
      ]
    )
  }
}

package struct RemoteResponse: Hashable, Codable, Sendable {
  package let query: Array<Query>?
  package let mutation: Array<Mutation>?
  
  package init(
    query: Array<Query>? = nil,
    mutation: Array<Mutation>? = nil
  ) {
    self.query = query
    self.mutation = mutation
  }
}

extension RemoteResponse {
  package enum Query: Hashable, Codable, Sendable {
    case categories(categories: Array<Category>)
    case animals(animals: Array<Animal>)
  }
}

extension RemoteResponse {
  package enum Mutation: Hashable, Codable, Sendable {
    case addAnimal(animal: Animal)
    case updateAnimal(animal: Animal)
    case deleteAnimal(animal: Animal)
    case reloadSampleData(
      animals: Array<Animal>,
      categories: Array<Category>
    )
  }
}

extension RemoteResponse.Query {
  package struct Error: Swift.Error {
    package enum Code: Equatable {
      case categoriesNotFound
      case animalsNotFound
    }
    
    package let code: Self.Code
  }
}

extension RemoteResponse.Mutation {
  package struct Error: Swift.Error {
    package enum Code: Equatable {
      case animalNotFound
      case sampleDataNotFound
    }
    
    package let code: Self.Code
  }
}

public protocol RemoteStoreNetworkSession: Sendable {
  func json<T>(
    for request: URLRequest,
    from decoder: JSONDecoder
  ) async throws -> T where T : Decodable
}

final public actor RemoteStore<NetworkSession>: PersistentSessionPersistentStore where NetworkSession : RemoteStoreNetworkSession {
  private let session: NetworkSession
  
  public init(session: NetworkSession) {
    self.session = session
  }
}

extension RemoteStore {
  package struct Error : Swift.Error {
    package enum Code: Equatable {
      case urlError
      case requestError
    }
    
    package let code: Self.Code
  }
}

extension RemoteStore {
  private static func networkRequest(remoteRequest: RemoteRequest) throws -> URLRequest {
    guard
      let url = URL(string: "http://localhost:8080/animals/api")
    else {
      throw Error(code: .urlError)
    }
    var networkRequest = URLRequest(url: url)
    networkRequest.httpMethod = "POST"
    networkRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    networkRequest.httpBody = try {
      do {
        return try JSONEncoder().encode(remoteRequest)
      } catch {
        throw Error(code: .requestError)
      }
    }()
    return networkRequest
  }
}

extension RemoteStore {
  public func fetchCategoriesQuery() async throws -> Array<Category> {
    let remoteRequest = RemoteRequest(query: .categories)
    let networkRequest = try Self.networkRequest(remoteRequest: remoteRequest)
    let remoteResponse: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: JSONDecoder()
    )
    guard
      let query = remoteResponse.query,
      let categories = {
        let element = query.first { element in
          if case .categories = element {
            return true
          }
          return false
        }
        if case .categories(categories: let categories) = element {
          return categories
        }
        return nil
      }()
    else {
      throw RemoteResponse.Query.Error(code: .categoriesNotFound)
    }
    return categories
  }
}

extension RemoteStore {
  public func fetchAnimalsQuery() async throws -> Array<Animal> {
    let remoteRequest = RemoteRequest(query: .animals)
    let networkRequest = try Self.networkRequest(remoteRequest: remoteRequest)
    let remoteResponse: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: JSONDecoder()
    )
    guard
      let query = remoteResponse.query,
      let animals = {
        let element = query.first { element in
          if case .animals = element {
            return true
          }
          return false
        }
        if case .animals(animals: let animals) = element {
          return animals
        }
        return nil
      }()
    else {
      throw RemoteResponse.Query.Error(code: .animalsNotFound)
    }
    return animals
  }
}

extension RemoteStore {
  public func addAnimalMutation(
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal {
    let remoteRequest = RemoteRequest(
      mutation: .addAnimal(
        name: name,
        diet: diet,
        categoryId: categoryId
      )
    )
    let networkRequest = try Self.networkRequest(remoteRequest: remoteRequest)
    let remoteResponse: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: JSONDecoder()
    )
    guard
      let mutation = remoteResponse.mutation,
      let animal = {
        let element = mutation.first { element in
          if case .addAnimal = element {
            return true
          }
          return false
        }
        if case .addAnimal(animal: let animal) = element {
          return animal
        }
        return nil
      }()
    else {
      throw RemoteResponse.Mutation.Error(code: .animalNotFound)
    }
    return animal
  }
}

extension RemoteStore {
  public func updateAnimalMutation(
    animalId: String,
    name: String,
    diet: Animal.Diet,
    categoryId: String
  ) async throws -> Animal {
    let remoteRequest = RemoteRequest(
      mutation: .updateAnimal(
        animalId: animalId,
        name: name,
        diet: diet,
        categoryId: categoryId
      )
    )
    let networkRequest = try Self.networkRequest(remoteRequest: remoteRequest)
    let remoteResponse: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: JSONDecoder()
    )
    guard
      let mutation = remoteResponse.mutation,
      let animal = {
        let element = mutation.first { element in
          if case .updateAnimal = element {
            return true
          }
          return false
        }
        if case .updateAnimal(animal: let animal) = element {
          return animal
        }
        return nil
      }()
    else {
      throw RemoteResponse.Mutation.Error(code: .animalNotFound)
    }
    return animal
  }
}

extension RemoteStore {
  public func deleteAnimalMutation(animalId: String) async throws -> Animal {
    let remoteRequest = RemoteRequest(
      mutation: .deleteAnimal(animalId: animalId)
    )
    let networkRequest = try Self.networkRequest(remoteRequest: remoteRequest)
    let remoteResponse: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: JSONDecoder()
    )
    guard
      let mutation = remoteResponse.mutation,
      let animal = {
        let element = mutation.first { element in
          if case .deleteAnimal = element {
            return true
          }
          return false
        }
        if case .deleteAnimal(animal: let animal) = element {
          return animal
        }
        return nil
      }()
    else {
      throw RemoteResponse.Mutation.Error(code: .animalNotFound)
    }
    return animal
  }
}

extension RemoteStore {
  public func reloadSampleDataMutation() async throws -> (
    animals: Array<Animal>,
    categories: Array<Category>
  ) {
    let remoteRequest = RemoteRequest(
      mutation: .reloadSampleData
    )
    let networkRequest = try Self.networkRequest(remoteRequest: remoteRequest)
    let remoteResponse: RemoteResponse = try await self.session.json(
      for: networkRequest,
      from: JSONDecoder()
    )
    guard
      let mutation = remoteResponse.mutation,
      let (animals, categories) = {
        let element = mutation.first { element in
          if case .reloadSampleData = element {
            return true
          }
          return false
        }
        if case .reloadSampleData(animals: let animals, categories: let categories) = element {
          return (animals, categories)
        }
        return nil
      }()
    else {
      throw RemoteResponse.Mutation.Error(code: .sampleDataNotFound)
    }
    return (animals, categories)
  }
}
