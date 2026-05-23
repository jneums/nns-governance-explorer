/// Candid types for the NNS Governance canister (rrkah-fqaaa-aaaaa-aaaaq-cai)
/// Only the query methods and types we need for read-only access.
module {

  public type NeuronId = { id : Nat64 };
  public type ProposalId = { id : Nat64 };

  public type Ballot = {
    vote : Int32;
    voting_power : Nat64;
  };

  public type BallotInfo = {
    vote : Int32;
    proposal_id : ?ProposalId;
  };

  public type Tally = {
    no : Nat64;
    yes : Nat64;
    total : Nat64;
    timestamp_seconds : Nat64;
  };

  public type GovernanceError = {
    error_message : Text;
    error_type : Int32;
  };

  public type KnownNeuronData = {
    name : Text;
    description : ?Text;
    links : ?[Text];
    committed_topics : ?[?TopicToFollow];
  };

  public type TopicToFollow = {
    #CatchAll;
    #NeuronManagement;
    #ExchangeRate;
    #NetworkEconomics;
    #Governance;
    #NodeAdmin;
    #ParticipantManagement;
    #SubnetManagement;
    #Kyc;
    #NodeProviderRewards;
    #IcOsVersionDeployment;
    #IcOsVersionElection;
    #SnsAndCommunityFund;
    #ApiBoundaryNodeManagement;
    #SubnetRental;
    #ApplicationCanisterManagement;
    #ProtocolCanisterManagement;
    #ServiceNervousSystemManagement;
  };

  public type KnownNeuron = {
    id : ?NeuronId;
    known_neuron_data : ?KnownNeuronData;
  };

  public type Motion = { motion_text : Text };

  // Simplified Action — we only need the variant tag to determine action_type
  public type Action = {
    #RegisterKnownNeuron : Any;
    #DeregisterKnownNeuron : Any;
    #ManageNeuron : Any;
    #UpdateCanisterSettings : Any;
    #InstallCode : Any;
    #StopOrStartCanister : Any;
    #CreateServiceNervousSystem : Any;
    #ExecuteNnsFunction : Any;
    #RewardNodeProvider : Any;
    #OpenSnsTokenSwap : Any;
    #SetSnsTokenSwapOpenTimeWindow : Any;
    #SetDefaultFollowees : Any;
    #RewardNodeProviders : Any;
    #ManageNetworkEconomics : Any;
    #ApproveGenesisKyc : Any;
    #AddOrRemoveNodeProvider : Any;
    #Motion : Motion;
    #FulfillSubnetRentalRequest : Any;
    #BlessAlternativeGuestOsVersion : Any;
    #TakeCanisterSnapshot : Any;
    #LoadCanisterSnapshot : Any;
    #CreateCanisterAndInstallCode : Any;
  };

  public type Proposal = {
    url : Text;
    title : ?Text;
    action : ?Action;
    summary : Text;
  };

  public type SuccessfulProposalExecutionValue = {
    #CreateCanisterAndInstallCode : Any;
    #TakeCanisterSnapshot : Any;
  };

  public type DerivedProposalInformation = {
    swap_background_information : ?Any;
  };

  public type ProposalInfo = {
    id : ?ProposalId;
    status : Int32;
    topic : Int32;
    failure_reason : ?GovernanceError;
    ballots : [(Nat64, Ballot)];
    proposal_timestamp_seconds : Nat64;
    reward_event_round : Nat64;
    deadline_timestamp_seconds : ?Nat64;
    failed_timestamp_seconds : Nat64;
    reject_cost_e8s : Nat64;
    derived_proposal_information : ?DerivedProposalInformation;
    latest_tally : ?Tally;
    reward_status : Int32;
    decided_timestamp_seconds : Nat64;
    proposal : ?Proposal;
    proposer : ?NeuronId;
    executed_timestamp_seconds : Nat64;
    total_potential_voting_power : ?Nat64;
    success_value : ?SuccessfulProposalExecutionValue;
  };

  public type NeuronInfo = {
    id : ?NeuronId;
    dissolve_delay_seconds : Nat64;
    recent_ballots : [BallotInfo];
    neuron_type : ?Int32;
    created_timestamp_seconds : Nat64;
    state : Int32;
    stake_e8s : Nat64;
    joined_community_fund_timestamp_seconds : ?Nat64;
    retrieved_at_timestamp_seconds : Nat64;
    visibility : ?Int32;
    known_neuron_data : ?KnownNeuronData;
    age_seconds : Nat64;
    voting_power : Nat64;
    voting_power_refreshed_timestamp_seconds : ?Nat64;
    deciding_voting_power : ?Nat64;
    potential_voting_power : ?Nat64;
    eight_year_gang_bonus_base_e8s : ?Nat64;
    staked_maturity_e8s_equivalent : ?Nat64;
  };

  public type ListProposalInfoRequest = {
    include_reward_status : [Int32];
    omit_large_fields : ?Bool;
    before_proposal : ?ProposalId;
    limit : Nat32;
    exclude_topic : [Int32];
    include_all_manage_neuron_proposals : ?Bool;
    include_status : [Int32];
    return_self_describing_action : ?Bool;
  };

  public type ListProposalInfoResponse = {
    proposal_info : [ProposalInfo];
  };

  public type ListKnownNeuronsResponse = {
    known_neurons : [KnownNeuron];
  };

  public type Vote = {
    #Unspecified;
    #Yes;
    #No;
  };

  public type NeuronVote = {
    proposal_id : ?ProposalId;
    vote : ?Vote;
  };

  public type ListNeuronVotesRequest = {
    neuron_id : ?NeuronId;
    before_proposal : ?ProposalId;
    limit : ?Nat64;
  };

  public type ListNeuronVotesOk = {
    votes : ?[NeuronVote];
    all_finalized_before_proposal : ?ProposalId;
  };

  public type ListNeuronVotesResponse = {
    #Ok : ListNeuronVotesOk;
    #Err : GovernanceError;
  };

  public type GetPendingProposalsRequest = {
    return_self_describing_action : ?Bool;
  };

  public type NeuronsFundEconomics = {
    // Simplified — we don't need the full structure
  };

  public type VotingPowerEconomics = {
    start_reducing_voting_power_after_seconds : ?Nat64;
    clear_following_after_seconds : ?Nat64;
    neuron_minimum_dissolve_delay_to_vote_seconds : ?Nat64;
  };

  public type NetworkEconomics = {
    neuron_minimum_stake_e8s : Nat64;
    max_proposals_to_keep_per_topic : Nat32;
    neuron_management_fee_per_proposal_e8s : Nat64;
    reject_cost_e8s : Nat64;
    transaction_fee_e8s : Nat64;
    neuron_spawn_dissolve_delay_seconds : Nat64;
    minimum_icp_xdr_rate : Nat64;
    maximum_node_provider_rewards_e8s : Nat64;
    neurons_fund_economics : ?NeuronsFundEconomics;
    voting_power_economics : ?VotingPowerEconomics;
  };

  public type NeuronSubsetMetrics = {};

  public type GovernanceCachedMetrics = {
    total_maturity_e8s_equivalent : Nat64;
    not_dissolving_neurons_e8s_buckets : [(Nat64, Float)];
    dissolving_neurons_staked_maturity_e8s_equivalent_sum : Nat64;
    garbage_collectable_neurons_count : Nat64;
    dissolving_neurons_staked_maturity_e8s_equivalent_buckets : [(Nat64, Float)];
    neurons_with_invalid_stake_count : Nat64;
    not_dissolving_neurons_count_buckets : [(Nat64, Nat64)];
    ect_neuron_count : Nat64;
    total_supply_icp : Nat64;
    neurons_with_less_than_6_months_dissolve_delay_count : Nat64;
    dissolved_neurons_count : Nat64;
    community_fund_total_maturity_e8s_equivalent : Nat64;
    total_staked_e8s_seed : Nat64;
    total_staked_maturity_e8s_equivalent_ect : Nat64;
    total_staked_e8s : Nat64;
    not_dissolving_neurons_count : Nat64;
    total_locked_e8s : Nat64;
    neurons_fund_total_active_neurons : Nat64;
    total_voting_power_non_self_authenticating_controller : ?Nat64;
    total_staked_maturity_e8s_equivalent : Nat64;
    not_dissolving_neurons_e8s_buckets_ect : [(Nat64, Float)];
    total_staked_e8s_ect : Nat64;
    not_dissolving_neurons_staked_maturity_e8s_equivalent_sum : Nat64;
    dissolved_neurons_e8s : Nat64;
    total_staked_e8s_non_self_authenticating_controller : ?Nat64;
    dissolving_neurons_e8s_buckets_seed : [(Nat64, Float)];
    neurons_with_less_than_6_months_dissolve_delay_e8s : Nat64;
    not_dissolving_neurons_staked_maturity_e8s_equivalent_buckets : [(Nat64, Float)];
    dissolving_neurons_count_buckets : [(Nat64, Nat64)];
    dissolving_neurons_e8s_buckets_ect : [(Nat64, Float)];
    dissolving_neurons_count : Nat64;
    dissolving_neurons_e8s_buckets : [(Nat64, Float)];
    total_staked_maturity_e8s_equivalent_seed : Nat64;
    community_fund_total_staked_e8s : Nat64;
    not_dissolving_neurons_e8s_buckets_seed : [(Nat64, Float)];
    timestamp_seconds : Nat64;
    seed_neuron_count : Nat64;
    spawning_neurons_count : Nat64;
    total_maturity_disbursements_in_progress_e8s_equivalent : Nat64;
    non_self_authenticating_controller_neuron_subset_metrics : ?NeuronSubsetMetrics;
    public_neuron_subset_metrics : ?NeuronSubsetMetrics;
    declining_voting_power_neuron_subset_metrics : ?NeuronSubsetMetrics;
    fully_lost_voting_power_neuron_subset_metrics : ?NeuronSubsetMetrics;
  };

  public type Result_NeuronInfo = {
    #Ok : NeuronInfo;
    #Err : GovernanceError;
  };

  public type Result_Metrics = {
    #Ok : GovernanceCachedMetrics;
    #Err : GovernanceError;
  };

  // Actor interface for the governance canister (query methods only)
  public type GovernanceActor = actor {
    list_proposals : shared query (ListProposalInfoRequest) -> async ListProposalInfoResponse;
    get_proposal_info : shared query (Nat64) -> async ?ProposalInfo;
    get_neuron_info : shared query (Nat64) -> async Result_NeuronInfo;
    list_known_neurons : shared query () -> async ListKnownNeuronsResponse;
    list_neuron_votes : shared query (ListNeuronVotesRequest) -> async ListNeuronVotesResponse;
    get_pending_proposals : shared query (?GetPendingProposalsRequest) -> async [ProposalInfo];
    get_metrics : shared query () -> async Result_Metrics;
    get_network_economics_parameters : shared query () -> async NetworkEconomics;
  };
};
