import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Json "mo:json";
import Nat64 "mo:base/Nat64";

import ToolContext "ToolContext";
import JsonHelpers "../JsonHelpers";

module {

  public func config() : McpTypes.Tool = {
    name = "get_neuron_info";
    title = ?"Get Neuron Info";
    description = ?"Look up public information about an NNS neuron by ID, including state, stake, voting power, dissolve delay, and known neuron data.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("neuron_id", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("The neuron ID to look up")),
        ])),
      ])),
      ("required", Json.arr([Json.str("neuron_id")])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("neuron_id", Json.obj([("type", Json.str("integer"))])),
        ("state", Json.obj([("type", Json.str("string"))])),
        ("stake_e8s", Json.obj([("type", Json.str("integer"))])),
        ("dissolve_delay_seconds", Json.obj([("type", Json.str("integer"))])),
      ])),
    ]);
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      let neuronId = switch (Result.toOption(Json.getAsNat(args, "neuron_id"))) {
        case (?n) { Nat64.fromNat(n) };
        case null {
          return ToolContext.makeError("Missing required argument: neuron_id", cb);
        };
      };

      try {
        let response = await ctx.governance.get_neuron_info(neuronId);

        switch (response) {
          case (#Ok(info)) {
            let result = JsonHelpers.neuronInfoToJson(neuronId, info);
            ToolContext.makeSuccess(result, cb);
          };
          case (#Err(err)) {
            let result = Json.obj([
              ("error", Json.str("Neuron not found")),
              ("neuron_id", Json.int(Nat64.toNat(neuronId))),
              ("details", Json.str(err.error_message)),
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
