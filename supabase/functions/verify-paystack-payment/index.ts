// Supabase Edge Function to verify Paystack payment
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { reference } = await req.json();

    // Validate input
    if (!reference) {
      return new Response(
        JSON.stringify({ error: 'Payment reference is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Get Paystack secret key from environment
    const paystackSecretKey = Deno.env.get('PAYSTACK_SECRET_KEY');
    if (!paystackSecretKey) {
      throw new Error('Paystack secret key not configured');
    }

    // Verify transaction with Paystack
    const response = await fetch(`https://api.paystack.co/transaction/verify/${reference}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${paystackSecretKey}`,
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || 'Failed to verify payment');
    }

    // Check if payment was successful
    const paymentData = data.data;
    const isSuccess = paymentData.status === 'success';

    return new Response(
      JSON.stringify({
        success: isSuccess,
        status: paymentData.status,
        reference: paymentData.reference,
        amount: paymentData.amount / 100, // Convert from kobo to main currency
        currency: paymentData.currency,
        paid_at: paymentData.paid_at,
        channel: paymentData.channel,
        authorization: paymentData.authorization,
        customer: {
          email: paymentData.customer.email,
          customer_code: paymentData.customer.customer_code,
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
