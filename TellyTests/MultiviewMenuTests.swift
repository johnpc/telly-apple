import Testing
@testable import Telly

/// The pure pane-menu row composition + picker titles: Change/Fullscreen always
/// offered, Remove only above one pane, Add only below capacity — Android's
/// pane-menu semantics, exercised without a view.
struct MultiviewMenuTests {
    @Test func singlePaneOffersChangeFullscreenAndAdd() {
        #expect(MultiviewMenu.rows(paneCount: 1, capacity: 4)
            == [.changeChannel, .fullscreen, .addPane])
    }

    @Test func midPaneOffersEveryRow() {
        #expect(MultiviewMenu.rows(paneCount: 2, capacity: 4)
            == [.changeChannel, .fullscreen, .removePane, .addPane])
    }

    @Test func fullGridDropsAdd() {
        #expect(MultiviewMenu.rows(paneCount: 4, capacity: 4)
            == [.changeChannel, .fullscreen, .removePane])
    }

    @Test func rowsExposeTitleAndSymbol() {
        #expect(MultiviewMenuRow.removePane.title == "Remove pane")
        #expect(!MultiviewMenuRow.addPane.symbol.isEmpty)
    }

    @Test func pickerModeTitles() {
        #expect(MultiviewPickerMode.change.title == "Change channel")
        #expect(MultiviewPickerMode.add.title == "Add pane")
    }
}
