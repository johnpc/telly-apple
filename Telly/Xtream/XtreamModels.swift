import Foundation

/// Decodable DTOs for the Xtream `player_api.php` JSON. Only the fields the
/// import needs are modelled; unknown keys are ignored. The client decodes with
/// `.convertFromSnakeCase`, so `user_info`/`category_id`/… map to these camelCase
/// properties without hand-written `CodingKeys`. `user_info.auth`/`status` gate
/// the import — `auth != 1` or a non-`Active` status means auth was rejected.
struct XtreamHandshake: Decodable {
    let userInfo: UserInfo?

    struct UserInfo: Decodable {
        let auth: Int?
        let status: String?

        /// Authorised only when `auth == 1` and the account status is active.
        var authorized: Bool { (auth ?? 0) == 1 && (status ?? "").lowercased() == "active" }
    }
}

/// A live/VOD category (`get_live_categories` / `get_vod_categories`).
struct XtreamCategory: Decodable {
    let categoryId: String
    let categoryName: String
}
