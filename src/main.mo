import Result "mo:base/Result";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Time "mo:base/Time";
import HttpTypes "mo:http-types";
import Map "mo:map/Map";

import AuthCleanup "mo:mcp-motoko-sdk/auth/Cleanup";
import AuthTypes "mo:mcp-motoko-sdk/auth/Types";

import Mcp "mo:mcp-motoko-sdk/mcp/Mcp";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import HttpHandler "mo:mcp-motoko-sdk/mcp/HttpHandler";
import Cleanup "mo:mcp-motoko-sdk/mcp/Cleanup";
import State "mo:mcp-motoko-sdk/mcp/State";
import Payments "mo:mcp-motoko-sdk/mcp/Payments";
import HttpAssets "mo:mcp-motoko-sdk/mcp/HttpAssets";
import Beacon "mo:mcp-motoko-sdk/mcp/Beacon";
import ApiKey "mo:mcp-motoko-sdk/auth/ApiKey";

import SrvTypes "mo:mcp-motoko-sdk/server/Types";

// Import tool modules
import ToolContext "tools/ToolContext";
import ListProposals "tools/list_proposals";
import GetProposal "tools/get_proposal";
import GetNeuronInfo "tools/get_neuron_info";
import ListKnownNeurons "tools/list_known_neurons";
import GetNeuronVotes "tools/get_neuron_votes";
import GetPendingProposals "tools/get_pending_proposals";
import GetGovernanceMetrics "tools/get_governance_metrics";
import GetNetworkEconomics "tools/get_network_economics";

// Import governance types
import GovernanceTypes "GovernanceTypes";

shared ({ caller = deployer }) persistent actor class McpServer(
  args : ?{
    owner : ?Principal;
  }
) = self {

  // The canister owner
  var owner : Principal = Option.get(do ? { args!.owner! }, deployer);

  // NNS Governance canister actor reference
  let GOVERNANCE_CANISTER_ID = "rrkah-fqaaa-aaaaa-aaaaq-cai";
  let governance : GovernanceTypes.GovernanceActor = actor (GOVERNANCE_CANISTER_ID);

  // State for certified HTTP assets
  var stable_http_assets : HttpAssets.StableEntries = [];
  transient let http_assets = HttpAssets.init(stable_http_assets);

  // Resource contents (none needed for this server)
  var resourceContents : [(Text, Text)] = [];

  // The application context
  var appContext : McpTypes.AppContext = State.init(resourceContents);

  // No authentication needed — all tools are public
  transient let authContext : ?AuthTypes.AuthContext = null;

  // --- Beacon ---
  let beaconCanisterId = Principal.fromText("m63pw-fqaaa-aaaai-q33pa-cai");
  transient let beaconContext : ?Beacon.BeaconContext = ?Beacon.init(
    beaconCanisterId,
    ?(15 * 60), // every 15 minutes
  );

  // --- Timers ---
  Cleanup.startCleanupTimer<system>(appContext);

  switch (authContext) {
    case (?ctx) { AuthCleanup.startCleanupTimer<system>(ctx) };
    case (null) { Debug.print("Authentication is disabled.") };
  };

  switch (beaconContext) {
    case (?ctx) { Beacon.startTimer<system>(ctx) };
    case (null) { Debug.print("Beacon is disabled.") };
  };

  // --- Tool Context ---
  transient let toolContext : ToolContext.ToolContext = {
    canisterPrincipal = Principal.fromActor(self);
    owner = owner;
    appContext = appContext;
    governance = governance;
  };

  // --- Resources (none) ---
  transient let resources : [McpTypes.Resource] = [];

  // --- Tools ---
  transient let tools : [McpTypes.Tool] = [
    ListProposals.config(),
    GetProposal.config(),
    GetNeuronInfo.config(),
    ListKnownNeurons.config(),
    GetNeuronVotes.config(),
    GetPendingProposals.config(),
    GetGovernanceMetrics.config(),
    GetNetworkEconomics.config(),
  ];

  // --- MCP Config ---
  transient let mcpConfig : McpTypes.McpConfig = {
    self = Principal.fromActor(self);
    allowanceUrl = null;
    serverInfo = {
      name = "nns-governance-explorer";
      title = "NNS Governance Explorer";
      version = "0.1.0";
    };
    resources = resources;
    resourceReader = func(uri) {
      Map.get(appContext.resourceContents, Map.thash, uri);
    };
    tools = tools;
    toolImplementations = [
      ("list_proposals", ListProposals.handle(toolContext)),
      ("get_proposal", GetProposal.handle(toolContext)),
      ("get_neuron_info", GetNeuronInfo.handle(toolContext)),
      ("list_known_neurons", ListKnownNeurons.handle(toolContext)),
      ("get_neuron_votes", GetNeuronVotes.handle(toolContext)),
      ("get_pending_proposals", GetPendingProposals.handle(toolContext)),
      ("get_governance_metrics", GetGovernanceMetrics.handle(toolContext)),
      ("get_network_economics", GetNetworkEconomics.handle(toolContext)),
    ];
    beacon = beaconContext;
  };

  // --- Create Server ---
  transient let mcpServer = Mcp.createServer(mcpConfig);

  // --- PUBLIC ENTRY POINTS ---

  public query func get_owner() : async Principal { return owner };

  public shared ({ caller }) func set_owner(new_owner : Principal) : async Result.Result<(), Payments.TreasuryError> {
    if (caller != owner) { return #err(#NotOwner) };
    owner := new_owner;
    return #ok(());
  };

  public shared func get_treasury_balance(ledger_id : Principal) : async Nat {
    return await Payments.get_treasury_balance(Principal.fromActor(self), ledger_id);
  };

  public shared ({ caller }) func withdraw(
    ledger_id : Principal,
    amount : Nat,
    destination : Payments.Destination,
  ) : async Result.Result<Nat, Payments.TreasuryError> {
    return await Payments.withdraw(caller, owner, ledger_id, amount, destination);
  };

  // --- HTTP Handlers ---

  private func _create_http_context() : HttpHandler.Context {
    return {
      self = Principal.fromActor(self);
      active_streams = appContext.activeStreams;
      mcp_server = mcpServer;
      streaming_callback = http_request_streaming_callback;
      auth = authContext;
      http_asset_cache = ?http_assets.cache;
      mcp_path = ?"/mcp";
    };
  };

  public query func http_request(req : SrvTypes.HttpRequest) : async SrvTypes.HttpResponse {
    let ctx : HttpHandler.Context = _create_http_context();
    switch (HttpHandler.http_request(ctx, req)) {
      case (?mcpResponse) { return mcpResponse };
      case (null) {
        if (req.url == "/") {
          return {
            status_code = 200;
            headers = [("Content-Type", "text/html")];
            body = Text.encodeUtf8("<h1>NNS Governance Explorer</h1><p>Connect via MCP at /mcp</p>");
            upgrade = null;
            streaming_strategy = null;
          };
        } else {
          return {
            status_code = 404;
            headers = [];
            body = Blob.fromArray([]);
            upgrade = null;
            streaming_strategy = null;
          };
        };
      };
    };
  };

  public shared func http_request_update(req : SrvTypes.HttpRequest) : async SrvTypes.HttpResponse {
    let ctx : HttpHandler.Context = _create_http_context();
    let mcpResponse = await HttpHandler.http_request_update(ctx, req);
    switch (mcpResponse) {
      case (?res) { return res };
      case (null) {
        return {
          status_code = 404;
          headers = [];
          body = Blob.fromArray([]);
          upgrade = null;
          streaming_strategy = null;
        };
      };
    };
  };

  public query func http_request_streaming_callback(token : HttpTypes.StreamingToken) : async ?HttpTypes.StreamingCallbackResponse {
    let ctx : HttpHandler.Context = _create_http_context();
    return HttpHandler.http_request_streaming_callback(ctx, token);
  };

  // --- Lifecycle ---

  system func preupgrade() {
    stable_http_assets := HttpAssets.preupgrade(http_assets);
  };

  system func postupgrade() {
    HttpAssets.postupgrade(http_assets);
  };

  // --- API Key System ---

  public shared (msg) func create_my_api_key(name : Text, scopes : [Text]) : async Text {
    switch (authContext) {
      case (null) { Debug.trap("Authentication is not enabled on this canister.") };
      case (?ctx) { return await ApiKey.create_my_api_key(ctx, msg.caller, name, scopes) };
    };
  };

  public shared (msg) func revoke_my_api_key(key_id : Text) : async () {
    switch (authContext) {
      case (null) { Debug.trap("Authentication is not enabled on this canister.") };
      case (?ctx) { return ApiKey.revoke_my_api_key(ctx, msg.caller, key_id) };
    };
  };

  public query (msg) func list_my_api_keys() : async [AuthTypes.ApiKeyMetadata] {
    switch (authContext) {
      case (null) { Debug.trap("Authentication is not enabled on this canister.") };
      case (?ctx) { return ApiKey.list_my_api_keys(ctx, msg.caller) };
    };
  };

  public type UpgradeFinishedResult = {
    #InProgress : Nat;
    #Failed : (Nat, Text);
    #Success : Nat;
  };

  private func natNow() : Nat { return Int.abs(Time.now()) };

  public func icrc120_upgrade_finished() : async UpgradeFinishedResult {
    #Success(natNow());
  };
};
