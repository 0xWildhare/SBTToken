 const Token_address = 0x6480A5f804cd3A5Dd89cDe1d87DD4e8A49b14557;
 const Oracle_address = 0x450267fB9232Dc4a4240DC235f5B3d972D3aA250;
 const Shares_address = 0x4B81DE930CDC3120aBF4241DAe544945705aea16;

 //const Bonding_address = '0xF4663D4cB6d3e0bAE882c6C4b048158B29c881A9';
async function main() {

//token
  //const SBToken = await hre.ethers.getContractFactory("SBToken");
  //const token = await SBToken.attach(Token_address);
  /*
  const token = await SBToken.deploy(ethers.utils.parseEther("1000"));
  await token.deployed();
  console.log("SBToken deployed to:", token.address);
*/
//bonding
  const Bonding = await hre.ethers.getContractFactory("bondingContract");
  //const bonding = await Bonding.attach(Bonding_address);

  const bonding = await Bonding.deploy();
  await bonding.deployed();
  console.log("bondingContract deployed to:", bonding.address);
/*  
//coupon
    const Coupon = await hre.ethers.getContractFactory("couponContract");
    //const bonding = await Bonding.attach(Bonding_address);

    const coupon = await Coupon.deploy();
    await coupon.deployed();
    console.log("couponContract deployed to:", coupon.address);



//shares
  const Shares = await hre.ethers.getContractFactory("bLSD");
  const shares = await Shares.deploy();
  await shares.deployed();
  console.log("shares deployed to:", shares.address);

//oracle (mock)
  const Oracle = await hre.ethers.getContractFactory("PriceOracle");
  const oracle = await Oracle.deploy();
  await oracle.deployed();
  console.log("oracle deployed to:", oracle.address);

//set addresses for token
  //bonding
  await token.changeBondingContract(bonding.address);
  let _bonding = await token.getBondingContract();
  console.log("token - bonding address set as: ", _bonding);

//set addresses for shares
  //bonding
  await shares.setBondingContract(bonding.address);
  _bonding = await shares.getBondingContract();
  console.log("shares - bonding address set as: ", _bonding);

//set addresses for bonding
  //token
  await bonding.setToken(Token_address);
  let _token = await bonding.getToken();
  console.log("bonding - token address set as: ", _token);

  //Oracle
  await bonding.setOracle(Oracle_address);
  let _oracle = await bonding.getOracle();
  console.log("bonding - oracle address set as: ", _oracle);

  //Shares
  await bonding.setShares(Shares_address);
  let _shares = await bonding.getShares();
  console.log("bonding - shares address set as: ", _shares);

  //coupon
  await bonding.setCouponContract(0x308D7102eD770618F543724a24f7a6E0c47b7B29);
  let _coupon = await bonding.getCouponContract();
  console.log("bonding - coupon address set as: ", _coupon);
*/
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
