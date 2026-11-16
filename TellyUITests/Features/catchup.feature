Feature: Catch-up
  As a viewer
  I want to replay a programme that already aired on a catch-up channel
  So that I never miss a show

  Scenario: An aired programme on a catch-up channel offers the archive
    Given the demo playlist is installed
    When I open the Guide
    And I page the guide to the previous day
    And I open the details of the first programme on the row "Movie House"
    Then I should see the catch-up action
    When I start the catch-up playback
    Then I should see the archive player
