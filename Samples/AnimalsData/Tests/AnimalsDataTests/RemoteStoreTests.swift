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

import AnimalsData
import Collections
import Foundation
import Testing

extension URLRequest {
  fileprivate var contentType: String? {
    self.value(forHTTPHeaderField: "Content-Type")
  }
}

final fileprivate class Error : Swift.Error {
  
}

final fileprivate class RemoteStoreNetworkSessionTestDouble : @unchecked Sendable {
  var request: URLRequest?
  var decoder: JSONDecoder?
  var response: RemoteResponse?
  let error = Error()
}

extension RemoteStoreNetworkSessionTestDouble : RemoteStoreNetworkSession {
  func json<T>(
    for request: URLRequest,
    from decoder: JSONDecoder
  ) async throws -> T where T : Decodable {
    self.request = request
    self.decoder = decoder
    guard
      let response = self.response
    else {
      throw self.error
    }
    return response as! T
  }
}

@Suite final actor RemoteStoreTests {
  private static let state = AnimalsState(
    categories: AnimalsState.Categories(
      data: TreeDictionary(
        Category.amphibian,
        Category.bird,
        Category.fish,
        Category.invertebrate,
        Category.mammal,
        Category.reptile
      )
    ),
    animals: AnimalsState.Animals(
      data: TreeDictionary(
        Animal.dog,
        Animal.cat,
        Animal.kangaroo,
        Animal.gibbon,
        Animal.sparrow,
        Animal.newt
      )
    )
  )
}

extension RemoteStoreTests {
  @Test func fetchAnimalsQueryThrowsSessionError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.fetchAnimalsQuery()
    } throws: { error in
      let error = try #require(error as? Error)
      return error === session.error
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        query: [
          .animals,
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func fetchAnimalsQueryThrowsAnimalsNotFoundError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.fetchAnimalsQuery()
    } throws: { error in
      let error = try #require(error as? RemoteResponse.Query.Error)
      return error.code == .animalsNotFound
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        query: [
          .animals,
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func fetchAnimalsQueryNoThrow() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse(
      query: [
        .animals(
          animals: Array(
            Self.state.animals.data.values
          )
        )
      ]
    )
    
    let store = RemoteStore(session: session)
    let animals = try await store.fetchAnimalsQuery()
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        query: [
          .animals,
        ]
      )
    )
    
    #expect(animals == Array(Self.state.animals.data.values))
  }
}

extension RemoteStoreTests {
  @Test func addAnimalMutationThrowsSessionError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.addAnimalMutation(
        name: "name",
        diet: .herbivorous,
        categoryId: "categoryId"
      )
    } throws: { error in
      let error = try #require(error as? Error)
      return error === session.error
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .addAnimal(
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func addAnimalMutationThrowsAnimalNotFoundError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.addAnimalMutation(
        name: "name",
        diet: .herbivorous,
        categoryId: "categoryId"
      )
    } throws: { error in
      let error = try #require(error as? RemoteResponse.Mutation.Error)
      return error.code == .animalNotFound
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .addAnimal(
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func addAnimalMutationNoThrow() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse(
      mutation: [
        .addAnimal(
          animal: Animal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        )
      ]
    )
    
    let store = RemoteStore(session: session)
    let animal = try await store.addAnimalMutation(
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    )
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .addAnimal(
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
    
    #expect(animal == Animal(
      animalId: "animalId",
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    ))
  }
}

extension RemoteStoreTests {
  @Test func updateAnimalMutationThrowsSessionError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.updateAnimalMutation(
        animalId: "animalId",
        name: "name",
        diet: .herbivorous,
        categoryId: "categoryId"
      )
    } throws: { error in
      let error = try #require(error as? Error)
      return error === session.error
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .updateAnimal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func updateAnimalMutationThrowsAnimalNotFoundError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.updateAnimalMutation(
        animalId: "animalId",
        name: "name",
        diet: .herbivorous,
        categoryId: "categoryId"
      )
    } throws: { error in
      let error = try #require(error as? RemoteResponse.Mutation.Error)
      return error.code == .animalNotFound
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .updateAnimal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func updateAnimalMutationNoThrow() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse(
      mutation: [
        .updateAnimal(
          animal: Animal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        )
      ]
    )
    
    let store = RemoteStore(session: session)
    let animal = try await store.updateAnimalMutation(
      animalId: "animalId",
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    )
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .updateAnimal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        ]
      )
    )
    
    #expect(animal == Animal(
      animalId: "animalId",
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    ))
  }
}

extension RemoteStoreTests {
  @Test func deleteAnimalMutationThrowsSessionError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.deleteAnimalMutation(
        animalId: "animalId"
      )
    } throws: { error in
      let error = try #require(error as? Error)
      return error === session.error
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .deleteAnimal(
            animalId: "animalId"
          )
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func deleteAnimalMutationThrowsAnimalNotFoundError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.deleteAnimalMutation(
        animalId: "animalId"
      )
    } throws: { error in
      let error = try #require(error as? RemoteResponse.Mutation.Error)
      return error.code == .animalNotFound
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .deleteAnimal(
            animalId: "animalId"
          )
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func deleteAnimalMutationNoThrow() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse(
      mutation: [
        .deleteAnimal(
          animal: Animal(
            animalId: "animalId",
            name: "name",
            diet: .herbivorous,
            categoryId: "categoryId"
          )
        )
      ]
    )
    
    let store = RemoteStore(session: session)
    let animal = try await store.deleteAnimalMutation(
      animalId: "animalId"
    )
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .deleteAnimal(
            animalId: "animalId"
          )
        ]
      )
    )
    
    #expect(animal == Animal(
      animalId: "animalId",
      name: "name",
      diet: .herbivorous,
      categoryId: "categoryId"
    ))
  }
}

extension RemoteStoreTests {
  @Test func fetchCategoriesQueryThrowsSessionError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.fetchCategoriesQuery()
    } throws: { error in
      let error = try #require(error as? Error)
      return error === session.error
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        query: [
          .categories,
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func fetchCategoriesQueryThrowsCategoriesNotFoundError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.fetchCategoriesQuery()
    } throws: { error in
      let error = try #require(error as? RemoteResponse.Query.Error)
      return error.code == .categoriesNotFound
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        query: [
          .categories,
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func fetchCategoriesQueryNoThrow() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse(
      query: [
        .categories(
          categories: Array(
            Self.state.categories.data.values
          )
        )
      ]
    )
    
    let store = RemoteStore(session: session)
    let categories = try await store.fetchCategoriesQuery()
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        query: [
          .categories,
        ]
      )
    )
    
    #expect(categories == Array(Self.state.categories.data.values))
  }
}

extension RemoteStoreTests {
  @Test func reloadSampleDataMutationThrowsSessionError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.reloadSampleDataMutation()
    } throws: { error in
      let error = try #require(error as? Error)
      return error === session.error
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .reloadSampleData,
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func reloadSampleDataMutationThrowsSampleDataNotFoundError() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse()
    
    let store = RemoteStore(session: session)
    await #expect {
      try await store.reloadSampleDataMutation()
    } throws: { error in
      let error = try #require(error as? RemoteResponse.Mutation.Error)
      return error.code == .sampleDataNotFound
    }
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .reloadSampleData,
        ]
      )
    )
  }
}

extension RemoteStoreTests {
  @Test func reloadSampleDataMutationNoThrow() async throws {
    let session = RemoteStoreNetworkSessionTestDouble()
    session.response = RemoteResponse(
      mutation: [
        .reloadSampleData(
          animals: Array(
            Self.state.animals.data.values
          ),
          categories: Array(
            Self.state.categories.data.values
          )
        )
      ]
    )
    
    let store = RemoteStore(session: session)
    let (animals, categories) = try await store.reloadSampleDataMutation()
    
    let networkRequest = try #require(session.request)
    #expect(networkRequest.url == URL(string: "http://localhost:8080/animals/api"))
    #expect(networkRequest.httpMethod == "POST")
    #expect(networkRequest.contentType == "application/json")
    let httpBody = try #require(networkRequest.httpBody)
    let request = try JSONDecoder().decode(RemoteRequest.self, from: httpBody)
    #expect(
      request == RemoteRequest(
        mutation: [
          .reloadSampleData,
        ]
      )
    )
    
    #expect(animals == Array(Self.state.animals.data.values))
    #expect(categories == Array(Self.state.categories.data.values))
  }
}
