Feature: My List
  As a viewer
  I want to save programmes I care about
  So that I can find them again later

  Scenario: My List starts empty
    Given the demo playlist is installed
    When I open My List
    Then I should see the empty message "No saved programmes"

  Scenario: Adding a future programme from the guide lists it in My List
    Given the demo playlist is installed
    When I open the Guide
    And I open the details of the next programme on the first row
    And I add the programme to My List
    And I go back to the channel list
    And I open My List
    Then My List should show a saved programme
