Feature: TV guide
  As a viewer
  I want a TiviMate-style programme grid
  So that I can see what is on across my channels

  Scenario: The guide renders the grid with demo EPG rows
    Given the demo playlist is installed
    When I open the Guide
    Then I should see the guide grid
    And the guide should list the channel "News One"
    And the guide should list the channel "Music Box"

  Scenario: Opening a programme shows its details
    Given the demo playlist is installed
    When I open the Guide
    And I open the details of the next programme on the first row
    Then I should see the programme details

  Scenario: Opening the Guide after watching a channel
    Given the demo playlist is installed
    And I open the channel "News One"
    And I should see the live player
    When I close the player
    And I open the Guide
    Then I should see the guide grid
    And the guide should list the channel "News One"
