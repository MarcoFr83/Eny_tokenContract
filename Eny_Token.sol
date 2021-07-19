// SPDX-License-Identifier: MIT
// JUL BLOCKTEAM PACA 2021 
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract Eny_Token is ERC20 {

    address owner;

    uint256 totalSupplyMax  = 6500000000000000000000000;
    uint256 supplyByFounder = 1000000000000000000000;

    address owner1  = 0xFD31839B5eabB91D88CbBb9e481e9d13ca469A1e;       // c
    address owner2  = 0xEF2C2a05638f4872f5732DFe5240b2Aa8315AcA1;       // jm
    address owner3  = 0x6752A24c636AEdC688de1e38212c392547A3b90c;       // r
    address owner4  = 0xfE4ED255e80F62b01E15AAFA9e581660230BbEB8;       // y
    

//    address ENYWalletSupply     = 0x2B6d5d6A6f588084dC9565ffA1b7f28fe60D479E;
    address ENYWalletSupply     = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    constructor() ERC20("En Y toktok", "ENYt") {
        owner = msg.sender;
        _mint(owner1, supplyByFounder);
        _mint(owner2, supplyByFounder);
        _mint(owner3, supplyByFounder);
        _mint(owner4, supplyByFounder);
        
        totalSupplyMax -= (supplyByFounder*4);
        _mint(ENYWalletSupply, totalSupplyMax);
        
    }
    
}