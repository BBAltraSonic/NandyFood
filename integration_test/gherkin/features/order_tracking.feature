Feature: Order Tracking
  As a user
  I want to track my orders in real-time
  So that I know when my food will arrive

  Background:
    Given the app is launched
    And I have placed an order

  Scenario: View order tracking screen
    When I navigate to order tracking
    Then I should see the order status
    And I should see estimated delivery time
    And I should see a map with delivery location

  Scenario: Order status updates
    When the order status changes to "Preparing"
    Then I should see "Restaurant is preparing your order"
    When the order status changes to "Out for Delivery"
    Then I should see "Driver is on the way"

  Scenario: Live driver location tracking
    When the driver is assigned
    Then I should see the driver's location on map
    And the location should update in real-time

  Scenario: Contact driver
    When the driver is assigned
    And I tap the "Call Driver" button
    Then the phone dialer should open with driver's number

  Scenario: Contact restaurant
    When I am on order tracking screen
    And I tap the "Call Restaurant" button
    Then the phone dialer should open with restaurant's number

  Scenario: View order details
    When I am on order tracking screen
    And I tap "View Order Details"
    Then I should see all order items
    And I should see the total amount

  Scenario: Cancel order
    When the order status is "Pending"
    And I tap "Cancel Order"
    And I confirm cancellation
    Then the order should be cancelled
    And I should see cancellation confirmation

  Scenario: Order delivered notification
    When the order is marked as delivered
    Then I should receive a notification
    And I should see "Order Delivered" status

  Scenario: Rate order after delivery
    When the order is delivered
    Then I should see a prompt to rate the order
    When I tap "Rate Order"
    Then I should see the rating screen
