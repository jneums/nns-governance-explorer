import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import McpTypes "mo:mcp-motoko-sdk/mcp/Types";
import Json "mo:json";

import GovernanceTypes "../GovernanceTypes";

module ToolContext {

  /// Context shared between tools and the main canister
  public type ToolContext = {
    /// The principal of the canister
    canisterPrincipal : Principal;
    /// The owner of the canister
    owner : Principal;
    /// The application context from the MCP SDK
    appContext : McpTypes.AppContext;
    /// The governance canister actor for cross-canister calls
    governance : GovernanceTypes.GovernanceActor;
  };

  /// Helper function to create an error response
  public func makeError(message : Text, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) {
    cb(#ok({ content = [#text({ text = "Error: " # message })]; isError = true; structuredContent = null }));
  };

  /// Helper function to create a success response with structured JSON
  public func makeSuccess(structured : Json.Json, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) {
    cb(#ok({ content = [#text({ text = Json.stringify(structured, null) })]; isError = false; structuredContent = ?structured }));
  };

  /// Helper function to create a success response with plain text
  public func makeTextSuccess(text : Text, cb : (Result.Result<McpTypes.CallToolResult, McpTypes.HandlerError>) -> ()) {
    cb(#ok({ content = [#text({ text = text })]; isError = false; structuredContent = null }));
  };

  /// Format a Nat64 timestamp (seconds) to ISO 8601 string
  public func formatTimestamp(seconds : Nat64) : Text {
    let s = seconds;
    if (s == 0) return "N/A";
    // Simple formatting: return as seconds since epoch
    // (Full ISO formatting would need a datetime library)
    Nat64.toText(s);
  };

  /// Format an optional Nat64 timestamp
  public func formatOptTimestamp(seconds : ?Nat64) : ?Text {
    switch (seconds) {
      case (?s) {
        if (s == 0) { null } else { ?Nat64.toText(s) };
      };
      case null { null };
    };
  };
};
