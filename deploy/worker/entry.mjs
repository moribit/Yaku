// Application boundary around the unchanged, Akamata-managed WASM bridge.
import bridge from "./index.mjs";
import { boundedRequest } from "./request_limit.mjs";
export default {
  async fetch(request, env, ctx) {
    try {
      const bounded = await boundedRequest(request);
      if (!bounded)
        return Response.json(
          { error_kind: "request_too_large" },
          { status: 413 },
        );
      return await bridge.fetch(bounded, env, ctx);
    } catch {
      console.error(JSON.stringify({ message: "application dispatch failed" }));
      return Response.json(
        { error_kind: "internal_server_error" },
        { status: 500 },
      );
    }
  },
};
