const { ethers } = require("ethers");
const { readFileSync, writeFile } = require("fs");
async function storeInputsetup() {
 
  //first get some random values for secret and nullifer
  const secretN = ethers.BigNumber.from(
    ethers.utils.randomBytes(32)
  ).toString();
  const nulliferK = ethers.BigNumber.from(
    ethers.utils.randomBytes(32)
  ).toString();
  console.log(secretN);
  console.log(nulliferK);

  //As we need input in the form of binary hence

  let n = BigInt(secretN).toString(2); //converting into binary
  let k = BigInt(nulliferK).toString(2);

  // we have to pass input of 256 bits so let's do some padding if necessary
  let prePaddingN = "";
  let prePaddingK = "";

  for (var i = 0; i < 256 - n.length || 256 - k.length; i++) {
    if (i < 256 - n.length) {
      prePaddingN += "0";
    }
    if (i < 256 - k.length) {
      prePaddingK += "0";
    }
  }

  n = prePaddingN + n;
  k = prePaddingK + k;

  const input = {
    secret: n.split(""),
    nullifier: k.split(""),
  };

  console.log(input);

}

storeInputsetup().catch((error) => {
  console.log(error);
  process.exit(1);
});
