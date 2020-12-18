
async function main() {

  const SBToken = await hre.ethers.getContractFactory("SBToken");
  const contract = await SBToken.deploy(ethers.utils.parseEther("1000"));

  await contract.deployed();

  console.log("SBToken deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
