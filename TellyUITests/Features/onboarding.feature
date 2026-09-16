Feature: App Launch
  As a first-time user
  I want a clear welcome screen
  So that I know how to start watching

  Scenario: Shows the welcome screen on first launch
    Given the app is launched
    Then I should see the welcome screen
    And I should see a prompt to add a playlist
