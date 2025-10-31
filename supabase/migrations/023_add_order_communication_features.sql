-- =====================================================
-- NandyFood Database Schema
-- Migration: 023 - Order Communication Features
-- Description: Adds real-time chat and calling features within order context
-- =====================================================

-- Create order_conversations table
CREATE TABLE IF NOT EXISTS public.order_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,

    -- Conversation metadata
    title TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),

    -- Conversation settings
    is_muted BOOLEAN DEFAULT FALSE,
    auto_translate BOOLEAN DEFAULT TRUE,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create order_messages table
CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.order_conversations(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

    -- Message content
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice', 'file', 'call_ended', 'call_started', 'order_status')),

    -- Message status
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'failed')),

    -- Media attachments
    file_url TEXT,
    file_type TEXT,
    file_size INTEGER,
    file_name TEXT,

    -- Voice message specifics
    voice_duration INTEGER, -- in seconds
    voice_waveform JSONB, -- waveform data for voice messages

    -- Call specifics
    call_id UUID REFERENCES public.order_calls(id) ON DELETE SET NULL,
    call_duration INTEGER, -- in seconds
    call_type TEXT, -- 'voice', 'video'

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    read_at TIMESTAMPTZ,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Constraints
    CONSTRAINT valid_message_content CHECK (
        (message_type = 'text' AND content IS NOT NULL) OR
        (message_type IN ('image', 'file') AND file_url IS NOT NULL) OR
        (message_type = 'voice' AND file_url IS NOT NULL) OR
        (message_type IN ('call_started', 'call_ended', 'order_status'))
    )
);

-- Create order_calls table
CREATE TABLE IF NOT EXISTS public.order_calls (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.order_conversations(id) ON DELETE CASCADE NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,

    -- Call participants
    initiator_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    receiver_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,

    -- Call details
    call_type TEXT NOT NULL CHECK (call_type IN ('voice', 'video')),
    status TEXT DEFAULT 'initiated' CHECK (status IN ('initiated', 'ringing', 'connected', 'ended', 'missed', 'failed')),
    duration INTEGER DEFAULT 0, -- in seconds

    -- Call quality metrics
    connection_quality TEXT, -- 'excellent', 'good', 'fair', 'poor'
    signal_strength INTEGER CHECK (signal_strength BETWEEN 0 AND 5),

    -- Technical details
    rtc_session_id TEXT, -- WebRTC session identifier
    signaling_server TEXT,

    -- Timestamps
    initiated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    connected_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,

    -- End reason
    end_reason TEXT, -- 'user_hung_up', 'connection_lost', 'call_rejected'

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create order_communication_settings table
CREATE TABLE IF NOT EXISTS public.order_communication_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,

    -- Notification preferences
    message_notifications BOOLEAN DEFAULT TRUE,
    call_notifications BOOLEAN DEFAULT TRUE,
    status_notifications BOOLEAN DEFAULT TRUE,

    -- Communication preferences
    auto_translate BOOLEAN DEFAULT TRUE,
    show_typing_indicators BOOLEAN DEFAULT TRUE,

    -- Privacy settings
    allow_voice_calls BOOLEAN DEFAULT TRUE,
    allow_video_calls BOOLEAN DEFAULT FALSE,
    allow_screen_sharing BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Constraints
    CONSTRAINT unique_order_user_settings UNIQUE (order_id, user_id)
);

-- Add communication fields to user_profiles
ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS online_status TEXT DEFAULT 'offline' CHECK (online_status IN ('online', 'offline', 'away', 'busy')),
    ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS communication_preferences JSONB DEFAULT '{"notifications": true, "calls": true}'::jsonb;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_order_conversations_order_id ON public.order_conversations(order_id);
CREATE INDEX IF NOT EXISTS idx_order_conversations_restaurant_id ON public.order_conversations(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_order_conversations_customer_id ON public.order_conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_conversations_status ON public.order_conversations(status);
CREATE INDEX IF NOT EXISTS idx_order_conversations_last_activity ON public.order_conversations(last_activity_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_messages_conversation_id ON public.order_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_order_id ON public.order_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_sender_id ON public.order_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_created_at ON public.order_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_messages_status ON public.order_messages(status);
CREATE INDEX IF NOT EXISTS idx_order_messages_type ON public.order_messages(message_type);

CREATE INDEX IF NOT EXISTS idx_order_calls_conversation_id ON public.order_calls(conversation_id);
CREATE INDEX IF NOT EXISTS idx_order_calls_order_id ON public.order_calls(order_id);
CREATE INDEX IF NOT EXISTS idx_order_calls_initiator_id ON public.order_calls(initiator_id);
CREATE INDEX IF NOT EXISTS idx_order_calls_receiver_id ON public.order_calls(receiver_id);
CREATE INDEX IF NOT EXISTS idx_order_calls_status ON public.order_calls(status);
CREATE INDEX IF NOT EXISTS idx_order_calls_initiated_at ON public.order_calls(initiated_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_communication_settings_order_id ON public.order_communication_settings(order_id);
CREATE INDEX IF NOT EXISTS idx_order_communication_settings_user_id ON public.order_communication_settings(user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_online_status ON public.user_profiles(online_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_active ON public.user_profiles(last_active_at DESC);

-- Create triggers for updated_at timestamps
DROP TRIGGER IF EXISTS update_order_conversations_updated_at ON public.order_conversations;
CREATE TRIGGER update_order_conversations_updated_at
    BEFORE UPDATE ON public.order_conversations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_order_messages_updated_at ON public.order_messages;
CREATE TRIGGER update_order_messages_updated_at
    BEFORE UPDATE ON public.order_messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_order_calls_updated_at ON public.order_calls;
CREATE TRIGGER update_order_calls_updated_at
    BEFORE UPDATE ON public.order_calls
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_order_communication_settings_updated_at ON public.order_communication_settings;
CREATE TRIGGER update_order_communication_settings_updated_at
    BEFORE UPDATE ON public.order_communication_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Function to automatically create conversation when order is confirmed
CREATE OR REPLACE FUNCTION public.create_order_conversation()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create conversation for confirmed orders
    IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
        INSERT INTO public.order_conversations (
            order_id,
            restaurant_id,
            customer_id,
            title,
            status
        ) VALUES (
            NEW.id,
            NEW.restaurant_id,
            NEW.user_id,
            'Order #' || LEFT(NEW.id::text, 8),
            'active'
        );

        -- Insert system message about order confirmation
        INSERT INTO public.order_messages (
            conversation_id,
            order_id,
            sender_id,
            content,
            message_type,
            status,
            created_at
        ) VALUES (
            (SELECT id FROM public.order_conversations WHERE order_id = NEW.id ORDER BY created_at DESC LIMIT 1),
            NEW.id,
            NULL, -- System message, no sender
            'Order confirmed! You can now chat with the restaurant about your order.',
            'order_status',
            'delivered',
            NOW()
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic conversation creation
DROP TRIGGER IF EXISTS create_order_conversation_trigger ON public.orders;
CREATE TRIGGER create_order_conversation_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.create_order_conversation();

-- Function to send order status messages to chat
CREATE OR REPLACE FUNCTION public.send_order_status_message()
RETURNS TRIGGER AS $$
DECLARE
    conversation_uuid UUID;
BEGIN
    -- Find conversation for this order
    SELECT id INTO conversation_uuid
    FROM public.order_conversations
    WHERE order_id = NEW.id
    LIMIT 1;

    -- If conversation exists, send status update
    IF conversation_uuid IS NOT NULL THEN
        INSERT INTO public.order_messages (
            conversation_id,
            order_id,
            sender_id,
            content,
            message_type,
            status,
            created_at
        ) VALUES (
            conversation_uuid,
            NEW.id,
            NULL, -- System message
            CASE NEW.status
                WHEN 'preparing' THEN 'Your order is now being prepared!'
                WHEN 'ready_for_pickup' THEN 'Your order is ready for pickup! 🎉'
                WHEN 'cancelled' THEN 'Order has been cancelled.'
                ELSE 'Order status updated to: ' || NEW.status
            END,
            'order_status',
            'delivered',
            NOW()
        );

        -- Update conversation last activity
        UPDATE public.order_conversations
        SET last_activity_at = NOW(),
            updated_at = NOW()
        WHERE id = conversation_uuid;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for order status messages
DROP TRIGGER IF EXISTS send_order_status_message_trigger ON public.orders;
CREATE TRIGGER send_order_status_message_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('preparing', 'ready_for_pickup', 'cancelled'))
    EXECUTE FUNCTION public.send_order_status_message();

-- Function to get conversation statistics
CREATE OR REPLACE FUNCTION public.get_conversation_stats(order_id_param UUID)
RETURNS TABLE (
    message_count BIGINT,
    last_message_at TIMESTAMPTZ,
    unread_count BIGINT,
    total_call_duration INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(m.id) as message_count,
        MAX(m.created_at) as last_message_at,
        COUNT(CASE WHEN m.status != 'read' AND m.sender_id != order_id_param THEN 1 END) as unread_count,
        COALESCE(SUM(c.duration), 0) as total_call_duration
    FROM public.order_conversations oc
    LEFT JOIN public.order_messages m ON oc.id = m.conversation_id
    LEFT JOIN public.order_calls c ON oc.id = c.conversation_id
    WHERE oc.order_id = order_id_param
    GROUP BY oc.id;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old conversations (cleanup job)
CREATE OR REPLACE FUNCTION public.cleanup_old_communications(days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    cleanup_count INTEGER;
BEGIN
    -- Archive conversations for orders completed more than X days ago
    UPDATE public.order_conversations
    SET status = 'archived',
        updated_at = NOW()
    WHERE id IN (
        SELECT oc.id
        FROM public.order_conversations oc
        JOIN public.orders o ON oc.order_id = o.id
        WHERE o.status IN ('ready_for_pickup', 'cancelled')
        AND o.updated_at < NOW() - INTERVAL '1 day' * days_to_keep
        AND oc.status = 'active'
    );

    GET DIAGNOSTICS cleanup_count = ROW_COUNT;

    RETURN cleanup_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get user's active conversations
CREATE OR REPLACE FUNCTION public.get_user_active_conversations(user_id_param UUID)
RETURNS TABLE (
    conversation_id UUID,
    order_id UUID,
    restaurant_name TEXT,
    customer_name TEXT,
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    unread_count BIGINT,
    order_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        oc.id as conversation_id,
        oc.order_id,
        r.name as restaurant_name,
        up.full_name as customer_name,
        m.content as last_message,
        oc.last_message_at,
        COUNT(CASE WHEN m.status != 'read' AND m.sender_id != user_id_param THEN 1 END) as unread_count,
        o.status as order_status
    FROM public.order_conversations oc
    JOIN public.orders o ON oc.order_id = o.id
    JOIN public.restaurants r ON oc.restaurant_id = r.id
    JOIN public.user_profiles up ON oc.customer_id = up.id
    LEFT JOIN public.order_messages m ON oc.id = m.conversation_id
        AND m.id = (
            SELECT id FROM public.order_messages
            WHERE conversation_id = oc.id
            ORDER BY created_at DESC
            LIMIT 1
        )
    WHERE (oc.customer_id = user_id_param OR oc.restaurant_id IN (
        SELECT restaurant_id FROM public.user_profiles WHERE id = user_id_param
    ))
    AND oc.status = 'active'
    AND o.status NOT IN ('cancelled')
    GROUP BY oc.id, o.id, r.name, up.full_name, m.content, oc.last_message_at, o.status
    ORDER BY oc.last_activity_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Create view for active order communications
CREATE OR REPLACE VIEW public.active_order_communications AS
SELECT
    oc.*,
    o.status as order_status,
    o.total_amount,
    o.placed_at as order_placed_at,
    r.name as restaurant_name,
    up.full_name as customer_name,
    CASE
        WHEN oc.last_message_at > NOW() - INTERVAL '5 minutes' THEN 'active'
        WHEN oc.last_message_at > NOW() - INTERVAL '1 hour' THEN 'recent'
        ELSE 'inactive'
    END as activity_status,
    (
        SELECT COUNT(*)
        FROM public.order_messages m
        WHERE m.conversation_id = oc.id
        AND m.status != 'read'
    ) as unread_count
FROM public.order_conversations oc
JOIN public.orders o ON oc.order_id = o.id
JOIN public.restaurants r ON oc.restaurant_id = r.id
JOIN public.user_profiles up ON oc.customer_id = up.id
WHERE oc.status = 'active'
AND o.status NOT IN ('cancelled');

-- Add RLS policies for order conversations
ALTER TABLE public.order_conversations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view conversations for their orders or their restaurant's orders
CREATE POLICY "Users can view relevant order conversations" ON public.order_conversations
    FOR SELECT USING (
        customer_id = auth.uid() OR
        restaurant_id IN (
            SELECT id FROM public.restaurants
            WHERE id IN (
                SELECT restaurant_id FROM public.user_profiles
                WHERE id = auth.uid() AND role = 'restaurant_owner'
            )
            OR id IN (
                SELECT restaurant_id FROM public.user_roles
                WHERE user_id = auth.uid() AND role = 'restaurant_staff'
            )
        )
    );

-- Policy: Users can insert conversations for their orders
CREATE POLICY "Users can create order conversations" ON public.order_conversations
    FOR INSERT WITH CHECK (
        customer_id = auth.uid() OR
        restaurant_id IN (
            SELECT id FROM public.restaurants
            WHERE id IN (
                SELECT restaurant_id FROM public.user_profiles
                WHERE id = auth.uid() AND role = 'restaurant_owner'
            )
            OR id IN (
                SELECT restaurant_id FROM public.user_roles
                WHERE user_id = auth.uid() AND role = 'restaurant_staff'
            )
        )
    );

-- Policy: Users can update conversations they participate in
CREATE POLICY "Users can update relevant order conversations" ON public.order_conversations
    FOR UPDATE USING (
        customer_id = auth.uid() OR
        restaurant_id IN (
            SELECT id FROM public.restaurants
            WHERE id IN (
                SELECT restaurant_id FROM public.user_profiles
                WHERE id = auth.uid() AND role = 'restaurant_owner'
            )
            OR id IN (
                SELECT restaurant_id FROM public.user_roles
                WHERE user_id = auth.uid() AND role = 'restaurant_staff'
            )
        )
    );

-- Add RLS policies for order messages
ALTER TABLE public.order_messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view messages in conversations they participate in
CREATE POLICY "Users can view messages in their conversations" ON public.order_messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM public.order_conversations
            WHERE customer_id = auth.uid() OR
            restaurant_id IN (
                SELECT id FROM public.restaurants
                WHERE id IN (
                    SELECT restaurant_id FROM public.user_profiles
                    WHERE id = auth.uid() AND role = 'restaurant_owner'
                )
                OR id IN (
                    SELECT restaurant_id FROM public.user_roles
                    WHERE user_id = auth.uid() AND role = 'restaurant_staff'
                )
            )
        )
    );

-- Policy: Users can insert messages in conversations they participate in
CREATE POLICY "Users can send messages in their conversations" ON public.order_messages
    FOR INSERT WITH CHECK (
        conversation_id IN (
            SELECT id FROM public.order_conversations
            WHERE customer_id = auth.uid() OR
            restaurant_id IN (
                SELECT id FROM public.restaurants
                WHERE id IN (
                    SELECT restaurant_id FROM public.user_profiles
                    WHERE id = auth.uid() AND role = 'restaurant_owner'
                )
                OR id IN (
                    SELECT restaurant_id FROM public.user_roles
                    WHERE user_id = auth.uid() AND role = 'restaurant_staff'
                )
            )
        ) AND
        (sender_id = auth.uid() OR sender_id IS NULL) -- Allow system messages (NULL sender)
    );

-- Policy: Users can update message status for messages sent to them
CREATE POLICY "Users can update message status" ON public.order_messages
    FOR UPDATE USING (
        conversation_id IN (
            SELECT id FROM public.order_conversations
            WHERE customer_id = auth.uid() OR
            restaurant_id IN (
                SELECT id FROM public.restaurants
                WHERE id IN (
                    SELECT restaurant_id FROM public.user_profiles
                    WHERE id = auth.uid() AND role = 'restaurant_owner'
                )
                OR id IN (
                    SELECT restaurant_id FROM public.user_roles
                    WHERE user_id = auth.uid() AND role = 'restaurant_staff'
                )
            )
        ) AND
        (sender_id != auth.uid() OR sender_id IS NULL) -- Can update status of messages not sent by them
    );

-- Add RLS policies for order calls
ALTER TABLE public.order_calls ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view calls in conversations they participate in
CREATE POLICY "Users can view calls in their conversations" ON public.order_calls
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM public.order_conversations
            WHERE customer_id = auth.uid() OR
            restaurant_id IN (
                SELECT id FROM public.restaurants
                WHERE id IN (
                    SELECT restaurant_id FROM public.user_profiles
                    WHERE id = auth.uid() AND role = 'restaurant_owner'
                )
                OR id IN (
                    SELECT restaurant_id FROM public.user_roles
                    WHERE user_id = auth.uid() AND role = 'restaurant_staff'
                )
            )
        )
    );

-- Add comments
COMMENT ON TABLE public.order_conversations IS 'Manages chat conversations tied to specific orders';
COMMENT ON TABLE public.order_messages IS 'Stores all messages within order conversations';
COMMENT ON TABLE public.order_calls IS 'Records voice/video calls within order conversations';
COMMENT ON TABLE public.order_communication_settings IS 'User preferences for order-specific communications';
COMMENT ON VIEW public.active_order_communications IS 'Real-time view of active order communications with metadata';