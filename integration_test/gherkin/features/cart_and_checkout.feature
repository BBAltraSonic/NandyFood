Feature: Cart and Checkout
  As a user
  I want to add items to cart and checkout
  So that I can place food orders

  Background:
    Given the app is launched
    And I am on the home screen
    And I navigate to a restaurant menu

  Scenario: Add item to cart
    When I tap on a menu item
    And I tap the "Add to Cart" button
    Then the item should be added to cart
    And the cart badge should show "1"

  Scenario: Increase item quantity in cart
    When I navigate to cart
    And I tap the "+" button on the first item
    Then the quantity should increase
    And the total price should update

  Scenario: Decrease item quantity in cart
    When I navigate to cart
    And I tap the "-" button on the first item
    Then the quantity should decrease
    And the total price should update

  Scenario: Remove item from cart
    When I navigate to cart
    And I tap the delete icon on the first item
    And I confirm deletion
    Then the item should be removed from cart

  Scenario: Apply promo code
    When I navigate to cart
    And I tap "Have a promo code?"
    And I enter "SAVE10" into the promo code field
    And I tap "Apply"
    Then the discount should be applied
    And the total should be reduced

  Scenario: Invalid promo code
    When I navigate to cart
    And I enter "INVALID" into the promo code field
    And I tap "Apply"
    Then I should see error "Invalid promo code"

  Scenario: Proceed to checkout
    When I navigate to cart
    And I tap the "Proceed to Checkout" button
    Then I should see the checkout screen

  Scenario: Select delivery address
    When I am on the checkout screen
    And I tap "Change Address"
    And I select an address
    Then the selected address should be displayed

  Scenario: Add new delivery address
    When I am on the checkout screen
    And I tap "Add New Address"
    And I fill in the address form
    And I save the address
    Then the new address should be available

  Scenario: Select payment method
    When I am on the checkout screen
    And I tap the payment method section
    And I select "Credit Card"
    Then "Credit Card" should be selected

  Scenario: Schedule delivery time
    When I am on the checkout screen
    And I tap the delivery time dropdown
    And I select "ASAP"
    Then "ASAP" should be displayed

  Scenario: Add special instructions
    When I am on the checkout screen
    And I enter "No onions" into special instructions
    Then the instructions should be saved

  Scenario: Place order successfully
    When I am on the checkout screen
    And all required fields are filled
    And I tap "Place Order"
    Then I should see the order confirmation screen
    And I should see the order number

  Scenario: Empty cart validation
    When I have an empty cart
    And I navigate to cart
    Then I should see "Your cart is empty" message
    And the checkout button should be disabled
