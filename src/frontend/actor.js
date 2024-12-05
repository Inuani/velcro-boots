import { HttpAgent, Actor } from "@dfinity/agent";

const canisterId = process.env.CANISTER_ID_VELCRO_BOOT;
const host = process.env.DFX_NETWORK === "ic" 
  ? "https://ic0.app"
  : "http://localhost:4943";


const idlFactory = ({ IDL }) => {
  return IDL.Service({
    whoAmI: IDL.Func([], [IDL.Principal], ["query"]),
    get_cycle_balance: IDL.Func([], [IDL.Nat], ["query"])
  });
};

const createActor = (options = {}) => {
  const agent = new HttpAgent({
    host,
    ...options
  });
  
  // only fetch root key in local dev
  if (process.env.DFX_NETWORK !== "ic") {
    agent.fetchRootKey().catch(console.error);
  }
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
  });
};

export const actor = createActor();
export const updateActorIdentity = (identity) => {
  return createActor({ identity });
};