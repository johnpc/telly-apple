Feature: Search
  As a viewer
  I want to search channels and programmes
  So that I can jump straight to what I want

  Scenario: Typing a query lists matching channels
    Given the demo playlist is installed
    When I open Search
    And I search for "sports"
    Then the results should list the channel "Sports Arena"
    And the results should list the channel "Sports Arena HD"

  Scenario: A programme title from the EPG finds its channel
    Given the demo playlist is installed
    When I open Search
    And I search for "Morning Report"
    Then the results should list the programme "Morning Report"
    And the results should list the channel "News One"
