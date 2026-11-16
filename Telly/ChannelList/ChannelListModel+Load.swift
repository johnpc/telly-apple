import Foundation

/// The channel list's load lifecycle is the shared ``LoadableModel`` one: cached
/// channels render immediately with a silent refresh; only an empty store shows
/// the skeleton and, should its refresh throw, the error+retry state.
extension ChannelListModel: LoadableModel {
    var hasContent: Bool { !channels.isEmpty }
}
