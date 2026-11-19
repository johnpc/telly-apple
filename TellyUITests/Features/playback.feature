Feature: Watch and zap
  As a viewer
  I want to open a channel and get back to the list
  So that watching live TV feels immediate

  Scenario: Tapping a channel opens the live player
    Given the demo playlist is installed
    When I open the channel "News One"
    Then I should see the live player

  Scenario: Closing the player returns to the channel list
    Given the demo playlist is installed
    When I open the channel "Sports Arena"
    And I close the player
    Then I should see the channel list

  @tvos
  Scenario: The info overlay comes back after it auto-hides
    Given the demo playlist is installed
    And I open the channel "News One"
    When I raise the info overlay
    Then the info overlay should hide by itself
    When I raise the info overlay
    Then the info overlay should hide by itself
    When I raise the info overlay
    Then I should see the live player
