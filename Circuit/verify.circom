pragma circom 2.0.0;

include "./mimc7.circom";
include "./commitment_hash.circom";

template Verify() {
    // root, nullifierhash are provided by proover
    //these are kind of public inputs, will be filled by events emitted during storing the commitemnt
    signal input root;   //hash of the root
    signal input nullifierHash; //H(k)
    
//inputs provided for verifying 
    signal input secret[256];
    signal input nullifier[256];
    signal input hashPairings[10];
    signal input hashDirections[10];

    // check if the public variable (submitted) nullifierHash is equal to the output 
    // from hashing secret and nullifier
    component cHasher = CommitmentHasher();
    cHasher.secret <== secret;
    cHasher.nullifier <== nullifier;
    cHasher.nullifierHash === nullifierHash;  //check for correct nullifier hash


    // checking merkle tree hash path
    component leafHashers[10];

    signal currentHash[10 + 1];
    currentHash[0] <== cHasher.commitment;

    signal left[10];
    signal right[10];
//computation of root hash based on the input and compare from root
    for(var i = 0; i < 10; i++){
        var d = hashDirections[i];

        leafHashers[i] = MiMC7Sponge(2);

        left[i] <== (1 - d) * currentHash[i];
        leafHashers[i].ins[0] <== left[i] + d * hashPairings[i];

        right[i] <== d * currentHash[i];
        leafHashers[i].ins[1] <== right[i] + (1 - d) * hashPairings[i];

        leafHashers[i].k <== cHasher.commitment;
        currentHash[i + 1] <== leafHashers[i].o;
    }

    root === currentHash[10];



}

component main {public [root, nullifierHash]} = Verify();