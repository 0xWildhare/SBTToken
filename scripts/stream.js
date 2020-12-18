const TOKEN_ADDRESS = "0x779f7F647914f156826A712D20D69b26E41298E6";

async function main() {
  const SBToken = await hre.ethers.getContractFactory("SBToken");
  const sbt = await SBToken.attach(TOKEN_ADDRESS);

  const tx = await sbt.createStream("0x4007CE2083c7F3E18097aeB3A39bb8eC149a341d", ethers.utils.parseEther("100"), 11000);
  const receipt = await tx.wait();

  console.log(receipt);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
