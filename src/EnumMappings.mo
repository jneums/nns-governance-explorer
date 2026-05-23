/// Human-readable string mappings for NNS governance integer codes
import Int32 "mo:base/Int32";
import Array "mo:base/Array";
import Text "mo:base/Text";
import GovernanceTypes "GovernanceTypes";

module {

  // --- Proposal Status ---
  public func proposalStatusToText(code : Int32) : Text {
    switch (Int32.toInt(code)) {
      case 0 { "unknown" };
      case 1 { "open" };
      case 2 { "rejected" };
      case 3 { "accepted" };
      case 4 { "executed" };
      case 5 { "failed" };
      case _ { "unknown" };
    };
  };

  public func proposalStatusFromText(t : Text) : ?Int32 {
    switch (t) {
      case "open" { ?Int32.fromInt(1) };
      case "rejected" { ?Int32.fromInt(2) };
      case "accepted" { ?Int32.fromInt(3) };
      case "executed" { ?Int32.fromInt(4) };
      case "failed" { ?Int32.fromInt(5) };
      case _ { null };
    };
  };

  // --- Proposal Topic ---
  public func topicToText(code : Int32) : Text {
    switch (Int32.toInt(code)) {
      case 0 { "unspecified" };
      case 1 { "neuron_management" };
      case 2 { "exchange_rate" };
      case 3 { "network_economics" };
      case 4 { "governance" };
      case 5 { "node_admin" };
      case 6 { "participant_management" };
      case 7 { "subnet_management" };
      case 8 { "network_canister_management" };
      case 9 { "kyc" };
      case 10 { "node_provider_rewards" };
      case 12 { "ic_os_version_deployment" };
      case 13 { "ic_os_version_election" };
      case 14 { "sns_and_community_fund" };
      case 15 { "api_boundary_node_management" };
      case 16 { "subnet_rental" };
      case 17 { "application_canister_management" };
      case 18 { "protocol_canister_management" };
      case 19 { "service_nervous_system_management" };
      case _ { "unknown" };
    };
  };

  public func topicFromText(t : Text) : ?Int32 {
    switch (t) {
      case "unspecified" { ?Int32.fromInt(0) };
      case "neuron_management" { ?Int32.fromInt(1) };
      case "exchange_rate" { ?Int32.fromInt(2) };
      case "network_economics" { ?Int32.fromInt(3) };
      case "governance" { ?Int32.fromInt(4) };
      case "node_admin" { ?Int32.fromInt(5) };
      case "participant_management" { ?Int32.fromInt(6) };
      case "subnet_management" { ?Int32.fromInt(7) };
      case "network_canister_management" { ?Int32.fromInt(8) };
      case "kyc" { ?Int32.fromInt(9) };
      case "node_provider_rewards" { ?Int32.fromInt(10) };
      case "ic_os_version_deployment" { ?Int32.fromInt(12) };
      case "ic_os_version_election" { ?Int32.fromInt(13) };
      case "sns_and_community_fund" { ?Int32.fromInt(14) };
      case "api_boundary_node_management" { ?Int32.fromInt(15) };
      case "subnet_rental" { ?Int32.fromInt(16) };
      case "application_canister_management" { ?Int32.fromInt(17) };
      case "protocol_canister_management" { ?Int32.fromInt(18) };
      case "service_nervous_system_management" { ?Int32.fromInt(19) };
      case _ { null };
    };
  };

  // --- Reward Status ---
  public func rewardStatusToText(code : Int32) : Text {
    switch (Int32.toInt(code)) {
      case 0 { "unknown" };
      case 1 { "accept_votes" };
      case 2 { "ready_to_settle" };
      case 3 { "settled" };
      case 4 { "ineligible" };
      case _ { "unknown" };
    };
  };

  public func rewardStatusFromText(t : Text) : ?Int32 {
    switch (t) {
      case "accept_votes" { ?Int32.fromInt(1) };
      case "ready_to_settle" { ?Int32.fromInt(2) };
      case "settled" { ?Int32.fromInt(3) };
      case "ineligible" { ?Int32.fromInt(4) };
      case _ { null };
    };
  };

  // --- Neuron State ---
  public func neuronStateToText(code : Int32) : Text {
    switch (Int32.toInt(code)) {
      case 1 { "not_dissolving" };
      case 2 { "dissolving" };
      case 3 { "dissolved" };
      case 4 { "spawning" };
      case _ { "unknown" };
    };
  };

  // --- Neuron Type ---
  public func neuronTypeToText(code : ?Int32) : ?Text {
    switch (code) {
      case (?c) {
        switch (Int32.toInt(c)) {
          case 1 { ?"seed" };
          case 2 { ?"ect" };
          case _ { null };
        };
      };
      case null { null };
    };
  };

  // --- Vote ---
  public func voteToText(v : ?GovernanceTypes.Vote) : Text {
    switch (v) {
      case (?#Yes) { "yes" };
      case (?#No) { "no" };
      case (?#Unspecified) { "unspecified" };
      case null { "unspecified" };
    };
  };

  // --- Action Type ---
  public func actionTypeToText(action : ?GovernanceTypes.Action) : Text {
    switch (action) {
      case (?#RegisterKnownNeuron(_)) { "RegisterKnownNeuron" };
      case (?#DeregisterKnownNeuron(_)) { "DeregisterKnownNeuron" };
      case (?#ManageNeuron(_)) { "ManageNeuron" };
      case (?#UpdateCanisterSettings(_)) { "UpdateCanisterSettings" };
      case (?#InstallCode(_)) { "InstallCode" };
      case (?#StopOrStartCanister(_)) { "StopOrStartCanister" };
      case (?#CreateServiceNervousSystem(_)) { "CreateServiceNervousSystem" };
      case (?#ExecuteNnsFunction(_)) { "ExecuteNnsFunction" };
      case (?#RewardNodeProvider(_)) { "RewardNodeProvider" };
      case (?#OpenSnsTokenSwap(_)) { "OpenSnsTokenSwap" };
      case (?#SetSnsTokenSwapOpenTimeWindow(_)) { "SetSnsTokenSwapOpenTimeWindow" };
      case (?#SetDefaultFollowees(_)) { "SetDefaultFollowees" };
      case (?#RewardNodeProviders(_)) { "RewardNodeProviders" };
      case (?#ManageNetworkEconomics(_)) { "ManageNetworkEconomics" };
      case (?#ApproveGenesisKyc(_)) { "ApproveGenesisKyc" };
      case (?#AddOrRemoveNodeProvider(_)) { "AddOrRemoveNodeProvider" };
      case (?#Motion(_)) { "Motion" };
      case (?#FulfillSubnetRentalRequest(_)) { "FulfillSubnetRentalRequest" };
      case (?#BlessAlternativeGuestOsVersion(_)) { "BlessAlternativeGuestOsVersion" };
      case (?#TakeCanisterSnapshot(_)) { "TakeCanisterSnapshot" };
      case (?#LoadCanisterSnapshot(_)) { "LoadCanisterSnapshot" };
      case (?#CreateCanisterAndInstallCode(_)) { "CreateCanisterAndInstallCode" };
      case null { "unknown" };
    };
  };

  // --- TopicToFollow ---
  public func topicToFollowToText(t : GovernanceTypes.TopicToFollow) : Text {
    switch (t) {
      case (#CatchAll) { "catch_all" };
      case (#NeuronManagement) { "neuron_management" };
      case (#ExchangeRate) { "exchange_rate" };
      case (#NetworkEconomics) { "network_economics" };
      case (#Governance) { "governance" };
      case (#NodeAdmin) { "node_admin" };
      case (#ParticipantManagement) { "participant_management" };
      case (#SubnetManagement) { "subnet_management" };
      case (#Kyc) { "kyc" };
      case (#NodeProviderRewards) { "node_provider_rewards" };
      case (#IcOsVersionDeployment) { "ic_os_version_deployment" };
      case (#IcOsVersionElection) { "ic_os_version_election" };
      case (#SnsAndCommunityFund) { "sns_and_community_fund" };
      case (#ApiBoundaryNodeManagement) { "api_boundary_node_management" };
      case (#SubnetRental) { "subnet_rental" };
      case (#ApplicationCanisterManagement) { "application_canister_management" };
      case (#ProtocolCanisterManagement) { "protocol_canister_management" };
      case (#ServiceNervousSystemManagement) { "service_nervous_system_management" };
    };
  };

  // --- Helpers for parsing text arrays into int32 arrays ---
  public func parseStatusFilters(texts : [Text]) : [Int32] {
    Array.mapFilter<Text, Int32>(texts, func(t) { proposalStatusFromText(t) });
  };

  public func parseTopicFilters(texts : [Text]) : [Int32] {
    Array.mapFilter<Text, Int32>(texts, func(t) { topicFromText(t) });
  };

  public func parseRewardStatusFilters(texts : [Text]) : [Int32] {
    Array.mapFilter<Text, Int32>(texts, func(t) { rewardStatusFromText(t) });
  };

  // All valid status strings
  public let validStatuses : [Text] = ["open", "rejected", "accepted", "executed", "failed"];

  // All valid topic strings
  public let validTopics : [Text] = [
    "unspecified", "neuron_management", "exchange_rate", "network_economics",
    "governance", "node_admin", "participant_management", "subnet_management",
    "network_canister_management", "kyc", "node_provider_rewards",
    "ic_os_version_deployment", "ic_os_version_election", "sns_and_community_fund",
    "api_boundary_node_management", "subnet_rental", "application_canister_management",
    "protocol_canister_management", "service_nervous_system_management",
  ];

  // All valid reward status strings
  public let validRewardStatuses : [Text] = ["accept_votes", "ready_to_settle", "settled", "ineligible"];
};
