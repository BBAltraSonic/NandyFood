Feature: Profile Management
  As a user
  I want to manage my profile and settings
  So that I can customize my experience

  Background:
    Given the app is launched
    And I am logged in
    And I am on the profile screen

  Scenario: View profile information
    Then I should see my name
    And I should see my email
    And I should see my profile picture

  Scenario: Edit profile information
    When I tap the "Edit Profile" button
    And I change my name to "John Doe"
    And I tap "Save"
    Then my profile should be updated
    And I should see "Profile updated successfully"

  Scenario: Upload profile picture
    When I tap the profile picture
    And I select "Choose from gallery"
    And I select an image
    Then the profile picture should be updated

  Scenario: View order history
    When I tap "Order History"
    Then I should see my past orders
    And each order should show date, restaurant, and total

  Scenario: Reorder from history
    When I tap "Order History"
    And I tap "Reorder" on a past order
    Then the items should be added to cart

  Scenario: Manage delivery addresses
    When I tap "Addresses"
    Then I should see my saved addresses
    When I tap "Add New Address"
    And I fill in the address details
    And I save the address
    Then the address should appear in the list

  Scenario: Set default address
    When I tap "Addresses"
    And I tap the menu icon on an address
    And I tap "Set as Default"
    Then the address should be marked as default

  Scenario: Delete address
    When I tap "Addresses"
    And I tap the delete icon on an address
    And I confirm deletion
    Then the address should be removed

  Scenario: Manage payment methods
    When I tap "Payment Methods"
    Then I should see my saved payment methods
    When I tap "Add Payment Method"
    And I enter card details
    And I save the card
    Then the card should appear in the list

  Scenario: Remove payment method
    When I tap "Payment Methods"
    And I tap delete on a payment method
    And I confirm deletion
    Then the payment method should be removed

  Scenario: View favorites
    When I tap "Favorites"
    Then I should see my favorite restaurants
    And I should be able to remove favorites

  Scenario: Notification settings
    When I tap "Settings"
    And I tap "Notifications"
    Then I should see notification preferences
    When I toggle "Order Updates"
    Then the preference should be saved

  Scenario: Change password
    When I tap "Settings"
    And I tap "Change Password"
    And I enter current password
    And I enter new password
    And I confirm new password
    And I tap "Save"
    Then my password should be updated

  Scenario: Enable dark mode
    When I tap "Settings"
    And I toggle "Dark Mode"
    Then the app theme should change to dark

  Scenario: Logout
    When I tap "Settings"
    And I tap "Logout"
    And I confirm logout
    Then I should be logged out
    And I should see the login screen
