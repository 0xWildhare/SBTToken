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
        ethers.utils.parseEther("24"),
        2
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

 it('should not be able to create second stream from same address', async() => {
     recipient = ethers.provider.getSigner(3);

     let ex;
     try {
       const tx = await token.createStream(
         recipient.getAddress(),
         ethers.utils.parseEther("10"),
         1000
       );
     }
     catch(_ex) {
       ex = _ex;
     }
     assert(ex); // asserts that ex is truthy, otherwise this fails

      })

  it('should create second stream from second sender', async() => {
    recipient = ethers.provider.getSigner(2);
    await token.transfer(
      recipient.getAddress(),
      ethers.utils.parseEther("10")
    );
    recipient = ethers.provider.getSigner(3);
    deployer = ethers.provider.getSigner(2);
    const tx = await token.createStream(
      recipient.getAddress(),
      ethers.utils.parseEther("10"),
      1000
    );
    const stream = await token.getStream(2);
   //console.log(stream);
   // console.log(await recipient.getAddress());
    assert(stream);
     })

 it('should return deposit of 0 immediately', async() => {
   const balance = await token.balanceOf(recipient.getAddress());
   const deployerBalance = await token.balanceOf(deployer.getAddress());
   //console.log(deployerBalance.toString());
   assert.equal(
     balance.toString(),
     ethers.utils.parseEther("0").toString()
   );
 })

  it('should return a balance of 12 after 1 second', async() => {

     await hre.network.provider.request({
       method: "evm_increaseTime",
       params: [1]
     });
     await hre.network.provider.request({
       method: "evm_mine",
       params: []
     });

     const balance = await token.balanceOf(recipient.getAddress());
     const deployerBalance = await token.balanceOf(deployer.getAddress());
     //console.log(deployerBalance.toString());
        assert.equal(
          balance.toString(),
          ethers.utils.parseEther("12").toString()
          );
        });

    it('should return a balance of 24 after 2 second', async() => {

      await hre.network.provider.request({
        method: "evm_increaseTime",
        params: [2]
      });
      await hre.network.provider.request({
        method: "evm_mine",
        params: []
      });

      const balance = await token.balanceOf(recipient.getAddress());
      const deployerBalance = await token.balanceOf(deployer.getAddress());
      //console.log(deployerBalance.toString());
         assert.equal(
           balance.toString(),
           ethers.utils.parseEther("24").toString()
           );
         });

   it('should allow a transfer mid-stream', async() => {

      await hre.network.provider.request({
        method: "evm_increaseTime",
        params: [1]
      });
      await hre.network.provider.request({
         method: "evm_mine",
         params: []
       });

       recipient = ethers.provider.getSigner(4);
       await token.transfer(
           recipient.getAddress(),
           ethers.utils.parseEther("976")
         );

       const balance = await token.balanceOf(recipient.getAddress());
       const deployerBalance = await token.balanceOf(deployer.getAddress());
       //console.log(deployerBalance.toString());
            assert.equal(
              balance.toString(),
              ethers.utils.parseEther("976").toString()
            );
          });

    it('should not allow a transfer to cut into remaining stream balance', async() => {

       await hre.network.provider.request({
         method: "evm_increaseTime",
         params: [1]
       });
        await hre.network.provider.request({
          method: "evm_mine",
          params: []
          });

        recipient = ethers.provider.getSigner(4);
        let ex;
        try {
          await token.transfer(
            recipient.getAddress(),
            ethers.utils.parseEther("988")
          );
        }
        catch(_ex) {
          ex = _ex;
          }
          assert(ex); // asserts that ex is truthy, otherwise this fails
          })

  it('should not create a stream for more than the avaliable balance', async() => {

    recipient = ethers.provider.getSigner(3);
    deployer = ethers.provider.getSigner(2);
    let ex;
    try {
      const tx = await token.createStream(
        recipient.getAddress(),
        ethers.utils.parseEther("10000"),
        1000
      );
      
    }
    catch(_ex) {
      ex = _ex;
      }
      assert(ex); // asserts that ex is truthy, otherwise this fails
      })


  })

});
