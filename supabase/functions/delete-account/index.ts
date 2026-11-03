import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authorization = request.headers.get('Authorization')
    if (!authorization) {
      return Response.json(
        { error: 'Missing authorization header.' },
        { status: 401, headers: corsHeaders },
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const publishableKey =
      Deno.env.get('SUPABASE_ANON_KEY') ?? Deno.env.get('SB_PUBLISHABLE_KEY')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const userClient = createClient(supabaseUrl, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    })
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()

    if (userError || !user) {
      return Response.json(
        { error: 'Invalid user session.' },
        { status: 401, headers: corsHeaders },
      )
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    })
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      user.id,
    )
    if (deleteError) throw deleteError

    return Response.json({ deleted: true }, { headers: corsHeaders })
  } catch (error) {
    console.error('delete-account failed', error)
    return Response.json(
      { error: 'Account could not be deleted.' },
      { status: 500, headers: corsHeaders },
    )
  }
})
