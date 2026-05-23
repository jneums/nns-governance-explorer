import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Json "mo:json";

import ToolContext "ToolContext";
import JsonHelpers "../JsonHelpers";

module {

  public func config() : McpTypes.Tool = {
    name = "get_governance_metrics";
    title = ?"Get Governance Metrics";
    description = ?"Get cached NNS governance metrics including total staked ICP, neuron counts, dissolving statistics, and more.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("total_staked_e8s", Json.obj([("type", Json.str("integer"))])),
        ("total_supply_icp", Json.obj([("type", Json.str("integer"))])),
        ("not_dissolving_neurons_count", Json.obj([("type", Json.str("integer"))])),
        ("dissolving_neurons_count", Json.obj([("type", Json.str("integer"))])),
      ])),
    ]);
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(_args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      try {
        let response = await ctx.governance.get_metrics();

        switch (response) {
          case (#Ok(m)) {
            let result = Json.obj([
              ("total_staked_e8s", JsonHelpers.nat64(m.total_staked_e8s)),
              ("total_supply_icp", JsonHelpers.nat64(m.total_supply_icp)),
              ("total_locked_e8s", JsonHelpers.nat64(m.total_locked_e8s)),
              ("total_voting_power", JsonHelpers.optNat64(m.total_voting_power_non_self_authenticating_controller)),
              ("not_dissolving_neurons_count", JsonHelpers.nat64(m.not_dissolving_neurons_count)),
              ("dissolving_neurons_count", JsonHelpers.nat64(m.dissolving_neurons_count)),
              ("dissolved_neurons_count", JsonHelpers.nat64(m.dissolved_neurons_count)),
              ("seed_neuron_count", JsonHelpers.nat64(m.seed_neuron_count)),
              ("ect_neuron_count", JsonHelpers.nat64(m.ect_neuron_count)),
              ("total_maturity_e8s", JsonHelpers.nat64(m.total_maturity_e8s_equivalent)),
              ("total_staked_maturity_e8s", JsonHelpers.nat64(m.total_staked_maturity_e8s_equivalent)),
              ("neurons_fund_total_active_neurons", JsonHelpers.nat64(m.neurons_fund_total_active_neurons)),
              ("community_fund_total_staked_e8s", JsonHelpers.nat64(m.community_fund_total_staked_e8s)),
              ("timestamp", JsonHelpers.nat64(m.timestamp_seconds)),
            ]);

            ToolContext.makeSuccess(result, cb);
          };
          case (#Err(err)) {
            ToolContext.makeError("Failed to get governance metrics: " # err.error_message, cb);
          };
        };
      } catch (e) {
        ToolContext.makeError("Failed to reach NNS governance canister: " # Error.message(e), cb);
      };
    };
  };
};
