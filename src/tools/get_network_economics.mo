import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Nat32 "mo:base/Nat32";
import Json "mo:json";

import ToolContext "ToolContext";
import JsonHelpers "../JsonHelpers";

module {

  public func config() : McpTypes.Tool = {
    name = "get_network_economics";
    title = ?"Get Network Economics";
    description = ?"Get current NNS economic parameters including minimum neuron stake, reject cost, transaction fee, and voting power economics.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("neuron_minimum_stake_e8s", Json.obj([("type", Json.str("integer"))])),
        ("reject_cost_e8s", Json.obj([("type", Json.str("integer"))])),
        ("transaction_fee_e8s", Json.obj([("type", Json.str("integer"))])),
      ])),
    ]);
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(_args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      try {
        let econ = await ctx.governance.get_network_economics_parameters();

        let vpEconomics = switch (econ.voting_power_economics) {
          case (?vpe) {
            Json.obj([
              ("start_reducing_voting_power_after_seconds", JsonHelpers.optNat64(vpe.start_reducing_voting_power_after_seconds)),
              ("clear_following_after_seconds", JsonHelpers.optNat64(vpe.clear_following_after_seconds)),
              ("neuron_minimum_dissolve_delay_to_vote_seconds", JsonHelpers.optNat64(vpe.neuron_minimum_dissolve_delay_to_vote_seconds)),
            ]);
          };
          case null { Json.nullable() };
        };

        let result = Json.obj([
          ("neuron_minimum_stake_e8s", JsonHelpers.nat64(econ.neuron_minimum_stake_e8s)),
          ("max_proposals_to_keep_per_topic", Json.int(Nat32.toNat(econ.max_proposals_to_keep_per_topic))),
          ("neuron_management_fee_per_proposal_e8s", JsonHelpers.nat64(econ.neuron_management_fee_per_proposal_e8s)),
          ("reject_cost_e8s", JsonHelpers.nat64(econ.reject_cost_e8s)),
          ("transaction_fee_e8s", JsonHelpers.nat64(econ.transaction_fee_e8s)),
          ("neuron_spawn_dissolve_delay_seconds", JsonHelpers.nat64(econ.neuron_spawn_dissolve_delay_seconds)),
          ("minimum_icp_xdr_rate", JsonHelpers.nat64(econ.minimum_icp_xdr_rate)),
          ("maximum_node_provider_rewards_e8s", JsonHelpers.nat64(econ.maximum_node_provider_rewards_e8s)),
          ("voting_power_economics", vpEconomics),
        ]);

        ToolContext.makeSuccess(result, cb);
      } catch (e) {
        ToolContext.makeError("Failed to reach NNS governance canister: " # Error.message(e), cb);
      };
    };
  };
};
