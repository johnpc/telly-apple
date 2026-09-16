import Testing
@testable import Telly

/// Unit coverage for XMLTV timestamp + episode-number parsing.
struct XmltvTimestampTests {

    @Test func parsesUtcTimestamp() {
        // 2026-09-13 12:30:00 UTC == 1_789_302_600_000 ms.
        #expect(XmltvTimestamp.parseMs("20260913123000 +0000") == 1_789_302_600_000)
    }

    @Test func subtractsPositiveOffsetToReachUtc() {
        let utc = XmltvTimestamp.parseMs("20260913123000 +0000")
        let plus2 = XmltvTimestamp.parseMs("20260913143000 +0200")
        #expect(plus2 == utc)
    }

    @Test func addsNegativeOffsetToReachUtc() {
        let utc = XmltvTimestamp.parseMs("20260913123000 +0000")
        let minus0530 = XmltvTimestamp.parseMs("20260913070000 -0530")
        #expect(minus0530 == utc)
    }

    @Test func treatsMissingOffsetAsUtc() {
        #expect(XmltvTimestamp.parseMs("20260913123000")
                == XmltvTimestamp.parseMs("20260913123000 +0000"))
    }

    @Test func rejectsGarbageAndPartialTimestamps() {
        #expect(XmltvTimestamp.parseMs(nil) == nil)
        #expect(XmltvTimestamp.parseMs("") == nil)
        #expect(XmltvTimestamp.parseMs("2026091312") == nil)
        #expect(XmltvTimestamp.parseMs("not-a-date") == nil)
    }

    @Test func episodeNumRendersXmltvNsOneBased() {
        #expect(XmltvEpisodeNum.display(system: "xmltv_ns", text: "0.9.") == "S1 E10")
        #expect(XmltvEpisodeNum.display(system: "xmltv_ns", text: "0 . 9/20 . ") == "S1 E10")
        #expect(XmltvEpisodeNum.display(system: "xmltv_ns", text: "..2") == nil)
        #expect(XmltvEpisodeNum.display(system: "xmltv_ns", text: "2..") == "S3")
    }

    @Test func episodeNumPassesThroughOtherSystemsAndRejectsEmpty() {
        #expect(XmltvEpisodeNum.display(system: "onscreen", text: "Ep 5") == "Ep 5")
        #expect(XmltvEpisodeNum.display(system: nil, text: "  ") == nil)
        #expect(XmltvEpisodeNum.display(system: nil, text: nil) == nil)
    }
}
