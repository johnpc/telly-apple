Feature: Demo playlist
  As a reviewer or first-time user without an IPTV provider
  I want a built-in demo playlist
  So that I can explore the whole app without any server

  Scenario: Trying the demo playlist lands on the channel list
    Given the app is launched
    When I choose the demo playlist
    Then I should see the channel list
    And I should see the channel "News One"
