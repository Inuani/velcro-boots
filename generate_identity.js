const { Ed25519KeyIdentity } = require("@dfinity/identity");
const crypto = require('crypto');
const fs = require("fs");

// to use only once
const seed = crypto.randomBytes(32);
const identity = Ed25519KeyIdentity.generate(seed);
fs.writeFileSync('identity.json', JSON.stringify(seed.toString('hex')));

console.log('Principal:', identity.getPrincipal().toText());