import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import * as chai from 'chai';
import { Contract } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { BigNumber } from '@ethersproject/bignumber';

let hyra: Contract;
let usdt: Contract;
let founder: Contract;
let owner: SignerWithAddress;

async function deployFounder(deployer: SignerWithAddress) {
    const HYRA = await ethers.getContractFactory("HYRA", deployer);
    hyra = await HYRA.deploy();

    const Usdt = await ethers.getContractFactory("Usdt", deployer);
    usdt = await Usdt.deploy();

    const Founder = await ethers.getContractFactory("Founder", deployer);
    founder = await Founder.deploy(hyra.address, usdt.address);

    return [hyra, usdt, founder];
}

describe('Founder contract', function() {
    
    it('owner is deployer for Founder', async function() {
        const [owner,buyer] = await ethers.getSigners();
        await deployFounder(owner);
    });

    it('get hyra token and get usdt token when deploy smart contract', async function(){
      const [owner] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);
      
      console.log("usdt balance: ", await usdt.balanceOf(owner.address));
      console.log("hyra balance: ", await hyra.balanceOf(owner.address));
      
      const usdtBalance = await usdt.balanceOf(owner.address);
      const hyraBalance = await hyra.balanceOf(owner.address);

      chai.expect(usdtBalance.eq(parseEther("1000000"))).true;
    });

    it('set Price, SaleDiv for Hyra', async function(){
      const [owner] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);

      const price = await founder.setSalePrice(parseEther("1"), 100);
      
      
      console.log("hyra price: ", await founder.salePrice());
      console.log("hyra Dive price: ", await founder.saleDiv());
      
      
      const hyraPrice = await founder.salePrice();
      const hyraDivPrice = await founder.saleDiv();

      chai.expect(hyraPrice.eq(parseEther("1"))).true;
      chai.expect(hyraDivPrice.eq(100)).true;
    });

    it('increase round when user buy quantity or hyra > 5_000_000_000', async function(){
      const [owner,buyer] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);

      const price = await founder.setSalePrice(1, 100_000_000);

      await hyra.transfer(founder.address,parseEther("10000000000"));
      await usdt.transfer(buyer.address,parseEther("700000"));
      const founderBuyer = await founder.connect(buyer);
      const usdtBuyer = await usdt.connect(buyer);

      await usdtBuyer.approve(founder.address,usdt.balanceOf(buyer.address));
      const allowance = await usdt.allowance(buyer.address, founder.address);

      console.log("buyer's usdt: ", await usdt.balanceOf(buyer.address));
      console.log("founder's hyra: ", await hyra.balanceOf(founder.address));

      console.log("totalTokenByRound at round 0: ", await founder.totalTokenByRound(0));
      console.log("totalTokenByRound at round 1: ", await founder.totalTokenByRound(1));
      for(let i = 0; i< 60; i++)
      {
          await founderBuyer.buy(parseEther("100000000"));
      }

      console.log("total: "+ await founder.totalTokenSold());
      const currentRound = await founder.currentRound();
      console.log("currentRound: "+currentRound);
      chai.expect(currentRound).equal(1);
      
    });

    it('return usdt for Founder and Buyer', async function(){
      const [owner,buyer] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);

      await hyra.transfer(founder.address,parseEther("1000000"));
      await usdt.transfer(buyer.address,parseEther("100"));
      const founderBuyer = await founder.connect(buyer);
      const usdtBuyer = await usdt.connect(buyer);

      await usdtBuyer.approve(founder.address,usdt.balanceOf(buyer.address));
      const allowance = await usdt.allowance(buyer.address, founder.address);
      const buy = await founderBuyer.buy(parseEther("1000"));
      
      const usdtFounderBalance = await usdt.balanceOf(founder.address);
      const usdtBuyerBalance = await usdt.balanceOf(buyer.address);
      
      chai.expect(usdtFounderBalance.eq(parseEther("1"))).true;
      chai.expect(usdtBuyerBalance.eq(parseEther("99"))).true;   
       
    });

    it('return available and lockedFullAmount of hyra at round 0', async function(){
      const [owner,buyer] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);

       await founder.setTokenGenerationEvent(true);

      await hyra.transfer(founder.address,parseEther("1000000"));
      await usdt.transfer(buyer.address,parseEther("100"));
      const founderBuyer = await founder.connect(buyer);
      const usdtBuyer = await usdt.connect(buyer);

      await usdtBuyer.approve(founder.address,usdt.balanceOf(buyer.address));
      const allowance = await usdt.allowance(buyer.address, founder.address);
      const buy = await founderBuyer.buy(parseEther("1000"));
      
      const available = await founder.getAvailableAmount(buyer.address);
      const lockedFullAmount = await founder.getLockedFullAmount(buyer.address);
      const availableEvent = await founder.getAvailableEventAmount(buyer.address);
      const lockedEventFullAmount = await founder.getLockedEventFullAmount(buyer.address);
      
      await founder.releaseAllMyToken();
      await founder.releaseAllMyTokenEvent();

      console.log("getAvailableAmount: "+ available);
      console.log("getLockedFullAmount: ", lockedFullAmount);
      console.log("getAvailableEventAmount: "+ availableEvent);
      console.log("getLockedFullEventAmount: ", lockedEventFullAmount);
      //chai.expect(available.eq(parseEther("75"))).true;
      chai.expect(available.eq(parseEther("0"))).true;
      chai.expect(lockedFullAmount.eq(parseEther("900"))).true;  
      /**
       getAvailableAmount: 0
        getLockedFullAmount:  BigNumber { value: "900 000 000 000 000 000 000" }
        getAvailableEventAmount: 100 000 000 000 000 000 000
        getLockedFullEventAmount:  BigNumber { value: "100 000 000 000 000 000 000" }
       *  */  
       
    });

    it('buy Hyra by usdt at round 0', async function(){
      const [owner,buyer] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);

      await hyra.transfer(founder.address,parseEther("1000000"));
      await usdt.transfer(buyer.address,parseEther("100"));
      const founderBuyer = await founder.connect(buyer);
      const usdtBuyer = await usdt.connect(buyer);

      await usdtBuyer.approve(founder.address,usdt.balanceOf(buyer.address));
      const allowance = await usdt.allowance(buyer.address, founder.address);
      // console.log("allowance1 : ", allowance);
      // console.log("currentRound: ",await founder.currentRound());
      const buy = await founderBuyer.buy(parseEther("1000"));
      
      const hyraBalance = await hyra.balanceOf(buyer.address);
      const availbleAmount = await founder.getAvailableAmount(buyer.address);
      const lockedFullAmount = await founder.getLockedFullAmount(buyer.address);

      const usdtFounderBalance = await usdt.balanceOf(founder.address);
      const usdtBuyerBalance = await usdt.balanceOf(buyer.address);
      
      chai.expect(usdtFounderBalance.eq(parseEther("1"))).true;
      chai.expect(usdtBuyerBalance.eq(parseEther("99"))).true;
      
       
    });

    it('buy Hyra by usdt at round 3', async function(){
      const [owner,buyer] = await ethers.getSigners();
      const [hyra, usdt, founder] = await deployFounder(owner);

      await founder.setCurrentRound(3);
      await hyra.transfer(founder.address,parseEther("1000000"));
      await usdt.transfer(buyer.address,parseEther("100"));
      const founderBuyer = await founder.connect(buyer);
      const usdtBuyer = await usdt.connect(buyer);

      await usdtBuyer.approve(founder.address,usdt.balanceOf(buyer.address));
      const allowance = await usdt.allowance(buyer.address, founder.address);
      
      console.log("allowance: ", allowance);
      const buy = await founderBuyer.buy(parseEther("1000"));

      const hyraBalance = await hyra.balanceOf(buyer.address);
      console.log("hyra balance: ", hyraBalance);

      chai.expect(hyraBalance.eq(parseEther("1000"))).true;
      const usdtFounderBalance = await usdt.balanceOf(founder.address);
      const usdtBuyerBalance = await usdt.balanceOf(buyer.address);
      console.log("usdt Owner balance: ", usdtFounderBalance);
      chai.expect(usdtFounderBalance.eq(parseEther("1"))).true;
      chai.expect(usdtBuyerBalance.eq(parseEther("99"))).true;
    });



});
