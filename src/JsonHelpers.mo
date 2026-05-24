/// JSON serialization helpers for governance data
///
/// All Nat64 values are serialized as JSON strings to avoid float64 precision
/// loss in JavaScript. Nat64 can hold values up to 2^64-1 (~1.8e19), but
/// JSON numbers parsed by JS lose precision beyond 2^53 (~9e15). Neuron IDs,
/// tally totals, and e8s amounts routinely exceed this threshold.
import Json "mo:json";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Array "mo:base/Array";

import GovernanceTypes "GovernanceTypes";
import EnumMappings "EnumMappings";

module {

  /// Convert optional text to JSON (null or string)
  public func optText(t : ?Text) : Json.Json {
    switch (t) {
      case (?v) { Json.str(v) };
      case null { Json.nullable() };
    };
  };

  /// Convert optional Nat64 to JSON string (avoids float64 precision loss)
  public func optNat64(n : ?Nat64) : Json.Json {
    switch (n) {
      case (?v) { Json.str(Nat.toText(Nat64.toNat(v))) };
      case null { Json.nullable() };
    };
  };

  /// Convert Nat64 to JSON string (avoids float64 precision loss)
  public func nat64(n : Nat64) : Json.Json {
    Json.str(Nat.toText(Nat64.toNat(n)));
  };

  /// Format Nat64 timestamp (seconds since epoch) as JSON string
  /// Returns null for zero timestamps
  public func timestampText(seconds : Nat64) : Json.Json {
    if (seconds == 0) { Json.nullable() } else {
      Json.str(Nat.toText(Nat64.toNat(seconds)));
    };
  };

  /// Format optional Nat64 timestamp
  public func optTimestampText(seconds : ?Nat64) : Json.Json {
    switch (seconds) {
      case (?s) {
        if (s == 0) { Json.nullable() } else {
          Json.str(Nat.toText(Nat64.toNat(s)));
        };
      };
      case null { Json.nullable() };
    };
  };

  /// Serialize a Tally to JSON
  public func tallyToJson(tally : ?GovernanceTypes.Tally) : Json.Json {
    switch (tally) {
      case (?t) {
        Json.obj([
          ("yes", nat64(t.yes)),
          ("no", nat64(t.no)),
          ("total", nat64(t.total)),
        ]);
      };
      case null {
        Json.obj([
          ("yes", Json.str("0")),
          ("no", Json.str("0")),
          ("total", Json.str("0")),
        ]);
      };
    };
  };

  /// Serialize a ProposalInfo to a summary JSON object (for list views)
  public func proposalSummaryToJson(p : GovernanceTypes.ProposalInfo) : Json.Json {
    let title = switch (p.proposal) {
      case (?prop) { optText(prop.title) };
      case null { Json.nullable() };
    };
    let url = switch (p.proposal) {
      case (?prop) { Json.str(prop.url) };
      case null { Json.str("") };
    };
    let proposerId = switch (p.proposer) {
      case (?nid) { nat64(nid.id) };
      case null { Json.nullable() };
    };
    let proposalId = switch (p.id) {
      case (?pid) { nat64(pid.id) };
      case null { Json.nullable() };
    };

    Json.obj([
      ("id", proposalId),
      ("title", title),
      ("topic", Json.str(EnumMappings.topicToText(p.topic))),
      ("status", Json.str(EnumMappings.proposalStatusToText(p.status))),
      ("proposer_neuron_id", proposerId),
      ("proposal_timestamp", nat64(p.proposal_timestamp_seconds)),
      ("deadline_timestamp", optNat64(p.deadline_timestamp_seconds)),
      ("tally", tallyToJson(p.latest_tally)),
      ("url", url),
      ("reward_status", Json.str(EnumMappings.rewardStatusToText(p.reward_status))),
    ]);
  };

  /// Serialize a ProposalInfo to a full detail JSON object
  public func proposalDetailToJson(p : GovernanceTypes.ProposalInfo) : Json.Json {
    let (title, summary, url, actionType) = switch (p.proposal) {
      case (?prop) {
        (
          optText(prop.title),
          Json.str(prop.summary),
          Json.str(prop.url),
          Json.str(EnumMappings.actionTypeToText(prop.action)),
        );
      };
      case null {
        (Json.nullable(), Json.str(""), Json.str(""), Json.str("unknown"));
      };
    };
    let proposerId = switch (p.proposer) {
      case (?nid) { nat64(nid.id) };
      case null { Json.nullable() };
    };
    let proposalId = switch (p.id) {
      case (?pid) { nat64(pid.id) };
      case null { Json.nullable() };
    };
    let failureReason = switch (p.failure_reason) {
      case (?err) { Json.str(err.error_message) };
      case null { Json.nullable() };
    };

    Json.obj([
      ("id", proposalId),
      ("title", title),
      ("summary", summary),
      ("url", url),
      ("topic", Json.str(EnumMappings.topicToText(p.topic))),
      ("status", Json.str(EnumMappings.proposalStatusToText(p.status))),
      ("action_type", actionType),
      ("proposer_neuron_id", proposerId),
      ("proposal_timestamp", nat64(p.proposal_timestamp_seconds)),
      ("deadline_timestamp", optNat64(p.deadline_timestamp_seconds)),
      ("decided_timestamp", timestampText(p.decided_timestamp_seconds)),
      ("executed_timestamp", timestampText(p.executed_timestamp_seconds)),
      ("failed_timestamp", timestampText(p.failed_timestamp_seconds)),
      ("failure_reason", failureReason),
      ("tally", tallyToJson(p.latest_tally)),
      ("reward_status", Json.str(EnumMappings.rewardStatusToText(p.reward_status))),
      ("reject_cost_e8s", nat64(p.reject_cost_e8s)),
    ]);
  };

  /// Serialize NeuronInfo to JSON
  public func neuronInfoToJson(neuronId : Nat64, info : GovernanceTypes.NeuronInfo) : Json.Json {
    let knownName = switch (info.known_neuron_data) {
      case (?knd) { Json.str(knd.name) };
      case null { Json.nullable() };
    };
    let knownDesc = switch (info.known_neuron_data) {
      case (?knd) { optText(knd.description) };
      case null { Json.nullable() };
    };

    Json.obj([
      ("neuron_id", nat64(neuronId)),
      ("state", Json.str(EnumMappings.neuronStateToText(info.state))),
      ("dissolve_delay_seconds", nat64(info.dissolve_delay_seconds)),
      ("age_seconds", nat64(info.age_seconds)),
      ("stake_e8s", nat64(info.stake_e8s)),
      ("deciding_voting_power", optNat64(info.deciding_voting_power)),
      ("potential_voting_power", optNat64(info.potential_voting_power)),
      ("created_timestamp", nat64(info.created_timestamp_seconds)),
      ("known_neuron_name", knownName),
      ("known_neuron_description", knownDesc),
      ("neuron_type", optText(EnumMappings.neuronTypeToText(info.neuron_type))),
    ]);
  };

  /// Serialize a KnownNeuron to JSON
  public func knownNeuronToJson(kn : GovernanceTypes.KnownNeuron) : Json.Json {
    let neuronId = switch (kn.id) {
      case (?nid) { nat64(nid.id) };
      case null { Json.nullable() };
    };
    let (name, description, links, topics) = switch (kn.known_neuron_data) {
      case (?knd) {
        let linksArr = switch (knd.links) {
          case (?ls) { Json.arr(Array.map<Text, Json.Json>(ls, func(l) { Json.str(l) })) };
          case null { Json.arr([]) };
        };
        let topicsArr = switch (knd.committed_topics) {
          case (?ts) {
            let mapped = Array.mapFilter<?GovernanceTypes.TopicToFollow, Json.Json>(
              ts,
              func(ot) {
                switch (ot) {
                  case (?t) { ?Json.str(EnumMappings.topicToFollowToText(t)) };
                  case null { null };
                };
              },
            );
            Json.arr(mapped);
          };
          case null { Json.arr([]) };
        };
        (Json.str(knd.name), optText(knd.description), linksArr, topicsArr);
      };
      case null {
        (Json.str(""), Json.nullable(), Json.arr([]), Json.arr([]));
      };
    };

    Json.obj([
      ("neuron_id", neuronId),
      ("name", name),
      ("description", description),
      ("links", links),
      ("committed_topics", topics),
    ]);
  };
};
