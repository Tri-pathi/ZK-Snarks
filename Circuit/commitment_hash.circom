pragma circom  2.0.0;

include "./pedersen.circom";

template CommitmentHasher(){
   
   signal input secret[256];
   signal input nullifier[256];
   signal output commitment;  // this will be saved in leaf node of merkle tree and we will need this hash during verification 
   signal output nullifierHash; // every time a wuthdrawl is completed this hash is marked as completed i.e same as nonce


 component cHasher = Pedersen(512);
    component nHasher = Pedersen(256);

    for(var i = 0; i < 256; i++){
        cHasher.in[i] <== nullifier[i];
        cHasher.in[i + 256] <== secret[i];
        nHasher.in[i] <== nullifier[i];
    }

    commitment <== cHasher.o;
    nullifierHash <== nHasher.o;
}