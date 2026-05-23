import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Json "mo:json";
import Array "mo:base/Array";

import ToolContext "ToolContext";
import JsonHelpers "../JsonHelpers";

module {

  public func config() : McpTypes.Tool = {
    name = "get_pending_proposals";
    title = ?"Get Pending Proposals";
    description = ?"Get all currently open/pending NNS proposals that are still accepting votes.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("proposals", Json.obj([
          ("type", Json.str("array")),
          ("description", Json.str("Array of pending proposal summaries")),
        ])),
        ("count", Json.obj([("type", Json.str("integer"))])),
      ])),
    ]);
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(_args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      try {
        let response = await ctx.governance.get_pending_proposals(?{
          return_self_describing_action = ?false;
        });

        let proposals = Array.map(response, JsonHelpers.proposalSummaryToJson);

        let result = Json.obj([
          ("proposals", Json.arr(proposals)),
          ("count", Json.int(proposals.size())),
        ]);

        ToolContext.makeSuccess(result, cb);
      } catch (e) {
        ToolContext.makeError("Failed to reach NNS governance canister: " # Error.message(e), cb);
      };
    };
  };
};
