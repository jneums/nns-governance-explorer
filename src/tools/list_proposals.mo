import Error "mo:base/Error";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";
import Result "mo:base/Result";
import Json "mo:json";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Int32 "mo:base/Int32";

import ToolContext "ToolContext";
import EnumMappings "../EnumMappings";
import JsonHelpers "../JsonHelpers";

module {

  public func config() : McpTypes.Tool = {
    name = "list_proposals";
    title = ?"List NNS Proposals";
    description = ?"Browse NNS governance proposals with optional filtering by status, topic, and reward status. Supports pagination via before_proposal cursor.";
    payment = null;
    inputSchema = Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("limit", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("Max proposals to return (default: 10, max: 50)")),
        ])),
        ("before_proposal", Json.obj([
          ("type", Json.str("integer")),
          ("description", Json.str("Proposal ID cursor for pagination — returns proposals with ID less than this value")),
        ])),
        ("include_status", Json.obj([
          ("type", Json.str("array")),
          ("items", Json.obj([("type", Json.str("string"))])),
          ("description", Json.str("Filter by status: open, accepted, rejected, executed, failed")),
        ])),
        ("exclude_topic", Json.obj([
          ("type", Json.str("array")),
          ("items", Json.obj([("type", Json.str("string"))])),
          ("description", Json.str("Exclude topics: neuron_management, exchange_rate, network_economics, governance, node_admin, subnet_management, kyc, etc.")),
        ])),
        ("include_reward_status", Json.obj([
          ("type", Json.str("array")),
          ("items", Json.obj([("type", Json.str("string"))])),
          ("description", Json.str("Filter by reward status: accept_votes, ready_to_settle, settled, ineligible")),
        ])),
      ])),
    ]);
    outputSchema = ?Json.obj([
      ("type", Json.str("object")),
      ("properties", Json.obj([
        ("proposals", Json.obj([
          ("type", Json.str("array")),
          ("description", Json.str("Array of proposal summaries")),
        ])),
        ("count", Json.obj([
          ("type", Json.str("integer")),
        ])),
      ])),
    ]);
  };

  // Extract text values from a Json array
  func extractTextArray(arr : [Json.Json]) : [Text] {
    Array.mapFilter<Json.Json, Text>(
      arr,
      func(j) {
        switch (j) {
          case (#string(t)) { ?t };
          case _ { null };
        };
      },
    );
  };

  public func handle(ctx : ToolContext.ToolContext) : McpTypes.ToolFn {
    func(args : McpTypes.JsonValue, _auth : ?AuthTypes.AuthInfo, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) : async () {

      // Parse limit
      let limit : Nat32 = switch (Result.toOption(Json.getAsNat(args, "limit"))) {
        case (?n) { Nat32.fromNat(if (n > 50) { 50 } else { n }) };
        case null { 10 : Nat32 };
      };

      // Parse before_proposal
      let beforeProposal = switch (Result.toOption(Json.getAsNat(args, "before_proposal"))) {
        case (?n) { ?{ id = Nat64.fromNat(n) } };
        case null { null };
      };

      // Parse include_status
      let includeStatus : [Int32] = switch (Result.toOption(Json.getAsArray(args, "include_status"))) {
        case (?arr) { EnumMappings.parseStatusFilters(extractTextArray(arr)) };
        case null { [] };
      };

      // Parse exclude_topic
      let excludeTopic : [Int32] = switch (Result.toOption(Json.getAsArray(args, "exclude_topic"))) {
        case (?arr) { EnumMappings.parseTopicFilters(extractTextArray(arr)) };
        case null { [] };
      };

      // Parse include_reward_status
      let includeRewardStatus : [Int32] = switch (Result.toOption(Json.getAsArray(args, "include_reward_status"))) {
        case (?arr) { EnumMappings.parseRewardStatusFilters(extractTextArray(arr)) };
        case null { [] };
      };

      try {
        let response = await ctx.governance.list_proposals({
          include_reward_status = includeRewardStatus;
          omit_large_fields = ?true;
          before_proposal = beforeProposal;
          limit = limit;
          exclude_topic = excludeTopic;
          include_all_manage_neuron_proposals = ?false;
          include_status = includeStatus;
          return_self_describing_action = ?false;
        });

        let proposals = Array.map(response.proposal_info, JsonHelpers.proposalSummaryToJson);

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
