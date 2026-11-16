Feature: Movies (VOD)
  As a viewer
  I want film entries kept apart from live channels
  So that the Movies browser and the guide each show the right thing

  Scenario: VOD entries never become guide channels
    Given the demo playlist is installed
    Then the channel list should not list "Big Buck Bunny"

  Scenario: The Movies browser lists the demo films
    Given the demo playlist is installed
    When I open the Movies browser
    Then I should see the film "Big Buck Bunny"
    And I should see the film "Test Pattern (offline)"
