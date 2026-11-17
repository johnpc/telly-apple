/// Which region of the guide screen owns remote focus on tvOS — the grid's cell
/// cursor, or one of the day-paging buttons in the chrome above it. One enum so
/// "where is focus" is a single value: the grid hands off upward on its top row
/// and the focus engine hands back downward.
enum GuideFocusArea: Hashable {
    case grid
    case previousDay
    case nextDay
}
