Feature: Settings
  As a viewer
  I want my preferences to stick
  So that the app behaves the same every time I open it

  Scenario: The settings sheet lists its sections
    Given the demo playlist is installed
    When I open Settings
    Then I should see the settings section "Playlists"
    And I should see the settings section "General"

  Scenario: A toggle persists across an app relaunch
    Given the demo playlist is installed
    When I open Settings
    And I turn on the "24-Hour Clock" toggle
    And I relaunch the app keeping its state
    And I open Settings
    Then the "24-Hour Clock" toggle should be on

  Scenario: Opening Settings after watching a channel
    Given the demo playlist is installed
    And I open the channel "News One"
    And I should see the live player
    When I close the player
    And I open Settings
    Then I should see the settings section "General"
