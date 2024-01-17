//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./MIMC7Hasher.sol";

interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    ) external;
}

contract ZKPStore {
    error ALREADYSTOREDCOMMITEMENT();
    error MerkleTreeIsFull();

    error AlreadyProved();
    error NotRoot();

    event Stored(
        uint256 merkleroot,
        uint256[5] hashPairings,
        uint8[5] pairDirection
    );
    event Verified(address to, uint256 nullifierHash);

    address gro16Verifer;
    address mimc7Hasher;

    uint256 public immutable treeLevel;
    uint256 public next;

    mapping(uint256 => bool) public merkleRoot;
    mapping(uint8 => uint256) lastLevelHash;
    mapping(uint256 => bool) public nullifierHashes;
    mapping(uint256 => bool) public commitments;
    uint256[5] levelDefaults = [
        23183772226880328093887215408966704399401918833188238128725944610428185466379,
        24000819369602093814416139508614852491908395579435466932859056804037806454973,
        90767735163385213280029221395007952082767922246267858237072012090673396196740,
        36838446922933702266161394000006956756061899673576454513992013853093276527813,
        68942419351509126448570740374747181965696714458775214939345221885282113404505
    ];

    constructor(address _hasher, address Verfier) {
        mimc7Hasher = _hasher; // solidity version of mimc7 circuit
        treeLevel = 5;
        gro16Verifer = Verfier; // setup for verifying the zk-snark proof
    }

    //this will store the commitment hash in the next leaf node and prepare the merkle tree for storing next value
    function store(uint256 _commitment) external {
        //A commitement hash could be used only once  i.e PedersenHash(k||n) a unique (k||n)
        if (!commitments[_commitment]) {
            revert ALREADYSTOREDCOMMITEMENT();
        }
        //number of max commitements used= numeber of leaf nodes
        if (next >= 2 ** treeLevel) {
            revert MerkleTreeIsFull();
        }
        uint256 newRoot;
        uint256[5] memory hashPairings; //hash of sister node
        uint8[5] memory hashDirections; //sign that will tell us which hash direction we should include to reach the root

        uint256 currentIdx = next; //current pointer where we are going to store the commitmenthASH
        uint256 currentHash = _commitment;

        uint256 left;
        uint256 right;
        uint256[2] memory ins;

        for (uint8 i = 0; i < treeLevel; i++) {
            if (currentIdx % 2 == 0) {
                //EVEN SHOWS LEFT NODE IN A COMPLETE BINARY TREE
                left = currentHash;
                right = levelDefaults[i];
                hashPairings[i] = levelDefaults[i];
                hashDirections[i] = 0;
            } else {
                left = lastLevelHash[i];
                right = currentHash;
                hashPairings[i] = lastLevelHash[i];
                hashDirections[i] = 1;
            }
            lastLevelHash[i] = currentHash;

            ins[0] = left;
            ins[1] = right;

            uint256 h = 0;
            MIMC7Hasher(mimc7Hasher).MiMC7Sponge(ins, _commitment);

            currentHash = h;
            currentIdx = currentIdx / 2;
        }

        newRoot = currentHash;
        merkleRoot[newRoot] = true;
        next = next + 1;

        commitments[_commitment] = true; //commitement has been used
        emit Stored(newRoot, hashPairings, hashDirections); //this logs is used in contruction of proof
    }

    //proof is based on trusted gro16 setup where first we neeed to generate zkey by contributing entropy using snarks powersoftau
    function verify(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    ) external {
        uint256 _root = input[0];
        uint256 _nullifierHash = input[1];

        if (nullifierHashes[_nullifierHash]) {
            revert AlreadyProved();
        }

        if (!merkleRoot[_root]) {
            revert NotRoot();
        }

        (bool verifyOK, ) = gro16Verifer.call(
            abi.encodeCall(
                IVerifier.verifyProof,
                (a, b, c, [_root, _nullifierHash])
            )
        );

        require(verifyOK, "invalid-proof");

        nullifierHashes[_nullifierHash] = true; //nonce

        emit Verified(msg.sender, _nullifierHash);
    }
}
