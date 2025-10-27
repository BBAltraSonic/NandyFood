Feature: User Authentication
  As a user
  I want to authenticate into the app
  So that I can access personalized features

  Background:
    Given the app is launched
    And I am on the login screen

  Scenario: Successful login with valid credentials
    When I enter "test@example.com" into the email field
    And I enter "password123" into the password field
    And I tap the "Login" button
    Then I should see the home screen
    And I should be authenticated

  Scenario: Login fails with invalid credentials
    When I enter "invalid@example.com" into the email field
    And I enter "wrongpassword" into the password field
    And I tap the "Login" button
    Then I should see an error message "Invalid credentials"
    And I should remain on the login screen

  Scenario: Login form validation
    When I tap the "Login" button
    Then I should see validation error for email field
    And I should see validation error for password field

  Scenario: Navigate to signup screen
    When I tap the "Sign Up" link
    Then I should see the signup screen

  Scenario: Password visibility toggle
    When I enter "password123" into the password field
    And I tap the password visibility icon
    Then the password should be visible
    When I tap the password visibility icon
    Then the password should be hidden

  Scenario: Forgot password flow
    When I tap the "Forgot Password" link
    Then I should see the forgot password screen
    When I enter "test@example.com" into the email field
    And I tap the "Reset Password" button
    Then I should see a success message

  Scenario: Social authentication - Google
    When I tap the "Sign in with Google" button
    Then the Google sign-in flow should start

  Scenario: Social authentication - Apple
    When I tap the "Sign in with Apple" button
    Then the Apple sign-in flow should start
