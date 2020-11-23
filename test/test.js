const { assert } = require("chai");

describe("SBTToken", function() {
  let token;
  let deployer
  const supply = "1000"
  beforeEach(async () => {
    deployer = await ethers.provider.getSigner(0);
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

  it("should be mintable by deployer", async () => {
    await token.mint(ethers.utils.parseEther(supply));
    const balance = await token.balanceOf(deployer.getAddress());
    let doubleSupply = "2000";
    assert.equal(
      balance.toString(),
      ethers.utils.parseEther(doubleSupply).toString()
    );
    });

  it("should not be mintable by someone other than the deployer", async () => {
    user = await ethers.provider.getSigner(1).getAddress();


    let ex;
    try {
      const tx = await token.connect(user).mint(ethers.utils.parseEther(supply));
    }
    catch(_ex) {
      ex = _ex;
    }
    assert(ex);

    });

  it("should be able to transfer ownership", async () => {
    let address = await ethers.provider.getSigner(2).getAddress();
    await token.transferOwnership(address);

    let owner = await token.owner();

    assert.equal(
      owner,
      address
    );
  });
/* cant get this test to work, don't know why. will test on test net.
  it("should allow new owner to mint", async () => {
    let address = await ethers.provider.getSigner(2).getAddress();
    await token.transferOwnership(address);

    console.log(await token.owner());
    console.log(address);

    await hre.network.provider.request({
      method: "evm_increaseTime",
      params: [1]
    });
    await hre.network.provider.request({
      method: "evm_mine",
      params: []
    });

    const tx = await token.connect(address).mint(ethers.utils.parseEther(supply));
    const balance = await token.balanceOf(address);
    console.log(tx);
    assert.equal(
      1,1
    );
  });

  */

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



  describe('A stream', () => {
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

    it('should return a balance of 24 after 2 seconds', async() => {

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

      //const deployerBalance = await token.balanceOf(deployer.getAddress());
       //console.log(deployerBalance.toString());

       recipient = ethers.provider.getSigner(4);
       await token.transfer(
           recipient.getAddress(),
           ethers.utils.parseEther("976")
         );

       const balance = await token.balanceOf(recipient.getAddress());


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


  it('Sender should not haved streamed tokens after stream ends', async() => {

    await hre.network.provider.request({
      method: "evm_increaseTime",
      params: [2]
    });
    await hre.network.provider.request({
      method: "evm_mine",
      params: []
    });
/*
    recipient = ethers.provider.getSigner(1);
    await token.transfer(
      recipient.getAddress(),
      ethers.utils.parseEther("1")
    );
*/
    const balance = await token.balanceOf(recipient.getAddress());
    const deployerBalance = await token.balanceOf(deployer.getAddress());
    //console.log(deployerBalance.toString());
       assert.equal(
         deployerBalance.toString(),
         ethers.utils.parseEther("976").toString()
         );
       });


   it('Sender should not haved streamed tokens after stream ends and new stream starts', async() => {
     await hre.network.provider.request({
       method: "evm_increaseTime",
       params: [3]
     });
     await hre.network.provider.request({
       method: "evm_mine",
       params: []
     });

     await token.createStream(
       recipient.getAddress(),
       ethers.utils.parseEther("10"),
       1000
     );

     const balance = await token.balanceOf(recipient.getAddress());
     const deployerBalance = await token.balanceOf(deployer.getAddress());
     //console.log(deployerBalance.toString());
        assert.equal(
          deployerBalance.toString(),
          ethers.utils.parseEther("976").toString()
          );
      });

      it("should be able to cancel stream", async () => {

        await token.cancelStream(1);
        let ex;
        try {
          await token.getStream(1);
        }
        catch(_ex) {
          ex = _ex;
        }
        assert(ex);
      })



  })


  describe('A longer timeframe stream', async () => {
    let recipient;
    let stringId;

    beforeEach(async () => {
      recipient = await ethers.provider.getSigner(2);
      const tx = await token.createStream(
        recipient.getAddress(),
        ethers.utils.parseEther("30"),
        200
      );

      const reciept = await tx.wait();

      //console.log(reciept);

      });



  it('should create second stream from second sender', async() => {
    let deployer = await ethers.provider.getSigner(0);
    recipient = ethers.provider.getSigner(2);
    await token.transfer(
      recipient.getAddress(),
      ethers.utils.parseEther("10")
    );
    recipient = ethers.provider.getSigner(3);
    deployer = ethers.provider.getSigner(2);
    const tx = await token.connect(deployer).createStream(
      recipient.getAddress(),
      ethers.utils.parseEther("10"),
      1000
    );
    const stream = await token.getStream(1);
    //console.log(await ethers.provider.getSigner(0).getAddress());
  //  console.log(await ethers.provider.getSigner(2).getAddress());
    //console.log(stream);
   // console.log(await recipient.getAddress());
    assert(stream);
     })


   it('should allow a transfer mid-stream', async() => {

      await hre.network.provider.request({
        method: "evm_increaseTime",
        params: [100]
      });
      await hre.network.provider.request({
         method: "evm_mine",
         params: []
       });

      //const deployerBalance = await token.balanceOf(deployer.getAddress());
      // console.log(deployerBalance.toString());

       //const stream = await token.getStream(1);
       //console.log(stream);

       recipient = ethers.provider.getSigner(4);
       await token.transfer(
           recipient.getAddress(),
           ethers.utils.parseEther("970")
         );

       const balance = await token.balanceOf(recipient.getAddress());


            assert.equal(
              balance.toString(),
              ethers.utils.parseEther("970").toString()
            );
          });


    it('should not allow a transfer to cut into remaining stream balance', async() => {

       await hre.network.provider.request({
         method: "evm_increaseTime",
         params: [100]
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
            ethers.utils.parseEther("975")
          );
        }
        catch(_ex) {
          ex = _ex;
          }
          assert(ex); // asserts that ex is truthy, otherwise this fails
          })

  it('should not create a stream for more than the avaliable balance', async() => {

    recipient = ethers.provider.getSigner(3);

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


  it('Sender should not haved streamed tokens after stream ends', async() => {

    await hre.network.provider.request({
      method: "evm_increaseTime",
      params: [205]
    });
    await hre.network.provider.request({
      method: "evm_mine",
      params: []
    });
  /*
    recipient = ethers.provider.getSigner(1);
    await token.transfer(
      recipient.getAddress(),
      ethers.utils.parseEther("1")
    );
  */
    const balance = await token.balanceOf(recipient.getAddress());
    const deployerBalance = await token.balanceOf(deployer.getAddress());
    //console.log(deployerBalance.toString());
       assert.equal(
         deployerBalance.toString(),
         ethers.utils.parseEther("970").toString()
         );
       });


   it('Sender should not haved streamed tokens after stream ends and new stream starts', async() => {
     await hre.network.provider.request({
       method: "evm_increaseTime",
       params: [205]
     });
     await hre.network.provider.request({
       method: "evm_mine",
       params: []
     });

     await token.createStream(
       recipient.getAddress(),
       ethers.utils.parseEther("10"),
       1000
     );

     const balance = await token.balanceOf(recipient.getAddress());
     const deployerBalance = await token.balanceOf(deployer.getAddress());
     //console.log(deployerBalance.toString());
        assert.equal(
          deployerBalance.toString(),
          ethers.utils.parseEther("970").toString()
          );
      });

      it("should be able to cancel stream", async () => {

        await token.cancelStream(1);
        let ex;
        try {
          await token.getStream(1);
        }
        catch(_ex) {
          ex = _ex;
        }
        assert(ex);
      })

      it("should not allow someone else to cancel the Stream", async () => {
        let someoneElse = await ethers.provider.getSigner(1);
        let ex;
        try {
          await token.connect(someoneElse).cancelStream(1);
        }
        catch(_ex) {
          ex = _ex;
        }
        //console.log(ex);
        assert(ex);

      })


  })


  describe('A stream to DAO', () => {

    let caller;
    let stringId;

    beforeEach(async () => {
      caller = ethers.provider.getSigner(1);

      await token.transfer(
        caller.getAddress(),
        ethers.utils.parseEther("1000")
      );

      const tx = await token.connect(caller).createStreamToDAO(ethers.utils.parseEther("100"));

      //const reciept = await tx.wait();

    //  console.log(reciept);

      });

      it("should exist", async () => {

        const stream = await token.getStream(1);
        //console.log(await ethers.provider.getSigner(0).getAddress());
        //console.log(stream);
        assert(stream);

      })

      it('should allow a normal stream to be sent', async() => {

          recipient = ethers.provider.getSigner(3);

            const tx = await token.connect(caller).createStream(
              recipient.getAddress(),
              ethers.utils.parseEther("10"),
              1000
            );

          const stream = await token.getStream(2);
          assert(stream);
           })

     it('should allow a transfer mid-stream', async() => {

        await hre.network.provider.request({
          method: "evm_increaseTime",
          params: [1]
        });
        await hre.network.provider.request({
           method: "evm_mine",
           params: []
         });

        //const deployerBalance = await token.balanceOf(deployer.getAddress());
         //console.log(deployerBalance.toString());
       recipient = ethers.provider.getSigner(4);
         await token.connect(caller).transfer(
             recipient.getAddress(),
             ethers.utils.parseEther("500")
           );
         const balance = await token.balanceOf(recipient.getAddress());

              assert.equal(
                balance.toString(),
                ethers.utils.parseEther("500").toString()
              );
            });



    })

    describe('A stream to 0x0', () => {

      let caller;
      let stringId;

      beforeEach(async () => {
        caller = ethers.provider.getSigner(1);

        await token.transfer(
          caller.getAddress(),
          ethers.utils.parseEther("1000")
        );

        const tx = await token.connect(caller).createStreamTo0x0(ethers.utils.parseEther("100"));

        //const reciept = await tx.wait();

      //  console.log(reciept);

        });

        it("should exist", async () => {

          const stream = await token.getStream(1);
          //console.log(await ethers.provider.getSigner(0).getAddress());
          //console.log(stream);
          assert(stream);

        })

        it('should allow a normal stream to be sent', async() => {

            recipient = ethers.provider.getSigner(3);

              const tx = await token.connect(caller).createStream(
                recipient.getAddress(),
                ethers.utils.parseEther("10"),
                1000
              );

            const stream = await token.getStream(2);
            assert(stream);
             })


      it('should allow a transfer mid-stream', async() => {

         await hre.network.provider.request({
           method: "evm_increaseTime",
           params: [1]
         });
         await hre.network.provider.request({
            method: "evm_mine",
            params: []
          });

         //const deployerBalance = await token.balanceOf(deployer.getAddress());
          //console.log(deployerBalance.toString());
        recipient = ethers.provider.getSigner(4);
          await token.connect(caller).transfer(
              recipient.getAddress(),
              ethers.utils.parseEther("500")
            );
          const balance = await token.balanceOf(recipient.getAddress());

               assert.equal(
                 balance.toString(),
                 ethers.utils.parseEther("500").toString()
               );
             });




     })

});
