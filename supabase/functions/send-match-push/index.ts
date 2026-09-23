import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5.10.0";

type MatchPushRequest = {
  match_id: string;
  event: "invite" | "response";
};

const json = (body: unknown, status = 200) => Response.json(body, { status });

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "Authentication required" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY")
    ?? Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const apnsKey = Deno.env.get("APNS_KEY_P8")?.replaceAll("\\n", "\n");
  const apnsKeyID = Deno.env.get("APNS_KEY_ID");
  const apnsTeamID = Deno.env.get("APNS_TEAM_ID");
  const apnsBundleID = Deno.env.get("APNS_BUNDLE_ID") ?? "com.rallyup.app";
  const apnsEnvironment = Deno.env.get("APNS_ENVIRONMENT") ?? "sandbox";

  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    return json({ error: "Supabase function environment is incomplete" }, 503);
  }
  if (!apnsKey || !apnsKeyID || !apnsTeamID) {
    return json({ error: "APNs credentials are not configured" }, 503);
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();
  if (userError || !user) return json({ error: "Invalid session" }, 401);

  let body: MatchPushRequest;
  try {
    body = await request.json() as MatchPushRequest;
  } catch {
    return json({ error: "Invalid request body" }, 400);
  }
  if (!body.match_id || !["invite", "response"].includes(body.event)) {
    return json({ error: "Invalid match push request" }, 400);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: match, error: matchError } = await adminClient
    .from("matches")
    .select("id,created_by,courts(name),match_participants(player_id)")
    .eq("id", body.match_id)
    .single();
  if (matchError || !match) return json({ error: "Match not found" }, 404);

  const participantIDs = (match.match_participants ?? [])
    .map((participant: { player_id: string }) => participant.player_id);
  if (match.created_by !== user.id && !participantIDs.includes(user.id)) {
    return json({ error: "You are not part of this match" }, 403);
  }

  const recipientIDs = participantIDs.filter((id: string) => id !== user.id);
  if (recipientIDs.length === 0) return json({ sent: 0 });

  const { data: tokenRows, error: tokenError } = await adminClient
    .from("device_push_tokens")
    .select("device_token,user_id")
    .in("user_id", recipientIDs);
  if (tokenError) return json({ error: "Could not load push tokens" }, 500);

  const courtName = match.courts?.name ?? "your RallyUp match";
  const alert = body.event === "invite"
    ? { title: "New match invite", body: `You have an invite at ${courtName}.` }
    : { title: "Match invite updated", body: `Your match at ${courtName} was updated.` };

  const signingKey = await importPKCS8(apnsKey, "ES256");
  const providerToken = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: apnsKeyID })
    .setIssuer(apnsTeamID)
    .setIssuedAt()
    .sign(signingKey);
  const host = apnsEnvironment === "production"
    ? "api.push.apple.com"
    : "api.sandbox.push.apple.com";

  let sent = 0;
  for (const row of tokenRows ?? []) {
    const response = await fetch(`https://${host}/3/device/${row.device_token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${providerToken}`,
        "apns-topic": apnsBundleID,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        aps: { alert, sound: "default", badge: 1 },
        match_id: body.match_id,
      }),
    });

    if (response.ok) {
      sent += 1;
    } else if (response.status === 400 || response.status === 410) {
      await adminClient
        .from("device_push_tokens")
        .delete()
        .eq("device_token", row.device_token);
    }
  }

  return json({ sent });
});
