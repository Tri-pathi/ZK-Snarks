# Task
Write a circom circuit that verifies a merkle proof. Deploy the solidity generated verifier on-chain. Write a quick script that demos that this works



## Approach

As I researched about how circuit's logic work with solidity verifier contract and send/retrieve data from the merkle tree.
In order to grasp the good understanding I went through these resources

1) Testing/understand current live zk based protocols which uses zk-snark eg cryptomixers, polygonId etc

2) picked a protocol (Tornado cash since it is pretty famous) and read the documentation and decided to implement this from scratch

In simple terms from the perspective of zk `It's a protocol which deposits assets in fixed denomination using a trusted random value secret(k) and nullifer. Further the deposit asset can be withdrawn by anyone who know the vaule of secret and nullifier. Here zk-snark comes in a user can verify that he knows the secret and nullifier without revealing to verifer`
 
 I found a video playlist which helped me in the implementation of the tornado cash also these were some helpful blogs

so the steps are
1) input values(secret and nullifier) go in different type of hasing i.e in pedersen or MIMC . 

2) nullifier hash is calculated by pedersen hash H(k) which is used to be stored in the storage and work as nonce for the one deposit-withdrawl

3) Hash of secret key + nullifier is calculated using MIMC which is stored in leaf node of merkle tree of height 20. Hence max number of deposits will be same as numbner of leaf nodes in the tree

4) Further this nullifier hash and path of root node  from leaf node used in validity of proof during withdrawal

     ////////DEPOSITED///////////////////////////

5) To solve front run issue of txn , a receiver address is used 

6) A zkey and verifying key is generated from Gro16(a trusted setup with powersoftau ceremony) by contributing some randomness(entropy) for above described deposit. Now anyone who knows the secret and nullifier can provide zk proof for withdrawing the deposits

 https://www.youtube.com/watch?v=-sXaP8Iaaq4&list=PL_SqG412uYVYtEM8B8xNccFyhrGsMV1MG

 https://medium.com/@VitalikButerin/quadratic-arithmetic-programs-from-zero-to-hero-f6d558cea649

 https://www.zeroknowledgeblog.com/index.php/groth16
 .https://link.springer.com/chapter/10.1007/978-3-662-49896-5_11

 https://iden3-docs.readthedocs.io/en/latest/iden3_repos/research/publications/zkproof-standards-workshop-2/pedersen-hash/pedersen.html

 


After implementing the minimal level of tornado cash I'm moving to our task


To make it simple and understandable I have tried to add comments everywhere 

1) Write a circom circuit - A MIMC hasher of power 7

2) that verifies a merkle proof- I have taken merkle tree of height 5

3) Verifier contract- a verifier contract deployed on polygon

In short i'm going to solve that a Address(Alice) sent a message `m` in the contract whoose hash is gonna to be store in leaf node of merkle tree and further any fresh address(who don't have anylinks with Alice) can proove that he knows the the value m and get some predefined output for this work



```solidity

/**
   The contract maintains only these states in contract:

   - Merkle root (32 bytes): The root hash of the Merkle tree.
   - Next (a uint): Indicates where the next input will be stored in the Merkle tree.
   - MerkleProof(next): A list of hashes from the leaf to the root of the Merkle tree.
   - Mapping(Hash=>true): Indicates the requirement for input not used earlier.
*/

```

USERFLOW

1)  - Alice selects two random values, `n`and `k`, ensuring they fall under the prime field specified in EIP

    -computes the hashes `H(k||n)` and `H(k)` [(32 bytes)] using the Pedersen Hasher and MIMC7 hasher

2)  - H(k||n) and MerkleProof(next) will be sent to the contract. 

    - Contract will use H(k||n) and previous store Merkleproof() to compute the update merkle root

3)  - The contract verifies the validity of the provided Merkle proof.
    - If the proof is valid, the contract updates its state; otherwise, it reverts to the previous state


4)  A verifier submit a zk roof that he knows the value n and k for which we have mapping(H(k)==false) and H(k||n) present in leaf node of merkle tree

  - public statement is something like Fresh Address have x=(root,H(k))
   and secret witness w=(k',n', Hash, MerkleProof(leaFNode))

  - Circuit(x,w)=0 iff 

     - Hash is one of the leaf node
     - Hash =H(k'||n')
     - H(k)=H(k')
Now depend upon the proof Verified or InValid Proof


For the purpose of demonstration, simplified solutions based on a single random value can be designed and implemented. Here I have tried to keeo as simple as possible while covering all the important logics

## Test

### STORE Flow
Clone the repository and compile the `store.circom` file to generate WebAssembly

```bash
circom store.circom --r1cs --wasm 
```
This will generate web assembly which can be run through browser

Now

Create a `input.json` and gGenerate two random values and calculate the witness values (commitment hash and nullifier hash)(I have used ethers utilities present in backend/utils)  in the form of `witness.wtns`
```bash
node ./store_js/generate_witness.js ./store_js/store.wasm  input.json witness.wtns
```
Export the witness file to a readable JSON format by snarksjs( install globally first)

```bash
snarkjs wtns export json witness.wtns witness.json
```
Second and Third element is our commitmenthash and nullifier hash respectively 

Now , just Call the `store(commitment)` function from `ZKPStore.sol` to store the data on the smart contract


### GRO16 Setup

#### Ceremony Setup - Phase 1

Make sure `snarkjs` is installed globally. Set up the powers of tau ceremony:

```bash
snarkjs powersoftau new bn128 12 ceremony_0000.ptau -v
```
`bn128` elliptic curve is used in this setup and nd 12 is max number of constraints. For more information check github page of snarkjs


This will generate a `ceremony_0000.ptau` file, where we need to contribute some entropy(as many you want)

```bash
snarkjs powersoftau contribute ceromony_0000.ptau ceremony_0001.ptau
```
input any random string/text/number.Repeat this process multiple times and after enough entropy prepare for phase2.

It is advised to verify the correctness of ceramony by

```
snarkjs powersoftau verify ceremany_000x.ptau
```

output should be a log `Powers Of tau file OK!`
#### Ceremony Setup - Phase 2

```bash
snarkjs powersoftau prepare phase2 ceremony_000x.ptau ceremony_final.ptau
```
Compile the circuit into R1CS and generate a ZKey:

```bash
snarkjs growth16 setup circuit.r1cs ceremony_000x.ptau setup_0000.zkey

```
Documentation says we could use this zkey but contributing entropy is always better so in case if someone wants to contribute entropy it can be performed in same the way as described above

compile `verify.circom` and generate proof

```bash
snarkjs groth16 fullprove input.json verify_js/verify.wasm setup_0000.zkey proof.json public.json
```

WOOAAHHH we have proof now. To verify the proof on-chain, call the `verify()` function in `ZKPStore.sol`. This function uses the verifier contract generated from snarkjs growth16 setup on verify.r1cs













