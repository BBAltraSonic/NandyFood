# Data Model: Modern Food Delivery App

## Entity: User Profile
- **id** (UUID, Primary Key): Unique identifier for the user
- **email** (String): User's email address
- **full_name** (String): User's full name
- **phone_number** (String, Optional): User's phone number
- **created_at** (DateTime): Timestamp when account was created
- **updated_at** (DateTime): Timestamp when account was last updated
- **preferences** (JSONB, Optional): User preferences including dietary restrictions
- **default_address** (JSONB, Optional): Default delivery address

## Entity: Restaurant
- **id** (UUID, Primary Key): Unique identifier for the restaurant
- **name** (String): Name of the restaurant
- **description** (Text, Optional): Description of the restaurant
- **cuisine_type** (String): Type of cuisine offered
- **address** (JSONB): Restaurant address with lat/long coordinates
- **phone_number** (String, Optional): Restaurant phone number
- **email** (String, Optional): Restaurant email
- **opening_hours** (JSONB): Operating hours for each day of the week
- **rating** (Float): Average rating from 0.0 to 5.0
- **delivery_radius** (Float): Delivery radius in kilometers
- **estimated_delivery_time** (Integer): Estimated delivery time in minutes
- **is_active** (Boolean): Whether the restaurant is accepting orders
- **created_at** (DateTime): Timestamp when restaurant was added
- **updated_at** (DateTime): Timestamp when restaurant was last updated

## Entity: Menu Item
- **id** (UUID, Primary Key): Unique identifier for the menu item
- **restaurant_id** (UUID, Foreign Key): Reference to the restaurant
- **name** (String): Name of the menu item
- **description** (Text, Optional): Description of the menu item
- **price** (Decimal): Price of the menu item
- **category** (String): Category of the menu item (e.g., appetizer, main course, dessert)
- **is_available** (Boolean): Whether the item is currently available
- **dietary_restrictions** (String[]): Array of dietary restrictions (vegetarian, vegan, gluten-free, etc.)
- **image_url** (String, Optional): URL to the menu item image
- **preparation_time** (Integer): Estimated preparation time in minutes
- **created_at** (DateTime): Timestamp when menu item was added
- **updated_at** (DateTime): Timestamp when menu item was last updated

## Entity: Order
- **id** (UUID, Primary Key): Unique identifier for the order
- **user_id** (UUID, Foreign Key): Reference to the user who placed the order
- **restaurant_id** (UUID, Foreign Key): Reference to the restaurant
- **delivery_address** (JSONB): Delivery address for the order
- **status** (String): Current status (placed, preparing, out_for_delivery, delivered, cancelled)
- **total_amount** (Decimal): Total amount for the order
- **delivery_fee** (Decimal): Delivery fee charged
- **tax_amount** (Decimal): Tax amount
- **tip_amount** (Decimal, Optional): Tip amount
- **payment_method** (String): Payment method used
- **payment_status** (String): Payment status (pending, completed, failed, refunded)
- **placed_at** (DateTime): Timestamp when order was placed
- **estimated_delivery_at** (DateTime, Optional): Estimated delivery time
- **delivered_at** (DateTime, Optional): Actual delivery time
- **notes** (Text, Optional): Special instructions from the user

## Entity: Order Item
- **id** (UUID, Primary Key): Unique identifier for the order item
- **order_id** (UUID, Foreign Key): Reference to the order
- **menu_item_id** (UUID, Foreign Key): Reference to the menu item
- **quantity** (Integer): Quantity ordered
- **unit_price** (Decimal): Price per unit at time of order
- **customizations** (JSONB, Optional): Customization details for the item
- **special_instructions** (Text, Optional): Special instructions for the kitchen

## Entity: Delivery
- **id** (UUID, Primary Key): Unique identifier for the delivery
- **order_id** (UUID, Foreign Key): Reference to the order being delivered
- **driver_id** (UUID, Optional): Reference to the delivery driver
- **estimated_arrival** (DateTime, Optional): Estimated arrival time
- **actual_arrival** (DateTime, Optional): Actual arrival time
- **current_location** (JSONB, Optional): Current location of the delivery
- **status** (String): Delivery status (assigned, picked_up, in_transit, delivered)
- **created_at** (DateTime): Timestamp when delivery was created
- **updated_at** (DateTime): Timestamp when delivery was last updated

## Entity: Promotion
- **id** (UUID, Primary Key): Unique identifier for the promotion
- **code** (String): Promotion code
- **description** (Text): Description of the promotion
- **discount_type** (String): Type of discount (percentage, fixed_amount)
- **discount_value** (Decimal): Value of the discount
- **minimum_order_amount** (Decimal, Optional): Minimum order amount to qualify
- **valid_from** (DateTime): Start date/time for the promotion
- **valid_until** (DateTime): End date/time for the promotion
- **usage_limit** (Integer, Optional): Maximum number of times the promotion can be used
- **used_count** (Integer): Number of times the promotion has been used
- **is_active** (Boolean): Whether the promotion is currently active

## Relationships
- User Profile → Order (1 to many)
- Restaurant → Menu Item (1 to many)
- Restaurant → Order (1 to many)
- Order → Order Item (1 to many)
- Order → Delivery (1 to 1)
- Menu Item → Order Item (1 to many)
- Promotion → Order (many to many through promotion_application)

## Validation Rules
- User email must be unique and valid
- Restaurant delivery radius must be between 1 and 20 km
- Menu item price must be positive
- Order status must follow the sequence: placed → preparing → out_for_delivery → delivered
- Delivery status must follow the sequence: assigned → picked_up → in_transit → delivered
- Order items must reference available menu items at the time of order

## State Transitions
- Order: placed → preparing → out_for_delivery → delivered OR cancelled
- Payment: pending → completed OR failed OR refunded
- Delivery: assigned → picked_up → in_transit → delivered