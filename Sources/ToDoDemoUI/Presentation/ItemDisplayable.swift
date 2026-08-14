//
//  ItemDisplayable.swift
//  ToDoDemoUI
//

public protocol ItemDisplayable: Identifiable, Sendable {
    var title: String { get }
    var isCompleted: Bool { get }
}
