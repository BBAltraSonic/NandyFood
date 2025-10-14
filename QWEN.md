# Qwen Project Context - NandyFood Flutter Project

## Project Overview
- **Project Name**: NandyFood - Modern Food Delivery Application
- **Platform**: Flutter with Supabase backend
- **Architecture**: Clean architecture with feature-based organization
- **State Management**: Riverpod
- **Navigation**: GoRouter

## Key Files & References
- Main entry point: `lib/main.dart`
- Project analysis: `PROJECT_ANALYSIS_AND_COMPLETION_PLAN.md`
- Implementation plan: `IMPLEMENTATION_PLAN.md`
- Database schema: `supabase/migrations/` directory
- Environment config: `.env.example`

## Important Directories
- `lib/features/` - Feature-based organization
- `lib/core/` - Shared infrastructure
- `lib/shared/` - Cross-feature components
- `supabase/migrations/` - Database schema
- `test/` - Test files

## Project Status
- Current completion: ~60-70%
- Payment system: PayFast integration planned
- Key features implemented: Authentication, restaurant discovery, order management
- Key features pending: Real-time tracking, reviews, advanced analytics

## Special Instructions
- Use PayFast instead of Stripe for payment implementation
- Follow existing code patterns and architecture
- Maintain consistent theming and UI components
- Follow the implementation plan in phases