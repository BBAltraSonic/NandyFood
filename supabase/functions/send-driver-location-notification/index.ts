import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') || ''
const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY') || ''

interface DriverLocationPayload {
  order_id: string
  user_id: string
  driver_name: string
  driver_phone?: string
  driver_lat: number
  driver_lng: number
  customer_lat: number
  customer_lng: number
  distance_km?: number
  eta_minutes?: number
}

serve(async (req) => {
  try {
    const payload: DriverLocationPayload = await req.json()

    // Get user's FCM tokens
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data: devices, error: deviceError } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', payload.user_id)
      .eq('is_active', true)

    if (deviceError || !devices || devices.length === 0) {
      return new Response(
        JSON.stringify({ success: false, message: 'No devices found' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Calculate distance if not provided
    const distance = payload.distance_km || calculateDistance(
      payload.driver_lat,
      payload.driver_lng,
      payload.customer_lat,
      payload.customer_lng
    )

    const eta = payload.eta_minutes || Math.ceil(distance / 0.5) // Assume 30 km/h average

    // Determine notification based on distance
    let notification: { title: string; body: string; type: string }

    if (distance < 0.5) {
      notification = {
        title: '📍 Driver is Very Close!',
        body: `${payload.driver_name} is arriving in about ${eta} minute${eta > 1 ? 's' : ''}. Get ready!`,
        type: 'driver_very_near'
      }
    } else if (distance < 1.5) {
      notification = {
        title: '🛵 Driver Nearby',
        body: `${payload.driver_name} is ${distance.toFixed(1)} km away (${eta} min)`,
        type: 'driver_nearby'
      }
    } else {
      notification = {
        title: '📱 Driver Location Update',
        body: `${payload.driver_name} is on the way - ${distance.toFixed(1)} km away (ETA: ${eta} min)`,
        type: 'driver_location_update'
      }
    }

    // Send notifications
    const results = await Promise.all(
      devices.map(device => sendFCMNotification(
        device.fcm_token,
        notification.title,
        notification.body,
        {
          type: notification.type,
          order_id: payload.order_id,
          driver_name: payload.driver_name,
          driver_phone: payload.driver_phone || '',
          distance: distance.toString(),
          eta: eta.toString()
        }
      ))
    )

    return new Response(
      JSON.stringify({ 
        success: true, 
        sent: results.filter(r => r.success).length,
        distance_km: distance,
        eta_minutes: eta
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error sending driver notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})

// Haversine formula to calculate distance between two coordinates
function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371 // Earth's radius in km
  const dLat = toRadians(lat2 - lat1)
  const dLng = toRadians(lng2 - lng1)
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2)
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180)
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
                channel_id: 'food_delivery_channel',
                notification_priority: 'PRIORITY_HIGH'
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                  'content-available': 1
                }
              }
            }
          }
        })
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
