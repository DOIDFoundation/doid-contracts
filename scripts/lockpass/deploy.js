// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  if (true){
    const Registry = await hre.ethers.getContractFactory('PassRegistry')
    const proxy = await upgrades.upgradeProxy("0x9281fD776D35f518B877D726e6a30eff1c7775E9", Registry)
    //const proxy = await upgrades.forceImport("0x208ec0Ef36E94F582841296dcA6F6B61d5823fBE", Registry)
    console.log("upgrade proxy", proxy.address)
    await proxy.deployed()
    await hre.run('verify:verify', {
      address: proxy.address,
    })
    return
  }
  if(false){
   const proxy = await hre.ethers.getContractAt('PassRegistry', "0x208ec0Ef36E94F582841296dcA6F6B61d5823fBE")
   //await proxy.setDoidRegistry("0x24256dab379962842691eb8bce11f2b5032bf1b6")
   //await proxy.claimDoid(100)

  // await proxy.updatePassIdStart(150)
//
//  //await proxy.lockPass(sig, "bob", "A")
//  const sig1 = ethers.utils.toUtf8Bytes("0x01debac705ebed9d2b48316e65889af05e263bec986b9fc238febcc913f38c3b31549fcfbebead15b496bf777e289f82a113282d4a7334617c40c5bd967a020a1c")
//  console.log(await proxy.estimateGas.lockPass(ethers.utils.arrayify("0x01debac705ebed9d2b48316e65889af05e263bec986b9fc238febcc913f38c3b31549fcfbebead15b496bf777e289f82a113282d4a7334617c40c5bd967a020a1c"), "bob", "A"))
  return
  }
  const accounts = await hre.ethers.getSigners()
  admin = accounts[0]
  console.log("admin:", admin.address)

  const Registry = await hre.ethers.getContractFactory('PassRegistry')
  const reg = await upgrades.deployProxy(Registry, [admin.address, "DOID Lock Pass", "PASS"])
  await reg.deployed()

  console.log(
    `✅deploy passRegistry ${reg.address}`
  );

  console.log(
    'implementation',
    await upgrades.erc1967.getImplementationAddress(reg.address),
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
