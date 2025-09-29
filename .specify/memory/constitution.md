Project Constitution: Food Delivery App

Preamble
This document establishes the guiding principles for the development of the Food Delivery App. Its purpose is to ensure the creation of a high-quality, reliable, and performant application that delivers an exceptional user experience. All technical decisions, code contributions, and architectural changes must align with these principles.

Article I: Code Quality & Maintainability
All code is an investment in the future of the project. It must be written with clarity, simplicity, and maintainability as primary goals.

Clarity and Readability: Code should be self-documenting. Prioritize clear variable names, logical function separation, and adherence to the official Effective Dart style guide.

Modular Architecture: The codebase will be organized by feature (/features/*). Each feature module must be as self-contained as possible to reduce coupling and improve scalability.

Single Responsibility Principle (SRP): Every class, function, or widget must have one, and only one, reason to change. Avoid creating monolithic "god objects" that manage disparate functionalities.

Conciseness and Simplicity (Kilo Code Principle): Strive to solve problems with the simplest possible solution. Avoid over-engineering and boilerplate. Functions and classes should be kept concise and focused, making them easier to review, test, and maintain.

Comprehensive Documentation:
Public APIs, complex business logic, and non-obvious code sections must have clear comments explaining the why, not just the what.
Each feature module should contain a README.md file explaining its purpose and usage.

Dependency Management: The introduction of any new third-party package requires a brief justification and approval from the technical lead to avoid code bloat and potential security vulnerabilities.

Article II: Testing & Reliability
A robust testing suite is non-negotiable and is the foundation of application reliability and user trust.

Testing Pyramid: We will adhere to the testing pyramid model:
Unit Tests: All business logic (services, repositories, state management logic) must have a unit test coverage of at least 80%.
Widget Tests: All UI components, especially those with user interaction or conditional rendering, must have corresponding widget tests.
Integration Tests: Critical user flows (e.g., authentication, adding to cart, checkout) must be validated with integration tests that verify interactions between the UI, services, and the Supabase backend.

Test-Driven Development (TDD): TDD is strongly encouraged for new features. Writing tests before implementation clarifies requirements and leads to a more robust design.

Continuous Integration (CI): Every pull request must pass all automated tests in the CI pipeline before it can be considered for merging. No exceptions.

Bug Reproduction: All bug fixes must include a new test that reproduces the bug, ensuring it does not regress in the future.

Article III: User Experience (UX) & Design Consistency
The user experience must be seamless, intuitive, and consistent across the entire application.

Single Source of Truth for Design: All UI development must adhere to a pre-defined design system. This includes consistent use of colors, typography, spacing, and component styles.

Predictable State Management: Every screen or widget that fetches data or performs an action must handle and clearly display all possible states:
Loading/Busy
Empty (no data)
Content/Success
Error (with a user-friendly message and a retry option)

Accessibility (A11y): The application must be accessible. This includes providing sufficient color contrast, supporting screen readers with semantic labels, and ensuring all interactive elements have adequate touch target sizes.

Platform Adaptability: While maintaining a consistent brand identity, the app should respect platform-specific UI/UX conventions to feel native on both iOS and Android.

Article IV: Performance & Efficiency
The application must feel fast, responsive, and respectful of the user's device resources.

60 FPS Standard: All animations and scrolling must maintain a consistent 60 frames per second (FPS). Performance profiling tools (like Flutter DevTools) must be used to identify and fix sources of jank.

Efficient Data Handling:
Never fetch more data than is necessary for the current view.
Implement pagination for all long lists of data.
Utilize local caching strategies to reduce redundant network calls.

Asset Optimization: All images and assets must be compressed and sized appropriately for their intended display. Utilize lazy loading for off-screen images.

App Startup Time: The time from app launch to an interactive home screen should not exceed 3 seconds on a mid-range device over a standard network connection.

Article V: Governance & Evolution
These principles will guide our work and will be upheld through a transparent governance process.

Mandatory Code Reviews: All pull requests must be reviewed and approved by at least one other developer before being merged into the main branch. Reviews should focus on adherence to this constitution.

Architectural Decision Records (ADRs): Significant changes to the app's architecture, core dependencies, or development patterns must be documented in an ADR. This provides a clear historical record of key decisions.

Principle of Consensus: Technical disputes should be resolved through discussion, with the goal of reaching a consensus that best aligns with the principles outlined in this document. The project's technical lead will have the final say if a consensus cannot be reached.

Amending the Constitution: This constitution is a living document. Amendments can be proposed via a pull request and must be ratified by a majority of the core development team after a period of discussion.