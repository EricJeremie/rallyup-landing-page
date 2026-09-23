import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return Response.json({ error: "Authentication required" }, { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    return Response.json({ error: "Account deletion is not configured" }, { status: 503 });
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return Response.json({ error: "Invalid session" }, { status: 401 });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Auth deletion rejects users who still own Storage objects. Remove the
  // account-scoped photo objects first; the database rows then cascade away.
  for (const bucket of ["profile-photos", "racket-photos"]) {
    const { data: objects, error: listError } = await adminClient.storage
      .from(bucket)
      .list(user.id, { limit: 1000, offset: 0 });
    if (listError) {
      return Response.json({ error: "Account deletion failed" }, { status: 500 });
    }

    const paths = (objects ?? []).map((object) => `${user.id}/${object.name}`);
    if (paths.length > 0) {
      const { error: removeError } = await adminClient.storage.from(bucket).remove(paths);
      if (removeError) {
        return Response.json({ error: "Account deletion failed" }, { status: 500 });
      }
    }
  }

  const { error } = await adminClient.auth.admin.deleteUser(user.id);
  if (error) {
    return Response.json({ error: "Account deletion failed" }, { status: 500 });
  }

  return Response.json({ deleted: true });
});
