import Server "mo:server";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
// import Nat16 "mo:base/Nat16";
import Assets "mo:assets";
import T "mo:assets/Types";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Debug "mo:base/Debug";

import Scan "scan";

shared ({ caller = creator }) actor class () {
  type Request = Server.Request;
  type Response = Server.Response;
  type HttpRequest = Server.HttpRequest;
  type HttpResponse = Server.HttpResponse;
  type ResponseClass = Server.ResponseClass;

  stable var serializedEntries : Server.SerializedEntries = ([], [], [creator]);

  stable var scan_count : Nat = 0;

  var server = Server.Server({ serializedEntries });

  public query ({ caller }) func whoAmI() : async Principal {
    return caller;
};

public query func get_cycle_balance() : async Nat {
  return Cycles.balance();
};



  server.get(
    "/404",
    func(_ : Request, res : ResponseClass) : async Response {
      res.send({
        status_code = 404;
        headers = [("Content-Type", "text/plain")];
        body = Text.encodeUtf8("Not found");
        streaming_strategy = null;
        cache_strategy = #noCache;
      });
    },
  );



   let assets = server.assets;

   public query func listAuthorized() : async [Principal] {
    server.entries().2
  };

  public shared({ caller }) func deauthorize(other: Principal) : async () {
  assert(caller == creator);
  let (urls, patterns, authorized) = server.entries();
  let filtered = Array.filter<Principal>(
    authorized, 
    func(p) { p != other }
  );
  serializedEntries := (urls, patterns, filtered);
  server := Server.Server({ serializedEntries });
};

//  public shared({ caller }) func authorize(other: Principal) : async () {
//  assert(caller == creator);
 
//  // Check if already authorized
//  switch(Array.find<Principal>(server.authorized, func(p) { p == other })) {
//    case null {
//      // Not authorized yet, add it
//      server.authorize({ caller; other });
//    };
//    case (?_) {}; // Already authorized, do nothing
//  };
// };

  public shared ({ caller }) func authorize(other : Principal) : async () {
    server.authorize({ caller; other });
  };

  public query func retrieve(path : Assets.Path) : async Assets.Contents {
    assets.retrieve(path);
  };

  public shared ({ caller }) func store(
    arg : {
      key : Assets.Key;
      content_type : Text;
      content_encoding : Text;
      content : Blob;
      sha256 : ?Blob;
    }
  ) : async () {
    server.store({ caller; arg });
  };


  // Bind the server to the HTTP interface
  // public query func http_request(req : HttpRequest) : async HttpResponse {
  //   server.http_request(req);
  // };

// public query func http_request(req : HttpRequest) : async HttpResponse {

//      if (req.url == "/velcro_boot.webp" or req.url == "/bundle.js") {
//        let res =server.http_request(req);
//         return res;
//     };

//      Debug.print("____________________________________________" # Nat.toText(scan_count));

//    Debug.print("initial scan_count: " # Nat.toText(scan_count));
//     let counter = Scan.scan(req.url, scan_count);
//   Debug.print("after 1st scan scan_count:"  # Nat.toText(scan_count));
//   Debug.print("1st counter:"  # Nat.toText(counter));
    
//     let new_request = {
//       url = if (counter > 0) {
//         "/"
//       } else {
//         "/edge.html"
//       };
//       method = req.method;
//       body = req.body;
//       headers = req.headers;
//     };

//     let response = server.http_request(new_request);
  

//     return {
//       body = response.body;
//       headers = response.headers;
//       status_code = response.status_code;
//       streaming_strategy = response.streaming_strategy;
//       cache_strategy = #noCache;
//       upgrade = ?true;
//     };

//   };

//   public func http_request_update(req : HttpRequest) : async HttpResponse {

//    if (req.url == "/velcro_boot.webp" or req.url == "/bundle.js") {
//       return await server.http_request_update(req);
//    };

//       let counter = Scan.scan(req.url, scan_count);
//       Debug.print("after 2nd scan : scan_count:"  # Nat.toText(scan_count));
//       Debug.print("2nd counter:"  # Nat.toText(counter));


//     if (counter > 0) {
//       Debug.print("scan_count before incr : " # Nat.toText(scan_count));
//       scan_count := counter;
//       Debug.print("scan_count after incr : " # Nat.toText(scan_count));
//       let new_request = {
//       url = "/";
//       method = req.method;
//       body = req.body;
//       headers = req.headers;
//     };
  
//      return await server.http_request_update(new_request);
//     };

//     let new_request = {
//       url = "/edge.html";
//       method = req.method;
//       body = req.body;
//       headers = req.headers;
//     };
//      await server.http_request_update(new_request);
//   };

public query func http_request(req : HttpRequest) : async HttpResponse {
   server.http_request(req);
};

public func http_request_update(req : HttpRequest) : async HttpResponse {
 
    let static_files = ["/velcro_boot.webp", "/bundle.js"];
    if (Array.find<Text>(static_files, func(path) { path == req.url }) != null) {
        return await server.http_request_update(req);
    };

    let counter = Scan.scan(req.url, scan_count);
    let new_request = {
        url = if (counter > 0) {
            scan_count := counter; 
            "/"
        } else {
            "/edge.html"
        };
        method = req.method;
        body = req.body;
        headers = req.headers;
    };
    await server.http_request_update(new_request);
    // await server.http_request_update(req);
};

  public func invalidate_cache() : async () {
    server.empty_cache();
  };

  system func preupgrade() {
    serializedEntries := server.entries();
  };

  system func postupgrade() {
    ignore server.cache.pruneAll();
  };


public query func list(arg : {}) : async [T.AssetDetails] {
  assets.list(arg);
};

public query func get(
  arg : {
    key : T.Key;
    accept_encodings : [Text];
  }
) : async ({
  content : Blob;
  content_type : Text;
  content_encoding : Text;
  total_length : Nat;
  sha256 : ?Blob;
}) {
  assets.get(arg);
};

public shared ({ caller }) func create_batch(arg : {}) : async ({
  batch_id : T.BatchId;
}) {
  assets.create_batch({
    caller;
    arg;
  });
};

public shared ({ caller }) func create_chunk(
  arg : {
    batch_id : T.BatchId;
    content : Blob;
  }
) : async ({
  chunk_id : T.ChunkId;
}) {
  assets.create_chunk({
    caller;
    arg;
  });
};

public shared ({ caller }) func commit_batch(args : T.CommitBatchArguments) : async () {
  assets.commit_batch({
    caller;
    args;
  });
};

public shared ({ caller }) func create_asset(arg : T.CreateAssetArguments) : async () {
  assets.create_asset({
    caller;
    arg;
  });
};

public shared ({ caller }) func set_asset_content(arg : T.SetAssetContentArguments) : async () {
  assets.set_asset_content({
    caller;
    arg;
  });
};

public shared ({ caller }) func unset_asset_content(args : T.UnsetAssetContentArguments) : async () {
  assets.unset_asset_content({
    caller;
    args;
  });
};

public shared ({ caller }) func delete_asset(args : T.DeleteAssetArguments) : async () {
  assets.delete_asset({
    caller;
    args;
  });
};

public shared ({ caller }) func clear(args : T.ClearArguments) : async () {
  assets.clear({
    caller;
    args;
  });
};

public type StreamingCallbackToken = {
  key : Text;
  content_encoding : Text;
  index : Nat;
  sha256 : ?Blob;
};

public type StreamingCallbackHttpResponse = {
  body : Blob;
  token : ?StreamingCallbackToken;
};

public query func http_request_streaming_callback(token : T.StreamingCallbackToken) : async StreamingCallbackHttpResponse {
  assets.http_request_streaming_callback(token);
};


//     server.get(
//   "/balance",
//   func(_ : Request, res : ResponseClass) : async Response {
//     let balance = Nat.toText(Cycles.balance());
//     res.send({
//       status_code = 200;
//       headers = [("Content-Type", "text/plain")];
//       body = Text.encodeUtf8(balance);
//       streaming_strategy = null;
//       cache_strategy = #noCache;
//     });
//   },
// );

  // server.get(
  //   "/json",
  //   func(_ : Request, res : ResponseClass) : async Response {
  //     res.json({
  //       status_code = 200;
  //       body = "{\"hello\":\"world\"}";
  //       cache_strategy = #noCache;
  //     });
  //   },
  // );

  //   public func removeDuplicates() : async () {
//  // Use a buffer to store unique principals
//  let seen = Buffer.Buffer<Principal>(0);
 
//  for (p in server.authorized.vals()) {
//    // Only add if not already seen
//    if (Option.isNull(Array.find(Buffer.toArray(seen), func(x: Principal) : Bool { x == p }))) {
//      seen.add(p);
//    };
//  };
 
//  // Update authorized with deduplicated array
//  server.authorized := Buffer.toArray(seen);
 
//  // Recreate server with new authorized list
//  let (urls, patterns, _) = server.entries();
//  serializedEntries := (urls, patterns, server.authorized);
//  server := Server.Server({ serializedEntries });
// };

};
