/// A byte count. Units are decimal, as carriers count them.
public typealias Bytes = Int64

extension Bytes {
    public static let megabyte: Bytes = 1_000_000
    public static let gigabyte: Bytes = 1_000_000_000
    public static let defaultTopUp: Bytes = 200 * megabyte

    /// Adds without trapping: a sum past the type's range stops at its end.
    func saturatingAdd(_ other: Bytes) -> Bytes {
        let (sum, overflow) = addingReportingOverflow(other)
        return overflow ? (other > 0 ? .max : .min) : sum
    }
}
