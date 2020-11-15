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

  describe('start stream', () => {
    let recipient;
    let stringId;

    beforeEach(async () => {
      recipient = ethers.provider.getSigner(2);
      const tx = await token.createStream(
        recipient.getAddress(),
        ethers.utils.parseEther("10"),
        1000
      );

      const reciept = await tx.wait();

      //console.log(reciept);

      });
   it('first stream should exist', async() => {
      const stream = await token.getStream(1);//token.isStream(1);

      assert(stream);
    })

    it('second stream should not exist', async() => {
      let ex;
      try {
        await token.getStream(2);
      }
      catch(_ex) {
        ex = _ex;
      }
      assert(ex); // asserts that ex is truthy, otherwise this fails


     })

     it('after creating 2 entities, 2nd stream should be an entity', async() => {
       recipient = ethers.provider.getSigner(3);
       const tx = await token.createStream(
         recipient.getAddress(),
         ethers.utils.parseEther("10"),
         1000
       );
       const stream = await token.getStream(2);
       console.log(stream);
       console.log(await recipient.getAddress());
       assert(stream);
        })

  })

});
