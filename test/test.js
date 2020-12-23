const { assert } = require("chai");

describe("SBToken", function() {
  let token;
  let deployer
  const supply = "1000"
  let bondingContract;
  let couponContract;
  let dustCollector;
  let oracle;
  let shares;

  beforeEach(async () => {
    deployer = await ethers.provider.getSigner(0);
    //bondingContract = await ethers.provider.getSigner(6);
    couponContract = await ethers.provider.getSigner(7);
    dustCollector = await await ethers.provider.getSigner(8);

    const SBToken = await ethers.getContractFactory("SBToken");
    const Bonding = await ethers.getContractFactory("bondingContract");
    const Oracle = await ethers.getContractFactory("PriceOracle");
    const Shares = await ethers.getContractFactory("bLSD");

    token = await SBToken.deploy(ethers.utils.parseEther(supply));
    bondingContract = await Bonding.deploy();
    oracle = await Oracle.deploy();
    shares = await Shares.deploy();

    await token.deployed();
    await token.changeBondingContract(bondingContract.address);
    await token.changeCouponContract(couponContract.getAddress());
    await token.changeDustCollector(dustCollector.getAddress());
    await bondingContract.setOracle(oracle.address);
/*
    await token.mint(ethers.utils.parseEther(supply));

    await token.transfer(
      bondingContract.address,
      ethers.utils.parseEther(supply)
    );
*/
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

  it('should have assigned a couponContract', async () => {
    let _coupCont = await token.getCouponContract();
    let addy = await couponContract.getAddress()
    assert.equal(_coupCont, addy);
  })

  it('should have assigned a bondingContract', async () => {
    let _bondCont = await token.getBondingContract();
    let addy = await bondingContract.address;
    assert.equal(_bondCont, addy);
  })

  it('should have assigned a dustCollector', async () => {
    let _dust = await token.getDustCollector();
    let addy = await dustCollector.getAddress()
    assert.equal(_dust, addy);
  })
  it('should not access balance through getAddress', async () => {
    let ex;
    try {
        await bondingContract.getBalance()
    }
    catch(_ex) {
      ex = _ex;
    }
    assert(ex); // asserts that ex is truthy, otherwise this fails
  })
  it('should see address after token is set', async () => {
    await bondingContract.setToken(token.address);
    let tokenAddress = await bondingContract.getToken();
    //console.log(tokenAddress);
    //console.log(token.address);
    assert.equal(tokenAddress, token.address);
  })

/*
  it('should see bonding balance after token is set', async () => {
    await bondingContract.setToken(token.address);
    await token.transfer(
      bondingContract.address,
      ethers.utils.parseEther("13"));
    let bondingBalance = await token.balanceOf(bondingContract.address);
    let bondingBalanceFromBonding = await bondingContract.getBondingBalance();
    //console.log(bondingBalance.toString());
    //console.log(bondingBalanceFromBonding.toString());
    assert.equal(bondingBalance.toString(), bondingBalanceFromBonding.toString());

  })


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

  it('should cost a lot to make a transfer if many streams are active', async () => {
    await token.createStream(
      recipient.getAddress(),
      ethers.utils.parseEther("24"),
      200
    );
    let caller = await ethers.provider.getSigner(1);
    await token.connect(caller).createStream(
      deployer.getAddress(),
      ethers.utils.parseEther("5"),
      1000
    );
    await token.createStreamToBonding(ethers.utils.parseEther("10"));
    await token.createStreamFromBonding(deployer.getAddress(), ethers.utils.parseEther("10"), 1000);
    await token.createStreamToBurn(ethers.utils.parseEther("10"));
    await token.transfer(
      recipient.getAddress(),
      ethers.utils.parseEther("10")
    );
    assert.equal(0,0);

  })
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
        207
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
      params: [210]
    });
    await hre.network.provider.request({
      method: "evm_mine",
      params: []
    });

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
       params: [210]
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

      it('Recipient should haved streamed tokens after stream ends and new stream starts', async() => {
        await hre.network.provider.request({
          method: "evm_increaseTime",
          params: [210]
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
           assert.isAbove(
             balance,
             ethers.utils.parseEther("29")
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

      it("should have sent remainder to dustCollector", async () => {
        let dust = await token.balanceOf(dustCollector.getAddress());
        //console.log(dust);
        assert.isAbove(dust, 0);
      })


  })


  describe('A stream to Bonding', () => {

    let caller;
    let stringId;

    beforeEach(async () => {
      caller = ethers.provider.getSigner(1);

      await token.transfer(
        caller.getAddress(),
        ethers.utils.parseEther("1000")
      );

      const tx = await token.connect(caller).createStreamToBonding(ethers.utils.parseEther("100"));

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

      it('should have tokens in bondingContract', async () => {

        await hre.network.provider.request({
          method: "evm_increaseTime",
          params: [1010]
        });
        await hre.network.provider.request({
          method: "evm_mine",
          params: []
        });

        await token.updateStream(1);
        const balance = await token.balanceOf(bondingContract.address);
        const deployerBalance = await token.balanceOf(deployer.getAddress());
        //console.log(deployerBalance.toString());
           assert.isAbove(
             balance,
             ethers.utils.parseEther(supply)
             );

      }  )



    })

    describe('A stream to couponContract', () => {

      let caller;
      let stringId;

      beforeEach(async () => {
        caller = ethers.provider.getSigner(1);

        await token.transfer(
          caller.getAddress(),
          ethers.utils.parseEther("1000")
        );

        const tx = await token.connect(caller).createStreamToBurn(ethers.utils.parseEther("100"));

        //const reciept = await tx.wait();

      //  console.log(reciept);

        });

        it("should exist", async () => {

          const stream = await token.getStream(1);
          //console.log(await caller.getAddress());
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


       it('should have tokens in couponContract', async () => {
         await hre.network.provider.request({
           method: "evm_increaseTime",
           params: [1010]
         });
         await hre.network.provider.request({
           method: "evm_mine",
           params: []
         });

         await token.updateStream(1);
         const balance = await token.balanceOf(couponContract.getAddress());
         const deployerBalance = await token.balanceOf(deployer.getAddress());
               //console.log(deployerBalance.toString());
            assert.isAbove(
              balance,
              ethers.utils.parseEther("0")
              );

       }  )

    })


    describe('A stream from Bonding', () => {

       let caller;
       let stringId;


       beforeEach(async () => {
         caller = ethers.provider.getSigner(1);

         await token.transfer(
           caller.getAddress(),
           ethers.utils.parseEther("1000")
         );


         await token.changeBondingContract(bondingContract.address);

         //address recipient, uint amount, uint duration
         const tx = await token.createStreamFromBonding(caller.getAddress(), ethers.utils.parseEther("100"), 1000);

         //const reciept = await tx.wait();

       //  console.log(reciept);

         });

         it("should exist", async () => {

           const stream = await token.getStream(1);
           //console.log(await caller.getAddress());
          // console.log(stream);
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

      it('should mint tokens to recipient', async() => {

         await hre.network.provider.request({
           method: "evm_increaseTime",
           params: [1000]
         });
         await hre.network.provider.request({
            method: "evm_mine",
            params: []
          });


          const balance = await token.balanceOf(caller.getAddress());

               assert.equal(
                 balance.toString(),
                 ethers.utils.parseEther("1100").toString()
               );
         });


        })
    describe('a bonding deposit', async() => {

      beforeEach(async () => {
        await bondingContract.setToken(token.address);
        await token.approve(bondingContract.address, ethers.utils.parseEther(supply));
        await bondingContract.bondTokens(ethers.utils.parseEther('10'));

      });

      it('should have created a deposit', async () => {
        let deposit = await bondingContract.getDeposit();
        //console.log(deposit);
        assert(deposit);
      })
    })

    describe('oracle interaction', async () => {
      beforeEach(async () => {

          await hre.network.provider.request({
            method: "evm_increaseTime",
            params: [3602]
          });
          await hre.network.provider.request({
             method: "evm_mine",
             params: []
          });
          await oracle.storePrice(66312345678, 63412345678);

          await hre.network.provider.request({
            method: "evm_increaseTime",
            params: [3612]
          });
          await hre.network.provider.request({
             method: "evm_mine",
             params: []
          });
          await oracle.storePrice(66712345678, 65412345678);

          await hre.network.provider.request({
            method: "evm_increaseTime",
            params: [3633]
          });
          await hre.network.provider.request({
             method: "evm_mine",
             params: []
          });
          await oracle.storePrice(65912345678, 67212345678);

          await hre.network.provider.request({
            method: "evm_increaseTime",
            params: [3602]
          });
          await hre.network.provider.request({
             method: "evm_mine",
             params: []
          });
          await oracle.storePrice(67112345678, 65312345678);
      })

      it('should give price', async () => {
        const price = await oracle.getCurrentPrice();
        //console.log(price);
        assert(price);
      })
      it('should give time', async () => {
        const time = await oracle.getCurrentTime();
        //console.log(time);
        assert(time);
      })
      it('it should give a previous price', async () => {
        let time = await oracle.getCurrentTime();
        time = time - 8000;
        const price = await oracle.getPrice(time);
        //console.log(price);
        assert(price);
      })
      it('it should give different previous prices at different times', async () => {
        let time = await oracle.getCurrentTime();
        time1 = time - 4800;
        time2 = time - 4900;
        const price1 = await oracle.getPrice(time1);
        const price2 = await oracle.getPrice(time2);
        //console.log(price1, price2);
        assert.notEqual(price1, price2);
      })
    })
*/
    describe('a bonding interaction', async() => {

      beforeEach(async () => {
        await bondingContract.setToken(token.address);
        await token.approve(bondingContract.address, ethers.utils.parseEther(supply));
        await bondingContract.setShares(shares.address);
        await bondingContract.setCouponContract(couponContract.getAddress());
        await shares.setBondingContract(bondingContract.address);
        await bondingContract.bondTokens(ethers.utils.parseEther('100'));


      })

      it('should have bonded tokens', async () => {
        let _shares = await shares.balanceOf(deployer.getAddress());
        //console.log(_shares);
        assert(_shares)
      })

      it('should recieve rewards from couponContract', async () => {
        await bondingContract.connect(couponContract).increaseShareValue(ethers.utils.parseEther('10'));
        const balance = await bondingContract.getRewardsBalance();
        const shouldBe = ethers.utils.parseEther('110')
        //console.log(balance);
        assert.equal(balance.toString(), shouldBe.toString());
      })

      it('should redeem rewards', async () => {
        await token.transfer(
          bondingContract.address,
          ethers.utils.parseEther('10')
        );
        await bondingContract.connect(couponContract).increaseShareValue(ethers.utils.parseEther('10'));
        //const balance = await bondingContract.getRewardsBalance();
        //let bondingBalance = await token.balanceOf(bondingContract.address);
        //let shareValue = await bondingContract.getCurrentShareValue();
        await bondingContract.redeemShares(ethers.utils.parseEther('100'));
        let stream = await token.getStream(1);
        /*
        console.log(balance);
        console.log(shareValue);
        console.log(bondingBalance);
        */
        console.log(stream);
        
        assert(stream);
      })

/*
      it('should get index for address', async () => {
        const index = await bondingContract.getIndex();
        //console.log(index);
        assert(index);
      })

      it('should get deposit', async () => {
        let deposit = await bondingContract.getDeposit();
        //console.log(deposit);
        assert(deposit);
      })

      it('shoould show interest rate', async () => {
        let time = await oracle.getCurrentTime();
        time = time - 8000;
        const intrest = await bondingContract._getIntrestRate(time);
        console.log(intrest);
        assert(intrest);
      })

      it('should calculate intrest', async () => {
        let index = await bondingContract.getIndex()
        let value = await bondingContract.getCurrentValue(index)
        console.log(value);
        assert.isAbove(value, 1000);
      })
*/

    })



});
