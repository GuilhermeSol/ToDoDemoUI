//
//  ItemListViewModeling.swift
//  ToDoDemoUI
//

import Combine

public protocol ItemListViewModeling: ObservableObject {
    var emptyMessage: String { get }
}
