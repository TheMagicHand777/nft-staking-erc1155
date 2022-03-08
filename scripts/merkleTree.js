const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const giftList = require('../whitelist/whitelist.json');

const hashedAddresses = giftList.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(hashedAddresses, keccak256, { sortPairs: true });

const myAddress = "0xD6e842B844a67151D9319CFED96B39EEeC6D466f";
const hashedAddress = keccak256(myAddress);
const proof = merkleTree.getHexProof(hashedAddress);
const root = merkleTree.getHexRoot();

// just for front-end display convenience
// proof will be validated in smart contract as well
const valid = merkleTree.verify(proof, hashedAddress, root);

console.log(proof);
console.log(root);
console.log(valid);
console.log(hashedAddress);