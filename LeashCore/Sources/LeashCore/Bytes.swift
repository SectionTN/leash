/// A byte count. Units are decimal, as carriers count them.
public typealias Bytes = Int64

extension Bytes {
    public static let megabyte: Bytes = 1_000_000
    public static let gigabyte: Bytes = 1_000_000_000
    public static let defaultTopUp: Bytes = 200 * megabyte
}
