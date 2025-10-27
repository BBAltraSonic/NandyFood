Feature: Restaurant Browsing
  As a user
  I want to browse and search for restaurants
  So that I can find food I want to order

  Background:
    Given the app is launched
    And I am on the home screen

  Scenario: View restaurant list
    Then I should see a list of restaurants
    And each restaurant should display name, image, rating, and delivery time

  Scenario: Search for restaurants
    When I tap the search bar
    And I enter "Pizza" into the search field
    Then I should see restaurants matching "Pizza"

  Scenario: Filter restaurants by category
    When I tap the "Italian" category chip
    Then I should see only Italian restaurants

  Scenario: View restaurant details
    When I tap on the first restaurant card
    Then I should see the restaurant detail screen
    And I should see restaurant information
    And I should see tabs for "Info", "Menu", and "Reviews"

  Scenario: Add restaurant to favorites
    When I tap on the first restaurant card
    And I tap the favorite icon
    Then the restaurant should be added to favorites
    And the favorite icon should be filled

  Scenario: View restaurant menu
    When I tap on the first restaurant card
    And I tap the "Menu" tab
    Then I should see menu items
    And each menu item should display name, price, and image

  Scenario: Read restaurant reviews
    When I tap on the first restaurant card
    And I tap the "Reviews" tab
    Then I should see customer reviews
    And each review should display rating, comment, and date

  Scenario: Scroll through restaurant list
    When I scroll down the restaurant list
    Then more restaurants should load
    And I should see a loading indicator

  Scenario: Pull to refresh restaurant list
    When I pull down on the restaurant list
    Then the list should refresh
    And I should see updated restaurants

  Scenario: Filter by dietary preferences
    When I tap the filter icon
    And I select "Vegetarian" filter
    And I tap "Apply"
    Then I should see only vegetarian restaurants

  Scenario: Sort restaurants
    When I tap the sort icon
    And I select "Rating (High to Low)"
    Then restaurants should be sorted by rating descending
