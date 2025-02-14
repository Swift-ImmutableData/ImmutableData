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
import ImmutableData
import QuakesData
import SwiftData
import Testing

extension Quake {
  fileprivate func model() -> QuakeModel {
    QuakeModel(
      quakeId: self.quakeId,
      magnitude: self.magnitude,
      time: self.time,
      updatedTime: self.updated,
      name: self.name,
      longitude: self.longitude,
      latitude: self.latitude
    )
  }
}

extension QuakeModel {
  fileprivate func quake() -> Quake {
    Quake(
      quakeId: self.quakeId,
      magnitude: self.magnitude,
      time: self.time,
      updated: self.updatedTime,
      name: self.name,
      longitude: self.longitude,
      latitude: self.latitude
    )
  }
}

extension ModelContext {
  fileprivate func fetch<T>(_ type: T.Type) throws -> Array<T> where T : PersistentModel {
    try self.fetch(
      FetchDescriptor<T>()
    )
  }
}

extension ModelContext {
  fileprivate func fetch<T>(_ predicate: Predicate<T>) throws -> Array<T> where T : PersistentModel {
    try self.fetch(
      FetchDescriptor(predicate: predicate)
    )
  }
}

@Suite(.serialized) final actor LocalStoreTests {
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

extension LocalStoreTests {
  private static func makeStore() async throws -> LocalStore {
    let store = try LocalStore(isStoredInMemoryOnly: true)
    let modelActor = await store.modelActor
    for quake in Self.state.quakes.data.values {
      let model = quake.model()
      modelActor.modelExecutor.modelContext.insert(model)
    }
    try modelActor.modelExecutor.modelContext.save()
    return store
  }
}

extension LocalStoreTests {
  @Test func fetchLocalQuakesQuery() async throws {
    let store = try await Self.makeStore()
    let modelActor = await store.modelActor
    
    let quakes = try await store.fetchLocalQuakesQuery()
    
    #expect(TreeDictionary(quakes) == Self.state.quakes.data)
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test func didFetchRemoteQuakesMutation() async throws {
    let store = try await Self.makeStore()
    let modelActor = await store.modelActor
    
    try await store.didFetchRemoteQuakesMutation(
      inserted: [
        Quake(
          quakeId: "quakeId",
          magnitude: 1.0,
          time: Date(timeIntervalSince1970: 2.0),
          updated: Date(timeIntervalSince1970: 2.0),
          name: "name",
          longitude: -125,
          latitude: 35
        )
      ],
      updated: [
        Quake(
          quakeId: "1",
          magnitude: 1.0,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 2.0),
          name: "name",
          longitude: -125,
          latitude: 35
        )
      ],
      deleted: [
        Quake(
          quakeId: "2",
          magnitude: 0.0,
          time: Date(timeIntervalSince1970: 1.0),
          updated: Date(timeIntervalSince1970: 1.0),
          name: "West of California",
          longitude: -125,
          latitude: 35
        )
      ]
    )
    
    let array = try modelActor.modelExecutor.modelContext.fetch(QuakeModel.self)
    let quakes = array.map { model in model.quake() }
    #expect(TreeDictionary(quakes) == {
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
        time: Date(timeIntervalSince1970: 2.0),
        updated: Date(timeIntervalSince1970: 2.0),
        name: "name",
        longitude: -125,
        latitude: 35
      )
      return data
    }())
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test(arguments: Self.state.quakes.data.values) func deleteLocalQuakeMutation(quake: Quake) async throws {
    let store = try await Self.makeStore()
    let modelActor = await store.modelActor
    
    try await store.deleteLocalQuakeMutation(quakeId: quake.id)
    
    let array = try modelActor.modelExecutor.modelContext.fetch(QuakeModel.self)
    let quakes = array.map { model in model.quake() }
    #expect(TreeDictionary(quakes) == {
      var data = Self.state.quakes.data
      data[quake.id] = nil
      return data
    }())
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}

extension LocalStoreTests {
  @Test func deleteLocalQuakesMutation() async throws {
    let store = try await Self.makeStore()
    let modelActor = await store.modelActor
    
    try await store.deleteLocalQuakesMutation()
    
    #expect(try modelActor.modelExecutor.modelContext.fetch(QuakeModel.self) == [])
    
    #expect(modelActor.modelExecutor.modelContext.hasChanges == false)
  }
}
