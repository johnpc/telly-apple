import Foundation
import Testing
@testable import Telly

/// Unit coverage for the streaming XMLTV parser and its element builders.
struct XmltvParserTests {

    private let document = """
    <?xml version="1.0" encoding="UTF-8"?>
    <tv>
      <channel id="bbc1">
        <display-name>BBC One</display-name>
        <icon src="http://logo/bbc1.png"/>
      </channel>
      <channel>
        <display-name>No ID, dropped</display-name>
      </channel>
      <programme channel="bbc1" start="20260913120000 +0000" stop="20260913130000 +0000">
        <title>The News</title>
        <sub-title>Lunchtime</sub-title>
        <desc><![CDATA[Headlines & weather]]></desc>
        <category>News</category>
        <episode-num system="xmltv_ns">0.4.</episode-num>
      </programme>
      <programme channel="bbc1" start="20260913130000 +0000" stop="20260913140000 +0000">
        <desc>No title, dropped</desc>
      </programme>
    </tv>
    """

    @Test func parsesChannelsAndProgramsTolerantly() {
        let doc = XmltvParser.parse(Data(document.utf8))
        #expect(doc.channels.count == 1)
        #expect(doc.channels[0] == XmltvChannel(id: "bbc1", displayName: "BBC One",
                                                iconUrl: "http://logo/bbc1.png"))
        #expect(doc.programs.count == 1)
        let program = doc.programs[0]
        #expect(program.channelId == "bbc1")
        #expect(program.startMs == XmltvTimestamp.parseMs("20260913120000 +0000"))
        #expect(program.endMs == XmltvTimestamp.parseMs("20260913130000 +0000"))
        #expect(program.details == ProgramDetails(title: "The News", subTitle: "Lunchtime",
                                                  description: "Headlines & weather",
                                                  category: "News", episode: "S1 E5"))
    }

    @Test func readerRequiresChannelId() {
        #expect(XmltvElementReader.channel(attributes: [:], children: ["display-name": "X"]) == nil)
        #expect(XmltvElementReader.channel(attributes: ["id": "  "], children: [:]) == nil)
        #expect(XmltvElementReader.channel(attributes: ["id": "c1"], children: [:])?.id == "c1")
    }

    @Test func readerRequiresChannelTitleAndTimes() {
        let good = ["channel": "c1", "start": "20260913120000 +0000", "stop": "20260913130000 +0000"]
        #expect(XmltvElementReader.program(attributes: good, children: [:]) == nil)
        #expect(XmltvElementReader.program(attributes: good, children: ["title": " "]) == nil)
        #expect(XmltvElementReader.program(attributes: ["channel": "c1"],
                                           children: ["title": "T"]) == nil)
        #expect(XmltvElementReader.program(attributes: good, children: ["title": "T"])?
            .details.title == "T")
    }
}
