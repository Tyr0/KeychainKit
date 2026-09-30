
extension Dictionary {

    func mapKeys<Transformed, Failure>(_ transform: (Key) throws(Failure) -> Transformed) throws(Failure) -> Dictionary<Transformed, Value> where Transformed: Hashable {
        let capacity = self.capacity

        var result = Dictionary<Transformed, Value>(minimumCapacity: capacity)

        for (key, value) in self {
            let transformedKey = try transform(key)
            result[transformedKey] = value
        }

        return result
    }
}
