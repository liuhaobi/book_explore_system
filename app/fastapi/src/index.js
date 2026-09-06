const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
    },
  });

function normalizeTokenPayload(raw) {
  if (raw && typeof raw === "object" && !Array.isArray(raw)) return raw;

  if (typeof raw !== "string") {
    return { detail: "SourceForge returned an invalid token response" };
  }

  const value = raw.trim();
  try {
    const nested = JSON.parse(value);
    if (nested && typeof nested === "object" && !Array.isArray(nested)) {
      return nested;
    }
    if (typeof nested === "string") return normalizeTokenPayload(nested);
  } catch (_) {
    // Continue with form-encoded/plain-text handling.
  }

  const form = new URLSearchParams(value);
  const formToken = form.get("access_token") || form.get("token");
  if (formToken) return Object.fromEntries(form.entries());

  if (value === "授权成功" || value === "Authorization completed") {
    return {
      detail: "Authorization callback succeeded, but no access_token was returned",
    };
  }

  return value
    ? { access_token: value }
    : { detail: "SourceForge returned an empty token response" };
}

async function exchangeToken(request, env) {
  if (!env.SOURCEFORGE_CLIENT_ID || !env.SOURCEFORGE_CLIENT_SECRET) {
    return json({ detail: "SourceForge OAuth is not configured" }, 500);
  }

  let params;
  try {
    params = await request.json();
  } catch (_) {
    return json({ detail: "JSON body is required" }, 400);
  }

  if (!params || typeof params !== "object" || Array.isArray(params)) {
    return json({ detail: "JSON object is required" }, 400);
  }

  const { code, code_verifier: codeVerifier } = params;
  const clientId = params.client_id || env.SOURCEFORGE_CLIENT_ID;
  if (!code || !codeVerifier) {
    return json({ detail: "code and code_verifier are required" }, 400);
  }
  if (clientId !== env.SOURCEFORGE_CLIENT_ID) {
    return json({ detail: "invalid client_id" }, 400);
  }

  const form = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    client_id: env.SOURCEFORGE_CLIENT_ID,
    client_secret: env.SOURCEFORGE_CLIENT_SECRET,
    redirect_uri: env.SOURCEFORGE_REDIRECT_URI,
    code_verifier: codeVerifier,
  });

  let upstream;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    upstream = await fetch(env.SOURCEFORGE_TOKEN_URL, {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/x-www-form-urlencoded",
      },
      body: form,
      signal: controller.signal,
    });
  } catch (error) {
    const timedOut = error?.name === "AbortError";
    console.error(
      JSON.stringify({
        event: "sourceforge_token_request_failed",
        timed_out: timedOut,
        message: error?.message,
        token_url: env.SOURCEFORGE_TOKEN_URL,
        redirect_uri: env.SOURCEFORGE_REDIRECT_URI,
      }),
    );
    return json(
      {
        detail: timedOut
          ? "SourceForge token request timed out"
          : `SourceForge token request failed: ${error.message}`,
      },
      timedOut ? 504 : 502,
    );
  } finally {
    clearTimeout(timeout);
  }

  const text = await upstream.text();
  let raw;
  try {
    raw = JSON.parse(text);
  } catch (_) {
    raw = text;
  }

  const payload = normalizeTokenPayload(raw);
  const token = payload.access_token || payload.token;
  console.log(
    JSON.stringify({
      event: "sourceforge_token_response",
      upstream_status: upstream.status,
      has_access_token: Boolean(token),
      content_type: upstream.headers.get("content-type"),
    }),
  );
  if (!token) {
    return json(payload, upstream.ok ? 502 : upstream.status);
  }

  return json(payload, upstream.status);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "GET, POST, OPTIONS",
          "access-control-allow-headers": "content-type",
        },
      });
    }

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ status: "ok" });
    }

    if (request.method === "GET" && url.pathname === "/test") {
      return json({ message: "hello" });
    }

    if (request.method === "GET" && url.pathname === "/source/auth/callback") {
      if (url.searchParams.get("error")) {
        return json(
          {
            status: "error",
            error: url.searchParams.get("error"),
            error_description: url.searchParams.get("error_description"),
          },
          400,
        );
      }
      return json({
        status: "authorized",
        message: "授权成功，请返回应用",
        has_code: Boolean(url.searchParams.get("code")),
      });
    }

    if (request.method === "POST" && url.pathname === "/source/auth/token") {
      return exchangeToken(request, env);
    }

    return json({ detail: "Not found" }, 404);
  },
};
