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
    name = "list_known_neurons";
    title = ?"List Known Neurons";
    description = ?"List all registered known neurons on the NNS with their names, descriptions, links, and committed voting topics.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("known_neurons", Json.obj([
          ("type", Json.str("array")),
          ("description", Json.str("Array of known neurons with metadata")),
        ])),
        ("count", Json.obj([("type", Json.str("integer"))])),
      ])),
    ]);
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(_args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      try {
        let response = await ctx.governance.list_known_neurons();

        let neurons = Array.map(response.known_neurons, JsonHelpers.knownNeuronToJson);

        let result = Json.obj([
          ("known_neurons", Json.arr(neurons)),
          ("count", Json.int(neurons.size())),
        ]);

        ToolContext.makeSuccess(result, cb);
      } catch (e) {
        ToolContext.makeError("Failed to reach NNS governance canister: " # Error.message(e), cb);
      };
    };
  };
};
