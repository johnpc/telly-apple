import Testing
@testable import Telly

/// The pure panel selection transforms: initial playing-row focus (clamped) and
/// the clamped row moves + column toggle. Key-routing is deferred, so these are
/// exercised directly here.
struct PanelSelectionTests {
    @Test func initialFocusesPlayingRowClamped() {
        #expect(PanelSelection.initial(groups: 3, rows: 5, selectedRow: 9)
                == PanelSelection(groupIndex: 0, rowIndex: 4, inGroups: false))
    }

    @Test func initialClampsEmptyToZero() {
        #expect(PanelSelection.initial(groups: 0, rows: 0, selectedRow: 3)
                == PanelSelection(groupIndex: 0, rowIndex: 0, inGroups: false))
    }

    @Test func movedDownClampsToLastRow() {
        #expect(PanelSelection(groupIndex: 0, rowIndex: 3, inGroups: false)
                    .movedDown(rowCount: 4).rowIndex == 3)
        #expect(PanelSelection(groupIndex: 0, rowIndex: 1, inGroups: false)
                    .movedDown(rowCount: 4).rowIndex == 2)
    }

    @Test func movedUpClampsToFirstRow() {
        #expect(PanelSelection(groupIndex: 0, rowIndex: 0, inGroups: false).movedUp().rowIndex == 0)
        #expect(PanelSelection(groupIndex: 0, rowIndex: 2, inGroups: false).movedUp().rowIndex == 1)
    }

    @Test func focusGroupsAndRowsToggle() {
        let rows = PanelSelection(groupIndex: 0, rowIndex: 0, inGroups: false)
        #expect(rows.focusGroups().inGroups == true)
        #expect(rows.focusGroups().focusRows().inGroups == false)
    }
}
