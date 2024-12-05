require('dotenv').config();
const { HttpAgent } = require("@dfinity/agent");
const fs = require("fs");
const path = require("path");
const { Ed25519KeyIdentity } = require("@dfinity/identity");
const { AssetManager } = require("@dfinity/assets");
const { spawn } = require("child_process");

const seedHex = fs.readFileSync('identity.json', 'utf8');
const seed = Buffer.from(JSON.parse(seedHex), 'hex');
const generatedIdentity = Ed25519KeyIdentity.generate(seed);

const canisterId = process.env.CANISTER_ID_VELCRO_BOOT;
const isIc = process.env.DFX_NETWORK === 'ic';
const HOST = isIc ? "https://ic0.app" : "http://127.0.0.1:4943";

console.log("Authorizing identity...");
const dfxArgs = ["canister"];
if (isIc) dfxArgs.push("--network", "ic");
dfxArgs.push(
  "call",
  "velcro_boot",
  "authorize",
  `(principal "${generatedIdentity.getPrincipal().toText()}")`
);

const child = spawn("dfx", dfxArgs);

child.stdout.on("data", (data) => {
  console.log(`Authorization success: ${data}`);
});

child.stderr.on("data", (data) => {
  console.error(`Authorization error: ${data}`);
});

child.on("close", (code) => {
  if (code === 0) {
    uploadAssets();
  }
});

async function uploadAssets() {
  const agent = new HttpAgent({
    host: HOST,
    identity: generatedIdentity
  });

  if (!isIc) {
    await agent.fetchRootKey();
  }

  const assetManager = new AssetManager({
    canisterId,
    agent,
  });

  console.log(`Clearing data...`);
  await assetManager.clear();

  const assets = [];

  // const staticPath = path.join(__dirname, "src/static");
  // if (fs.existsSync(staticPath)) {
  //   fs.readdirSync(staticPath).forEach((file) => {
  //     assets.push([file, fs.readFileSync(path.join(staticPath, file))]);
  //   });
  // }

  // const publicPath = path.join(__dirname, "src/frontend/public");
  // if (fs.existsSync(publicPath)) {
  //   fs.readdirSync(publicPath).forEach((file) => {
  //     assets.push([file, fs.readFileSync(path.join(publicPath, file))]);
  //   });
  // }

  // fs.readdirSync(path.join(__dirname, "src/frontend/public")).forEach((file) => {
  //   assets.push([file, fs.readFileSync(path.join(__dirname, "src/frontend/public", file))]);
  // });

  // console.log(`Uploading ${assets.length} files...`);
  
  // for (const [name, file] of assets) {
  //   const key = await assetManager.store(file, { fileName: name });
  //   const asset = await assetManager.get(key);
  //   console.log(`Uploaded ${name}, size: ${asset.length} bytes`);
  // }
}