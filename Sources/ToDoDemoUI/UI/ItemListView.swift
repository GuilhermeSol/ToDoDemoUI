//
//  ItemListView.swift
//  ToDoDemoUI
//

import SwiftUI

public struct ItemListView<ViewModel: ItemListViewModeling>: View {
    @ObservedObject private var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Text(viewModel.emptyMessage)
    }
}

#if DEBUG
private struct PreviewItem {}

private struct PreviewItemProvider: ItemProviding {
    let items: [PreviewItem]
}

#Preview {
    ItemListView(viewModel: ItemListViewModel(provider: PreviewItemProvider(items: [])))
}
#endif
