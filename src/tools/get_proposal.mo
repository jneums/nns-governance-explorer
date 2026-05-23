import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Json "mo:json";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";

import ToolContext "ToolContext";
import JsonHelpers "../JsonHelpers";

module {

  public func config() : McpTypes.Tool = {
    name = "get_proposal";
    title = ?"Get Proposal Details";
    description = ?"Get full details for a single NNS governance proposal including summary, tally, action type, and all timestamps.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("proposal_id", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("The proposal ID")),
        ])),
      ])),
      ("required", Json.arr([Json.str("proposal_id")])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("id", Json.obj([("type", Json.str("integer"))])),
        ("title", Json.obj([("type", Json.str("string"))])),
        ("summary", Json.obj([("type", Json.str("string"))])),
        ("status", Json.obj([("type", Json.str("string"))])),
        ("topic", Json.obj([("type", Json.str("string"))])),
        ("action_type", Json.obj([("type", Json.str("string"))])),
      ])),
    ]);
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      let proposalId = switch (Result.toOption(Json.getAsNat(args, "proposal_id"))) {
        case (?n) { Nat64.fromNat(n) };
        case null {
          return ToolContext.makeError("Missing required argument: proposal_id", cb);
        };
      };

      try {
        let response = await ctx.governance.get_proposal_info(proposalId);

        switch (response) {
          case (?info) {
            let result = JsonHelpers.proposalDetailToJson(info);
            ToolContext.makeSuccess(result, cb);
          };
          case null {
            let result = Json.obj([
              ("error", Json.str("Proposal not found")),
              ("proposal_id", Json.int(Nat64.toNat(proposalId))),
            ]);
            ToolContext.makeSuccess(result, cb);
          };
        };
      } catch (e) {
        ToolContext.makeError("Failed to reach NNS governance canister: " # Error.message(e), cb);
      };
    };
  };
};
