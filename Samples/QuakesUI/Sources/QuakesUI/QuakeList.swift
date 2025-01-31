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

import QuakesData
import SwiftUI

@MainActor fileprivate struct RowContent {
  private let quake: Quake
  
  init(quake: Quake) {
    self.quake = quake
  }
}

extension RowContent: View {
  var body: some View {
    HStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(.black)
        .frame(width: 60, height: 40)
        .overlay {
          Text(self.quake.magnitudeString)
            .font(.title)
            .bold()
            .foregroundStyle(self.quake.color)
        }
      
      VStack(alignment: .leading) {
        Text(self.quake.name)
          .font(.headline)
        Text("\(self.quake.time.formatted(.relative(presentation: .named)))")
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  ForEach(Quake.previewQuakes) { quake in
    RowContent(quake: quake)
      .padding()
  }
}

@MainActor fileprivate struct Footer {
  private let count: Int
  private let totalQuakes: Int
  @Binding private var searchDate: Date
  
  init(
    count: Int,
    totalQuakes: Int,
    searchDate: Binding<Date>
  ) {
    self.count = count
    self.totalQuakes = totalQuakes
    self._searchDate = searchDate
  }
}

extension Footer: View {
  var body: some View {
    HStack {
      VStack {
        Text("\(self.count) \(self.count == 1 ? "earthquake" : "earthquakes")")
        Text("\(self.totalQuakes) total")
          .foregroundStyle(.secondary)
      }
      .fixedSize()
      Spacer()
      DatePicker(
        "Search Date",
        selection: self.$searchDate,
        in: (.distantPast ... .distantFuture),
        displayedComponents: .date
      )
      .labelsHidden()
      .disabled(self.totalQuakes == .zero)
    }
  }
}

#Preview {
  @Previewable @State var searchDate: Date = .now
  Footer(
    count: 8,
    totalQuakes: 16,
    searchDate: $searchDate
  )
  .padding()
}

extension QuakeList {
  fileprivate enum SortOrder: String, CaseIterable, Identifiable, Hashable, Sendable {
    case forward, reverse
    var id: Self { self }
    var name: String { self.rawValue.capitalized }
  }
}

extension QuakeList {
  fileprivate enum SortParameter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case time, magnitude
    var id: Self { self }
    var name: String { self.rawValue.capitalized }
  }
}

extension SelectQuakesValues {
  fileprivate init(
    searchText: String,
    searchDate: Date,
    sortOrder: QuakeList.SortOrder,
    sortParameter: QuakeList.SortParameter
  ) {
    switch (sortParameter, sortOrder) {
    case (.time, .forward):
      self.init(searchText: searchText, searchDate: searchDate, sort: \Quake.time, order: .forward)
    case (.time, .reverse):
      self.init(searchText: searchText, searchDate: searchDate, sort: \Quake.time, order: .reverse)
    case (.magnitude, .forward):
      self.init(searchText: searchText, searchDate: searchDate, sort: \Quake.magnitude, order: .forward)
    case (.magnitude, .reverse):
      self.init(searchText: searchText, searchDate: searchDate, sort: \Quake.magnitude, order: .reverse)
    }
  }
}

@MainActor struct QuakeList {
  @Binding private var listSelection: Quake.ID?
  private let mapSelection: Quake.ID?
  @Binding private var searchText: String
  @Binding private var searchDate: Date
  @State private var sortOrder: QuakeList.SortOrder = .forward
  @State private var sortParameter: QuakeList.SortParameter = .time
  
  init(
    listSelection: Binding<Quake.ID?>,
    mapSelection: Quake.ID?,
    searchText: Binding<String>,
    searchDate: Binding<Date>
  ) {
    self._listSelection = listSelection
    self.mapSelection = mapSelection
    self._searchText = searchText
    self._searchDate = searchDate
  }
}

extension QuakeList : View {
  var body: some View {
    let _ = Self.debugPrint()
    Container(
      listSelection: self.$listSelection,
      mapSelection: self.mapSelection,
      searchText: self.$searchText,
      searchDate: self.$searchDate,
      sortOrder: self.$sortOrder,
      sortParameter: self.$sortParameter
    )
  }
}

extension QuakeList {
  @MainActor fileprivate struct Container {
    @SelectQuakesValues private var quakes: Array<Quake>
    @SelectQuakesCount private var totalQuakes: Int
    @SelectQuakesStatus private var status
    
    @Binding private var listSelection: Quake.ID?
    private let mapSelection: Quake.ID?
    @Binding private var searchText: String
    @Binding private var searchDate: Date
    @Binding private var sortOrder: SortOrder
    @Binding private var sortParameter: SortParameter
    
    @Dispatch private var dispatch
    
    init(
      listSelection: Binding<Quake.ID?>,
      mapSelection: Quake.ID?,
      searchText: Binding<String>,
      searchDate: Binding<Date>,
      sortOrder: Binding<SortOrder>,
      sortParameter: Binding<SortParameter>
    ) {
      self._quakes = SelectQuakesValues(
        searchText: searchText.wrappedValue,
        searchDate: searchDate.wrappedValue,
        sortOrder: sortOrder.wrappedValue,
        sortParameter: sortParameter.wrappedValue
      )
      self._listSelection = listSelection
      self.mapSelection = mapSelection
      self._searchText = searchText
      self._searchDate = searchDate
      self._sortOrder = sortOrder
      self._sortParameter = sortParameter
    }
  }
}

extension QuakeList.Container {
  private func onAppear() {
    do {
      try self.dispatch(.ui(.quakeList(.onAppear)))
    } catch {
      print(error)
    }
  }
}

extension QuakeList.Container {
  private func onTapRefreshQuakesButton(range: QuakesAction.UI.QuakeList.RefreshQuakesRange) {
    do {
      try self.dispatch(.ui(.quakeList(.onTapRefreshQuakesButton(range: range))))
    } catch {
      print(error)
    }
  }
}

extension QuakeList.Container {
  private func onTapDeleteSelectedQuakeButton(quakeId: Quake.ID) {
    do {
      try self.dispatch(.ui(.quakeList(.onTapDeleteSelectedQuakeButton(quakeId: quakeId))))
    } catch {
      print(error)
    }
  }
}

extension QuakeList.Container {
  private func onTapDeleteAllQuakesButton() {
    do {
      try self.dispatch(.ui(.quakeList(.onTapDeleteAllQuakesButton)))
    } catch {
      print(error)
    }
  }
}

extension QuakeList.Container: View {
  var body: some View {
    let _ = Self.debugPrint()
    QuakeList.Presenter(
      quakes: self.quakes,
      totalQuakes: self.totalQuakes,
      status: self.status,
      listSelection: self.$listSelection,
      mapSelection: self.mapSelection,
      searchText: self.$searchText,
      searchDate: self.$searchDate,
      sortOrder: self.$sortOrder,
      sortParameter: self.$sortParameter,
      onAppear: self.onAppear,
      onTapRefreshQuakesButton: self.onTapRefreshQuakesButton,
      onTapDeleteSelectedQuakeButton: self.onTapDeleteSelectedQuakeButton,
      onTapDeleteAllQuakesButton: self.onTapDeleteAllQuakesButton
    )
  }
}

extension QuakeList {
  @MainActor fileprivate struct Presenter {
    private let quakes: Array<Quake>
    private let totalQuakes: Int
    private let status: Status?
    @Binding private var listSelection: Quake.ID?
    private let mapSelection: Quake.ID?
    @Binding private var searchText: String
    @Binding private var searchDate: Date
    @Binding private var sortOrder: SortOrder
    @Binding private var sortParameter: SortParameter
    private let onAppear: () -> Void
    private let onTapRefreshQuakesButton: (QuakesAction.UI.QuakeList.RefreshQuakesRange) -> Void
    private let onTapDeleteSelectedQuakeButton: (Quake.ID) -> Void
    private let onTapDeleteAllQuakesButton: () -> Void
    
    init(
      quakes: Array<Quake>,
      totalQuakes: Int,
      status: Status?,
      listSelection: Binding<Quake.ID?>,
      mapSelection: Quake.ID?,
      searchText: Binding<String>,
      searchDate: Binding<Date>,
      sortOrder: Binding<SortOrder>,
      sortParameter: Binding<SortParameter>,
      onAppear: @escaping () -> Void,
      onTapRefreshQuakesButton: @escaping (QuakesAction.UI.QuakeList.RefreshQuakesRange) -> Void,
      onTapDeleteSelectedQuakeButton: @escaping (Quake.ID) -> Void,
      onTapDeleteAllQuakesButton: @escaping () -> Void
    ) {
      self.quakes = quakes
      self.totalQuakes = totalQuakes
      self.status = status
      self._listSelection = listSelection
      self.mapSelection = mapSelection
      self._searchText = searchText
      self._searchDate = searchDate
      self._sortOrder = sortOrder
      self._sortParameter = sortParameter
      self.onAppear = onAppear
      self.onTapRefreshQuakesButton = onTapRefreshQuakesButton
      self.onTapDeleteSelectedQuakeButton = onTapDeleteSelectedQuakeButton
      self.onTapDeleteAllQuakesButton = onTapDeleteAllQuakesButton
    }
  }
}

extension QuakeList.Presenter {
  private var refreshMenu: some View {
    Menu("Refresh", systemImage: "arrow.clockwise") {
      Button("All Hour") {
        self.onTapRefreshQuakesButton(.allHour)
      }
      Button("All Day") {
        self.onTapRefreshQuakesButton(.allDay)
      }
      Button("All Week") {
        self.onTapRefreshQuakesButton(.allWeek)
      }
      Button("All Month") {
        self.onTapRefreshQuakesButton(.allMonth)
      }
    }
    .pickerStyle(.inline)
  }
}

extension QuakeList.Presenter {
  private var deleteMenu: some View {
    Menu("Delete", systemImage: "trash") {
      Button("Delete Selected") {
        if let quakeId = self.listSelection {
          self.onTapDeleteSelectedQuakeButton(quakeId)
        }
      }
      .disabled(self.listSelection == nil)
      Button("Delete All") {
        self.onTapDeleteAllQuakesButton()
      }
    }
    .pickerStyle(.inline)
    .disabled(self.totalQuakes == .zero)
  }
}

extension QuakeList.Presenter {
  private var sortMenu: some View {
    Menu("Sort", systemImage: "arrow.up.arrow.down") {
      Picker("Sort Order", selection: self.$sortOrder) {
        ForEach(QuakeList.SortOrder.allCases) { order in
          Text(order.name)
        }
      }
      Picker("Sort By", selection: self.$sortParameter) {
        ForEach(QuakeList.SortParameter.allCases) { parameter in
          Text(parameter.name)
        }
      }
    }
    .pickerStyle(.inline)
    .disabled(self.quakes.isEmpty)
  }
}

extension QuakeList.Presenter {
  private var list: some View {
    ScrollViewReader { proxy in
      List(selection: self.$listSelection) {
        ForEach(self.quakes) { quake in
          RowContent(quake: quake)
        }
      }
      .safeAreaInset(edge: .bottom) {
        Footer(
          count: self.quakes.count,
          totalQuakes: self.totalQuakes,
          searchDate: self.$searchDate
        )
        .padding(.horizontal)
        .padding(.bottom, 4)
      }
      .onChange(of: self.mapSelection) {
        if self.listSelection != self.mapSelection {
          self.listSelection = self.mapSelection
          if let quakeId = self.mapSelection {
            withAnimation {
              proxy.scrollTo(quakeId, anchor: .center)
            }
          }
        }
      }
    }
  }
}

extension QuakeList.Presenter: View {
  var body: some View {
    let _ = Self.debugPrint()
    self.list
      .onAppear(perform: self.onAppear)
      .overlay {
        if self.totalQuakes == .zero {
          ContentUnavailableView("Refresh to load earthquakes", systemImage: "globe")
        } else if self.quakes.isEmpty {
          ContentUnavailableView.search
        }
      }
      .searchable(text: self.$searchText)
      .toolbar {
        self.refreshMenu
        self.deleteMenu
        self.sortMenu
      }
  }
}
#Preview {
  @Previewable @State var listSelection: Quake.ID?
  @Previewable @State var searchText: String = ""
  @Previewable @State var searchDate: Date = .now
  PreviewStore {
    QuakeList(
      listSelection: $listSelection,
      mapSelection: nil,
      searchText: $searchText,
      searchDate: $searchDate
    )
  }
}

#Preview {
  @Previewable @State var listSelection: Quake.ID?
  @Previewable @State var searchText: String = ""
  @Previewable @State var searchDate: Date = .now
  @Previewable @State var sortOrder: QuakeList.SortOrder = .forward
  @Previewable @State var sortParameter: QuakeList.SortParameter = .time
  QuakeList.Presenter(
    quakes: [],
    totalQuakes: 0,
    status: nil,
    listSelection: $listSelection,
    mapSelection: nil,
    searchText: $searchText,
    searchDate: $searchDate,
    sortOrder: $sortOrder,
    sortParameter: $sortParameter,
    onAppear: {
      print("onAppear")
    },
    onTapRefreshQuakesButton: { range in
      print("onTapRefreshQuakesButton: \(range)")
    },
    onTapDeleteSelectedQuakeButton: { quakeId in
      print("onTapDeleteSelectedQuakeButton: \(quakeId)")
    },
    onTapDeleteAllQuakesButton: {
      print("onTapDeleteAllQuakesButton")
    }
  )
}

#Preview {
  @Previewable @State var listSelection: Quake.ID?
  @Previewable @State var searchText: String = ""
  @Previewable @State var searchDate: Date = .now
  @Previewable @State var sortOrder: QuakeList.SortOrder = .forward
  @Previewable @State var sortParameter: QuakeList.SortParameter = .time
  QuakeList.Presenter(
    quakes: [],
    totalQuakes: 16,
    status: nil,
    listSelection: $listSelection,
    mapSelection: nil,
    searchText: $searchText,
    searchDate: $searchDate,
    sortOrder: $sortOrder,
    sortParameter: $sortParameter,
    onAppear: {
      print("onAppear")
    },
    onTapRefreshQuakesButton: { range in
      print("onTapRefreshQuakesButton: \(range)")
    },
    onTapDeleteSelectedQuakeButton: { quakeId in
      print("onTapDeleteSelectedQuakeButton: \(quakeId)")
    },
    onTapDeleteAllQuakesButton: {
      print("onTapDeleteAllQuakesButton")
    }
  )
}

#Preview {
  @Previewable @State var listSelection: Quake.ID?
  @Previewable @State var searchText: String = ""
  @Previewable @State var searchDate: Date = .now
  @Previewable @State var sortOrder: QuakeList.SortOrder = .forward
  @Previewable @State var sortParameter: QuakeList.SortParameter = .time
  QuakeList.Presenter(
    quakes: Quake.previewQuakes,
    totalQuakes: 16,
    status: nil,
    listSelection: $listSelection,
    mapSelection: nil,
    searchText: $searchText,
    searchDate: $searchDate,
    sortOrder: $sortOrder,
    sortParameter: $sortParameter,
    onAppear: {
      print("onAppear")
    },
    onTapRefreshQuakesButton: { range in
      print("onTapRefreshQuakesButton: \(range)")
    },
    onTapDeleteSelectedQuakeButton: { quakeId in
      print("onTapDeleteSelectedQuakeButton: \(quakeId)")
    },
    onTapDeleteAllQuakesButton: {
      print("onTapDeleteAllQuakesButton")
    }
  )
}
