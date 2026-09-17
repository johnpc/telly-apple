/// A user-created named group and its membership (channel keys) — the Apple
/// mirror of the Android `CustomGroup`. Membership is stored by the
/// refresh-stable `ChannelImporter.keyOf`, so it survives playlist refreshes.
struct CustomGroup: Equatable, Identifiable {
    let id: Int
    let name: String
    var members: Set<String> = []
}
