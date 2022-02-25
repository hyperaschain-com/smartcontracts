import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

describe("HYRA", function () {

  let hyra: Contract
  let owner: SignerWithAddress

  this.beforeEach(async () => {
    await ethers.provider.send("hardhat_reset", []);

    [ owner ] = await ethers.getSigners();

    const HYRA = await ethers.getContractFactory("HYRA");
    hyra = await HYRA.deploy();
    await hyra.deployed();

  })

  it("should return total supply", async () => {
    expect(await hyra.totalSupply()).equal(parseEther('100000000000'));
  })

  it('should return valid owner', async () => {
    expect(await hyra.owner()).equal(owner.address);
  })

});
