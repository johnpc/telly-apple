import Foundation

/// Splits an XMLTV `<category>` string into de-duplicated genre chips. Providers
/// pack several genres into one field with mixed delimiters (","/"/"/"|"), so the
/// info panel renders each as its own chip; blank fragments and case-insensitive
/// duplicates drop out. An absent / empty field yields no chips (the panel omits
/// the row entirely).
enum ProgramCategories {
    static func chips(from category: String?) -> [String] {
        guard let category else { return [] }
        var seen = Set<String>()
        return category.split(whereSeparator: { ",/|".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }
}
