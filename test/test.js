const { assert } = require("chai");

describe("SBTToken", function() {
  let token;
  let deployer
  const supply = "1000"
  beforeEach(async () => {
    deployer = ethers.provider.getSigner(0);
    const SBTToken = await ethers.getContractFactory("SBTToken");
    token = await SBTToken.deploy(ethers.utils.parseEther(supply));
    await token.deployed();
  });


  it("Should mint tokens to deployer", async () => {
    const balance = await token.balanceOf(deployer.getAddress());
    assert.equal(
      balance.toString(),
      ethers.utils.parseEther(supply).toString()
    );
  });
  describe('a transfer', () => {
    let recipient;
    beforeEach(async () => {
      recipient = ethers.provider.getSigner(1);
      await token.transfer(
        recipient.getAddress(),
        ethers.utils.parseEther("10")
      );
    });
    it('should transfer 10 tokens to the recipient', async () => {
      const balance = await token.balanceOf(recipient.getAddress());
      assert.equal(
        balance.toString(),
        ethers.utils.parseEther("10").toString()
      );
    });


  it('should leave deployer with 990', async () => {
    const balance = await token.balanceOf(deployer.getAddress());
    assert.equal(
      balance.toString(),
      ethers.utils.parseEther("990").toString()
    );
  });
});

});
