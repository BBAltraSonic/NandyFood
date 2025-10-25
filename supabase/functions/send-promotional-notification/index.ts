import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') || ''
const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY') || ''

interface PromoNotificationPayload {
  title: string
  body: string
  image_url?: string
  action_url?: string
  target_users?: string[] // Specific user IDs, if empty sends to all
  target_segments?: string[] // e.g., ['premium', 'frequent_orderers']
  restaurant_id?: string // For restaurant-specific promos
}

serve(async (req) => {
  try {
    const payload: PromoNotificationPayload = await req.json()

    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Build query to get target devices
    let devicesQuery = supabase
      .from('user_devices')
      .select('fcm_token, user_id')
      .eq('is_active', true)

    // Filter by specific users if provided
    if (payload.target_users && payload.target_users.length > 0) {
      devicesQuery = devicesQuery.in('user_id', payload.target_users)
    }

    const { data: devices, error: deviceError } = await devicesQuery

    if (deviceError || !devices || devices.length === 0) {
      return new Response(
        JSON.stringify({ success: false, message: 'No devices found' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // If segments are specified, filter users
    let targetDevices = devices
    if (payload.target_segments && payload.target_segments.length > 0) {
      // Query user profiles for segmentation
      const { data: profiles } = await supabase
        .from('user_profiles')
        .select('id')
        .in('id', devices.map(d => d.user_id))
      
      if (profiles) {
        const segmentedUserIds = profiles.map(p => p.id)
        targetDevices = devices.filter(d => segmentedUserIds.includes(d.user_id))
      }
    }

    // Send notifications in batches to avoid rate limits
    const batchSize = 500
    let totalSent = 0
    
    for (let i = 0; i < targetDevices.length; i += batchSize) {
      const batch = targetDevices.slice(i, i + batchSize)
      
      const results = await Promise.all(
        batch.map(device => sendFCMNotification(
          device.fcm_token,
          payload.title,
          payload.body,
          {
            type: 'promotion',
            action_url: payload.action_url || '',
            restaurant_id: payload.restaurant_id || ''
          },
          payload.image_url
        ))
      )
      
      totalSent += results.filter(r => r.success).length
    }

    // Log promotional campaign
    await supabase.from('notification_logs').insert({
      type: 'promotional',
      title: payload.title,
      target_count: targetDevices.length,
      sent_count: totalSent,
      payload: payload,
      created_at: new Date().toISOString()
    })

    return new Response(
      JSON.stringify({ 
        success: true, 
        sent: totalSent,
        total_devices: targetDevices.length
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error sending promotional notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

async function sendFCMNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
  imageUrl?: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const message: any = {
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
          channel_id: 'food_delivery_channel',
          color: '#FF6B35'
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

    // Add image if provided
    if (imageUrl) {
      message.notification.image = imageUrl
      message.android.notification.image = imageUrl
      message.apns.fcm_options = { image: imageUrl }
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${FIREBASE_SERVER_KEY}`
        },
        body: JSON.stringify({ message })
      }
    )

    if (!response.ok) {
      const error = await response.text()
      return { success: false, error }
    }

    return { success: true }
  } catch (error) {
    return { success: false, error: error.message }
  }
}
