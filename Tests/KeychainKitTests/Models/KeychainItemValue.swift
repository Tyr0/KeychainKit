
import KeychainKit

protocol KeychainItemValueProtocol: Sendable {

    associatedtype Item: KeychainItemProtocol

    var value: Item.Value { get }
}

struct KeychainItemValue<Item>: KeychainItemValueProtocol where Item: KeychainItemProtocol {

    let value: Item.Value

    init(_ item: Item.Type = Item.self, value: Item.Value) {
        self.value = value
    }
}
