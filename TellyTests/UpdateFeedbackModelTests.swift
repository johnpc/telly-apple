import Testing
@testable import Telly

/// The pure feedback state machine + outcome wording behind the Settings
/// "update" controls: idle → running → success/failure with a fake operation
/// (no network), dismiss back to idle, and the count/failure message rules.
@MainActor
struct UpdateFeedbackModelTests {
    @Test func startsIdle() {
        #expect(UpdateFeedbackModel().phase == .idle)
    }

    @Test func runsThenSucceeds() async {
        let model = UpdateFeedbackModel()
        await model.run {
            #expect(model.phase == .running)   // running before the work resolves
            return .success("Updated 3 channels")
        }
        #expect(model.phase == .success("Updated 3 channels"))
        #expect(model.isRunning == false)
    }

    @Test func runsThenFails() async {
        let model = UpdateFeedbackModel()
        await model.run { .failure("Couldn’t update playlists") }
        #expect(model.phase == .failure("Couldn’t update playlists"))
    }

    @Test func dismissReturnsToIdle() async {
        let model = UpdateFeedbackModel()
        await model.run { .success("Updated 1 channel") }
        model.dismiss()
        #expect(model.phase == .idle)
    }

    @Test func forAllReportsChannelCountOnSuccess() {
        #expect(UpdateOutcome.forAll(succeeded: 2, total: 2, channelCount: 5) == .success("Updated 5 channels"))
        #expect(UpdateOutcome.forAll(succeeded: 1, total: 2, channelCount: 1) == .success("Updated 1 channel"))
    }

    @Test func forAllFailsOnlyWhenNothingRefreshed() {
        #expect(UpdateOutcome.forAll(succeeded: 0, total: 2, channelCount: 0) == .failure("Couldn’t update playlists"))
        #expect(UpdateOutcome.forAll(succeeded: 0, total: 0, channelCount: 0) == .success("Updated 0 channels"))
    }

    @Test func forOneReflectsSuccessFlag() {
        #expect(UpdateOutcome.forOne(succeeded: true, channelCount: 4) == .success("Updated 4 channels"))
        #expect(UpdateOutcome.forOne(succeeded: false, channelCount: 0) == .failure("Couldn’t update playlist"))
    }

    @Test func doneChoosesWordingBySuccess() {
        #expect(UpdateOutcome.done(true, success: "Cleared", failure: "Nope") == .success("Cleared"))
        #expect(UpdateOutcome.done(false, success: "Cleared", failure: "Nope") == .failure("Nope"))
    }
}
