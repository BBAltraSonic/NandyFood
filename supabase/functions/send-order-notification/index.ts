import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') || ''
const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY') || ''

interface OrderNotificationPayload {
  order_id: string
  user_id: string
  status: string
  restaurant_name: string
  estimated_time?: string
}

serve(async (req) => {
  try {
    const payload: OrderNotificationPayload = await req.json()

    // Get user's FCM tokens from database
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Fetch user's active devices
    const { data: devices, error: deviceError } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', payload.user_id)
      .eq('is_active', true)

    if (deviceError || !devices || devices.length === 0) {
      console.log('No active devices found for user:', payload.user_id)
      return new Response(
        JSON.stringify({ success: false, message: 'No devices found' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      )
    }

    // Build notification message based on status
    const notification = getNotificationForStatus(payload.status, payload.restaurant_name, payload.estimated_time)

    // Send FCM notification to each device
    const results = await Promise.all(
      devices.map(device => sendFCMNotification(
        device.fcm_token,
        notification.title,
        notification.body,
        {
          type: 'order_status',
          order_id: payload.order_id,
          status: payload.status
        }
      ))
    )

    console.log(`Sent ${results.length} notifications for order ${payload.order_id}`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        sent: results.filter(r => r.success).length,
        total: results.length 
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error sending order notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

function getNotificationForStatus(status: string, restaurantName: string, estimatedTime?: string) {
  const notifications: Record<string, { title: string; body: string }> = {
    'confirmed': {
      title: '✅ Order Confirmed',
      body: `Your order from ${restaurantName} has been confirmed.`
    },
    'preparing': {
      title: '👨‍🍳 Preparing Your Food',
      body: `${restaurantName} is preparing your order.`
    },
    'ready_for_pickup': {
      title: '✨ Order Ready',
      body: `Your order from ${restaurantName} is ready for pickup!`
    },
    'out_for_delivery': {
      title: '🛵 On the Way',
      body: estimatedTime 
        ? `Your order from ${restaurantName} is on the way! ETA: ${estimatedTime}` 
        : `Your order from ${restaurantName} is on the way!`
    },
    'nearby': {
      title: '📍 Driver Nearby',
      body: `Your driver is less than 1 km away!`
    },
    'delivered': {
      title: '🎉 Delivered!',
      body: `Your order from ${restaurantName} has been delivered. Enjoy your meal!`
    },
    'cancelled': {
      title: '❌ Order Cancelled',
      body: `Your order from ${restaurantName} has been cancelled.`
    }
  }

  return notifications[status] || {
    title: 'Order Update',
    body: `Your order from ${restaurantName} status: ${status}`
  }
}

async function sendFCMNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${FIREBASE_SERVER_KEY}`
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title,
              body
            },
            data,
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channel_id: 'food_delivery_channel'
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1
                }
              }
            }
          }
        })
      }
    )

    if (!response.ok) {
      const error = await response.text()
      console.error('FCM error:', error)
      return { success: false, error }
    }

    return { success: true }
  } catch (error) {
    console.error('Error sending FCM:', error)
    return { success: false, error: error.message }
  }
}
