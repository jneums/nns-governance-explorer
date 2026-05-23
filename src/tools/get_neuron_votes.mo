import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Json "mo:json";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";

import ToolContext "ToolContext";
import EnumMappings "../EnumMappings";
import JsonHelpers "../JsonHelpers";
import GovernanceTypes "../GovernanceTypes";

module {

  public func config() : McpTypes.Tool = {
    name = "get_neuron_votes";
    title = ?"Get Neuron Voting History";
    description = ?"Get the voting history of a known neuron. Only available for neurons registered as known neurons.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("neuron_id", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("The neuron ID (must be a known neuron)")),
        ])),
        ("limit", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("Max votes to return (default: 20, max: 100)")),
        ])),
        ("before_proposal", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("Pagination cursor — return votes on proposals before this ID")),
        ])),
      ])),
      ("required", Json.arr([Json.str("neuron_id")])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("neuron_id", Json.obj([("type", Json.str("integer"))])),
        ("votes", Json.obj([
          ("type", Json.str("array")),
          ("description", Json.str("Array of vote records")),
        ])),
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

      let limit : Nat64 = switch (Result.toOption(Json.getAsNat(args, "limit"))) {
        case (?n) { Nat64.fromNat(if (n > 100) { 100 } else { n }) };
        case null { 20 : Nat64 };
      };

      let beforeProposal = switch (Result.toOption(Json.getAsNat(args, "before_proposal"))) {
        case (?n) { ?{ id = Nat64.fromNat(n) } : ?GovernanceTypes.ProposalId };
        case null { null };
      };

      try {
        let response = await ctx.governance.list_neuron_votes({
          neuron_id = ?{ id = neuronId };
          before_proposal = beforeProposal;
          limit = ?limit;
        });

        switch (response) {
          case (#Ok(data)) {
            let votes = switch (data.votes) {
              case (?vs) {
                Array.map<GovernanceTypes.NeuronVote, Json.Json>(
                  vs,
                  func(v) {
                    let proposalIdJson = switch (v.proposal_id) {
                      case (?pid) { JsonHelpers.nat64(pid.id) };
                      case null { Json.nullable() };
                    };
                    Json.obj([
                      ("proposal_id", proposalIdJson),
                      ("vote", Json.str(EnumMappings.voteToText(v.vote))),
                    ]);
                  },
                );
              };
              case null { [] };
            };

            let result = Json.obj([
              ("neuron_id", Json.int(Nat64.toNat(neuronId))),
              ("votes", Json.arr(votes)),
              ("count", Json.int(votes.size())),
            ]);

            ToolContext.makeSuccess(result, cb);
          };
          case (#Err(err)) {
            let result = Json.obj([
              ("error", Json.str("Voting history unavailable")),
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
