# NandyFood User Flows Documentation

**Document Version**: 1.0
**Last Updated**: November 2025
**Platform**: NandyFood Flutter Application

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [User Roles & Capabilities](#user-roles--capabilities)
3. [Authentication & Onboarding Flows](#authentication--onboarding-flows)
4. [Customer User Flows](#customer-user-flows)
5. [Restaurant Owner User Flows](#restaurant-owner-user-flows)
6. [Delivery Driver User Flows](#delivery-driver-user-flows)
7. [Administrator User Flows](#administrator-user-flows)
8. [Cross-Role Integration Points](#cross-role-integration-points)
9. [Technical Architecture](#technical-architecture)
10. [Security & Compliance](#security--compliance)

---

## 🏢 Project Overview

**NandyFood** is a comprehensive food ordering platform built with Flutter and Supabase. It's a production-ready application focused on **restaurant preparation and customer pickup** rather than traditional delivery. The platform connects customers with local restaurants for efficient order preparation and pickup, supporting multiple user roles with real-time features and offline-first architecture.

### Key Technologies
- **Flutter**: 3.35.5 (Mobile app framework)
- **Dart**: 3.8.0 (Programming language)
- **Riverpod**: 2.6.1 (State management)
- **Supabase**: 2.10.3 (Backend services)
- **Firebase**: Push notifications and analytics
- **GoRouter**: Navigation routing

### Architecture Pattern
Clean Architecture with feature modules organized under `lib/features/` directory.

---

## 👥 User Roles & Capabilities

### 1. **Consumer (Default Role)**
- **Capabilities**: Browse restaurants, place orders, track orders, manage profile, save favorites, view order history, leave reviews
- **Navigation**: Home → Favourites → Order History → Profile
- **Authentication**: Email/password or social login (Google OAuth)

### 2. **Restaurant Owner**
- **Capabilities**: Dashboard access, order management, menu management, analytics, restaurant settings, operating hours, staff management
- **Guarded Routes**: `/restaurant/*` requires authentication + restaurant role
- **Registration**: Document verification required (business license, food handling permit)

### 3. **Restaurant Staff**
- **Capabilities**: Order processing, menu updates, customer communication, limited settings access
- **Guarded Routes**: Same as restaurant owner but with restricted permissions

### 4. **Delivery Driver**
- **Status**: Role removed from current business model
- **Previous Capabilities**: Order acceptance, delivery tracking, location sharing (deprecated)
- **Note**: System now focuses on restaurant preparation and customer pickup rather than delivery

### 5. **Administrator**
- **Capabilities**: Full system access, user management, platform analytics, moderation, system configuration
- **Guarded Routes**: `/admin/*` requires admin role
- **Security**: Multi-factor authentication, audit logging, system-wide access

---

## 🔐 Authentication & Onboarding Flows

### App Entry Point Flow

```
┌─────────────────┐
│   App Launch   │
└───────┬─────────┘
        ↓
┌─────────────────┐
│  SplashScreen   │
└───────┬─────────┘
        ↓
    ┌──┴──┐
    │     │
┌───▼───┐ ┌▼───────────┐
│First  │ │Existing    │
│Time   │ │User        │
│User   │ │            │
└───┬───┘ └───────────┘
    │           │
    ↓           ↓
┌───▼───┐     ┌──────────────┐
│Show   │     │Check Auth &  │
│Onboarding│  │Onboarding    │
│Flow   │     │Status        │
└───┬───┘     └──────────────┘
    │                 │
    ↓                 ↓
┌───▼─────────────────▼────┐
│      Navigate to Home     │
│      (as Guest)          │
└─────────────────────────┘
```

### Onboarding Process

**4 Interactive Pages:**
1. **Discover Great Food** - Restaurant discovery features
2. **Order with Ease** - Cart, customization, checkout features
3. **Track in Real-Time** - Delivery tracking features
4. **Location Access** - Permission request with explanation

### Authentication Methods

- **Email/Password**: Traditional authentication with validation
- **Google OAuth**: Social login integration
- **Guest Mode**: Limited browsing without authentication

### Role Selection & Assignment

```
┌─────────────────┐
│ Role Selection  │
│ Screen          │
└───────┬─────────┘
        ↓
┌─────────────────┐
│ Available Roles:│
│ • Consumer      │
│ • Restaurant    │
│   Owner         │
│ • Delivery      │
│   Driver        │
│ • Admin         │
└───────┬─────────┘
        ↓
┌─────────────────┐
│ Role Features   │
│ Display         │
└───────┬─────────┘
        ↓
┌─────────────────┐
│ User Selection  │
│ & Continue      │
└───────┬─────────┘
        ↓
┌─────────────────┐
│ Switch Primary  │
│ Role            │
└───────┬─────────┘
```

---

## 🛒 Customer User Flows

### 1. Home & Discovery Flow

**Entry Points:** App launch, deep links, notification taps

**Key Features:**
- **Dual Interface**: List view and map view toggle
- **Location-Based Discovery**: GPS/network fallback
- **Content Sections**: Search bar, promotional banner, order again, categories, popular restaurants
- **Smart Filtering**: Real-time category and search filtering

**User Journey:**
```
Home Screen → Location Detection → Restaurant Browse → Search/Filter → Restaurant Selection
```

### 2. Restaurant Browsing Flow

**Entry Points:** Home screen, search results, favorites, deep links

**Interface Elements:**
- **Hero Section**: Restaurant image with gradient overlay
- **Category Navigation**: Sticky header with smooth scrolling
- **Menu Items**: High-quality images with customization options
- **Social Proof**: Ratings, reviews, customer photos

**Decision Points:**
- Restaurant availability and operating hours
- Delivery range verification
- Menu item availability

### 3. Order Flow

**Phase 1 - Item Addition:**
- Menu item selection with customization
- Real-time cart updates
- Quantity management

**Phase 2 - Cart Review:**
- Item details and pricing
- Promo code application
- Delivery and service fees
- Tip options

**Phase 3 - Checkout Process:**
- Address selection and verification
- Payment method selection
- Special instructions
- Order confirmation

**Error Handling:**
- Minimum order validation
- Stock availability checks
- Payment processing failures

### 4. Payment Flow

**Payment Methods:**
- Saved credit/debit cards
- Digital wallets (Apple Pay, Google Pay)
- Cash on delivery (if available)
- Bank transfer for large orders

**Security Features:**
- Real-time card validation
- 3D Secure authentication
- Fraud detection
- Tokenization and encryption

### 5. Order Tracking Flow

**Real-time Features:**
- Live GPS tracking
- Driver information display
- ETA calculation with traffic updates
- Communication options (call, message)

**Status Progression:**
```
Order Placed → Confirmed → Preparing → Ready for Pickup → Completed (Customer Pickup)
```

**Key Differences from Delivery Model:**
- No driver assignment or tracking
- Customer picks up directly from restaurant
- Real-time preparation status updates
- Pickup notifications when order is ready
- Focus on preparation time accuracy

### 6. Order History Flow

**Features:**
- Comprehensive order listing
- Advanced filtering and sorting
- One-click reordering
- Order details and reviews

**Search Capabilities:**
- Restaurant search
- Order ID search
- Date-based search
- Item-based search

### 7. Favorites Flow

**Organization:**
- Restaurant favorites
- Menu item favorites
- Tab-based navigation
- Bulk management options

**Quick Actions:**
- Direct restaurant ordering
- One-click add to cart
- Remove with undo option

### 8. Profile Management Flow

**Sections:**
- **Personal Information**: Name, email, phone, profile photo
- **Address Management**: Saved addresses, default setting
- **Payment Methods**: Card management, security
- **Preferences**: Notifications, language, theme
- **Account Actions**: Password change, privacy settings

### 9. Location & Delivery Flow

**Location Services:**
- GPS permission handling
- Address validation
- Geocoding integration
- Delivery radius checking

**Delivery Options:**
- Standard/express delivery
- Scheduled delivery
- Special instructions
- Contact preferences

### 10. Support & Help Flow

**Support Channels:**
- FAQ section with categorization
- In-app chat support
- Email support tickets
- Phone support options

**Issue Reporting:**
- Order-related problems
- Technical issues
- General inquiries
- Feedback submission

---

## 🏪 Restaurant Owner User Flows

### 1. Restaurant Registration Flow

**6-Step Registration Process:**

**Step 1 - Basic Information:**
- Restaurant name, description, cuisine type
- Contact information
- Validation: Required fields, format checking

**Step 2 - Location Setup:**
- Address with geocoding
- GPS coordinates calculation
- Delivery area definition

**Step 3 - Service Configuration:**
- Delivery radius (1-20 km)
- Estimated delivery time (15-90 min)
- Dietary options selection

**Step 4 - Operating Hours:**
- Daily hour management
- Time picker interface
- Holiday mode options

**Step 5 - Document Verification:**
- Business license upload
- Food handling permit
- Restaurant photos
- Secure storage with 1-2 day verification

**Step 6 - Review & Submit:**
- Complete summary review
- Final validation
- Status: Pending verification

### 2. Dashboard Flow

**Main Components:**
- **Status Management**: Real-time order acceptance toggle
- **Key Metrics**: Today's orders, revenue, pending orders, active menu items
- **Pending Orders**: Top 3 orders with accept/reject actions
- **Quick Actions**: Orders, Menu, Analytics access
- **Recent Activity**: Last 5 orders with status

**Real-time Features:**
- Live order notifications (sound + vibration)
- Status change notifications
- Auto-refresh on data changes
- Unread message counts

### 3. Order Management Flow

**Order Status Workflow:**
```
New Order → Accept/Reject → Start Preparation → Ready for Pickup → Customer Pickup → Completed
```

**Preparation-Focused Features:**
- **Preparation Time Management**: Set accurate preparation time estimates
- **Real-time Status Updates**: Live preparation tracking for customers
- **Pickup Notifications**: Alert customers when orders are ready
- **Preparation Analytics**: Track preparation efficiency and accuracy
- **Customer Communication**: Pickup coordination and instructions

**Order Acceptance Process:**
- Real-time notifications
- Preparation time setting (10-60 min slider)
- Customer communication
- Order details display

**Communication Features:**
- Real-time chat with customers
- Voice/video calling
- Message history
- Typing indicators

### 4. Menu Management Flow

**Menu Item Operations:**
- Add new items with images
- Edit existing items
- Search and filter by category
- Quick availability toggles

**Features:**
- Category-based organization
- Image upload and caching
- Real-time availability updates
- Bulk operations (planned)

### 5. Restaurant Settings Flow

**Settings Categories:**
- **Restaurant Information**: Name, description, contact info
- **Operating Hours**: Daily schedule, special hours
- **Delivery Settings**: Radius, fees, minimum order
- **Staff Management**: Employee accounts and permissions (planned)

### 6. Staff Management Flow (Planned)

**Role-Based Permissions:**
- **Manager**: Full access
- **Chef**: View orders, update status
- **Cashier**: View and update orders
- **Server**: View orders only
- **Delivery Coordinator**: Order management + tracking

### 7. Analytics & Reports Flow

**Metrics Dashboard:**
- Total sales and orders
- Customer insights (new, returning, repeat rate)
- Sales visualization (charts and trends)
- Menu performance analytics
- Date range selection

**Data Sources:**
- Restaurant analytics table
- Historical order data
- Menu item performance tracking
- Custom database functions

### 8. Promotions & Marketing Flow (Planned)

**Promotion Types:**
- Percentage discounts
- Fixed amount discounts
- Buy X get Y offers
- Time-limited promotions
- Loyalty program discounts

**Campaign Management:**
- Create and schedule promotions
- Track campaign performance
- Customer segmentation
- ROI calculation

### 9. Customer Communication Flow

**Communication Channels:**
- Order-specific chat
- Voice/video calling
- Push notifications
- In-app notifications

**Workflow Integration:**
- Order status updates
- Proactive customer service
- Review management
- Broadcast messaging

### 10. Financial Management Flow (Planned)

**Financial Components:**
- Revenue tracking by period
- Payment method breakdown
- Tax calculations
- Payout management

**Reporting Features:**
- Sales summaries
- Expense tracking
- Profit/loss statements
- Tax documentation

---

## 🚚 Delivery Driver User Flows

### **STATUS: NOT IMPLEMENTED**

**Note:** Based on migration `022_remove_delivery_features_and_focus_on_preparation.sql`, the delivery driver functionality has been intentionally removed from the platform. NandyFood now focuses on restaurant preparation and customer pickup rather than delivery.

#### Previous Driver Functionality (Deprecated):
The platform previously included comprehensive delivery driver features including:
- Driver registration and onboarding
- Order acceptance and navigation
- GPS tracking and route optimization
- Earnings management and performance analytics
- Customer communication and delivery confirmation

#### Current Business Model:
- **Restaurant Preparation**: Focus on efficient food preparation
- **Customer Pickup**: Customers pick up orders from restaurants
- **Order Status Tracking**: Real-time preparation status updates
- **Pickup Notifications**: Alerts when orders are ready for collection

#### Future Considerations:
If delivery functionality needs to be reintroduced, it would require:
- Complete driver module development
- GPS integration and mapping services
- Driver screening and verification systems
- Delivery fleet management tools
- Insurance and compliance frameworks

---

---

## 👨‍💼 Administrator User Flows

### 1. Admin Authentication & Access Control Flow

**Security Features:**
- Multi-factor authentication (SMS/Email OTP, TOTP)
- Role verification through database queries
- JWT with admin claims
- Session management with timeout
- Comprehensive audit trail

**Access Control:**
- System-wide data access
- Role-based permissions
- Activity logging
- Security monitoring

### 2. Admin Dashboard Flow

**Platform Overview:**
- Active users, restaurants, orders
- Revenue metrics and system health
- Analytics menu (user, restaurant, order, financial)
- System management interfaces
- Alerts and notifications center

### 3. User Management Flow

**User Operations:**
- Search and filter by role/status
- Profile viewing with activity logs
- Role assignment and management
- User actions (suspend, reactivate, delete)
- Password reset and account recovery

**Audit Logging:**
- Role change tracking
- User action logging
- Notification system
- Admin approval requirements

### 4. Restaurant Management Flow

**Restaurant Operations:**
- Application directory (pending, active, suspended)
- Document verification and compliance checks
- Quality control and monitoring
- Restaurant actions (suspend, feature, update status)

**Verification Process:**
- Document review
- Site inspection coordination
- Approval/rejection workflow
- Notification system

### 5. Order Management Flow

**Order Monitoring:**
- Live order queue viewing
- Dispute resolution and mediation
- Failed order analysis
- System-wide order analytics

**Intervention Tools:**
- Order cancellation authority
- Refund processing
- Priority delivery assignment
- Customer service escalation

### 6. Financial Management Flow

**Financial Oversight:**
- Revenue tracking and trend analysis
- Payment processing monitoring
- Payout management for restaurants/drivers
- Tax compliance and reporting
- Financial analytics and forecasting

**Reporting Features:**
- Export capabilities (CSV/Excel)
- Automated report generation
- Tax document preparation
- Custom report builder

### 7. Content Management Flow

**Content Operations:**
- Platform content management
- Promotion creation and scheduling
- Announcement management
- Support article maintenance

**Approval Workflow:**
- Content review queue
- Publication scheduling
- A/B testing capabilities
- Performance analytics

### 8. Analytics & Reporting Flow

**Business Intelligence:**
- User growth and engagement metrics
- Restaurant performance analysis
- Order trend monitoring
- Revenue and financial analysis

**Advanced Analytics:**
- Customer segmentation
- Market analysis
- Competitor benchmarking
- Predictive modeling

### 9. System Configuration Flow

**Platform Settings:**
- Feature flags management
- Rate limiting configuration
- Integration management
- Security settings

**Environment Management:**
- Development/staging/production coordination
- Feature branch management
- Integration testing

### 10. Support & Issue Resolution Flow

**Support Management:**
- Customer support ticket system
- Technical issue tracking
- Incident management protocols
- Communication coordination

**Emergency Response:**
- System-wide alerts
- Escalation procedures
- Backup systems
- Recovery planning

---

## 🔗 Cross-Role Integration Points

### Real-time Communication
- **Order Updates**: All roles receive relevant notifications
- **Status Changes**: Live synchronization across user types
- **Chat System**: Cross-role messaging capabilities
- **Push Notifications**: Role-specific alert routing

### Data Flow Integration
- **Order Data**: Shared across customer, restaurant, driver, admin
- **User Profiles**: Centralized user management
- **Financial Data**: Integrated payment processing
- **Analytics Data**: Cross-role performance metrics

### Security Integration
- **Authentication**: Unified login system
- **Authorization**: Role-based access control
- **Audit Logging**: Comprehensive activity tracking
- **Data Privacy**: Secure data handling

### Service Integration
- **Location Services**: GPS for multiple use cases
- **Payment Processing**: Unified payment gateway
- **Notification System**: Multi-channel communication
- **File Storage**: Secure document management

---

## 🏗️ Technical Architecture

### Database Schema
- **PostgreSQL**: Primary database with Supabase
- **Row Level Security**: Role-based data access
- **Real-time Subscriptions**: Live data updates
- **Audit Logging**: Comprehensive change tracking

### Backend Services
- **Supabase Auth**: Authentication and user management
- **Supabase Functions**: Serverless backend logic
- **Firebase Cloud Messaging**: Push notifications
- **Real-time Database**: Live data synchronization

### Frontend Architecture
- **Flutter**: Cross-platform mobile app
- **Riverpod**: State management with code generation
- **GoRouter**: Navigation routing
- **Clean Architecture**: Feature-based organization

### Key Services (21 total)
1. **AuthService** - Authentication management
2. **RestaurantService** - Restaurant operations
3. **OrderService** - Order processing
4. **PaymentService** - Payment processing
5. **LocationService** - GPS and address management
6. **NotificationService** - Push notifications
7. **RealtimeService** - Real-time data updates
8. **AnalyticsService** - Performance analytics
9. **FileStorageService** - Document management
10. **EmailService** - Email communications
11. **SMSService** - SMS notifications
12. **ChatService** - In-app messaging
13. **GeocodingService** - Address validation
14. **RatingService** - Review management
15. **PromotionService** - Marketing campaigns
16. **ReportService** - Business reporting
17. **AuditService** - Activity logging
18. **CacheService** - Performance optimization
19. **ValidationService** - Data validation
20. **ExportService** - Data export
21. **IntegrationService** - Third-party connections

### State Management
- **Providers**: Role-based state management
- **Real-time Updates**: Live data synchronization
- **Offline Support**: Cached data capability
- **Performance Optimization**: Efficient state updates

---

## 🔒 Security & Compliance

### Security Features
- **Authentication**: JWT-based with refresh tokens
- **Authorization**: Role-based access control (RBAC)
- **Data Encryption**: Secure data transmission and storage
- **Audit Logging**: Comprehensive activity tracking
- **Rate Limiting**: API abuse prevention
- **Input Validation**: SQL injection and XSS prevention

### Compliance Measures
- **GDPR Compliance**: User data management and consent
- **Payment Compliance**: PCI DSS standards
- **Food Safety**: Restaurant compliance monitoring
- **Data Privacy**: Privacy by design principles
- **Accessibility**: WCAG compliance

### Privacy Controls
- **Data Minimization**: Collect only necessary data
- **User Consent**: Explicit consent management
- **Data Retention**: Automated data cleanup
- **Right to Deletion**: GDPR-compliant data removal
- **Data Portability**: User data export capabilities

### Emergency Security
- **Incident Response**: Security breach procedures
- **Backup Systems**: Data recovery capabilities
- **Monitoring**: Real-time security alerts
- **Penetration Testing**: Regular security assessments
- **Compliance Audits**: Third-party security validation

---

## 📊 Conclusion

This comprehensive user flows documentation covers the complete NandyFood ecosystem, detailing every user journey from initial registration through daily operations. The platform supports five distinct user roles with specialized workflows, all integrated through a unified technical architecture.

### Key Strengths
- **Comprehensive Coverage**: All user roles and interactions documented
- **Real-time Features**: Live tracking and notifications across all flows
- **Security Focus**: Multi-layered security and compliance measures
- **Scalability**: Clean architecture supporting growth
- **User Experience**: Detailed workflow optimization

### Future Enhancements
- **AI Integration**: Predictive analytics and recommendations
- **Advanced Analytics**: Business intelligence and reporting
- **Mobile Web**: Cross-platform accessibility
- **API Ecosystem**: Third-party integrations
- **International Expansion**: Multi-language and multi-currency support

This documentation serves as the foundation for ongoing development, user training, and system optimization of the NandyFood platform.

---

**Document prepared by**: Claude AI Assistant
**Last reviewed**: November 2025
**Next review date**: February 2026