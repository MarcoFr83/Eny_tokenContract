// SPDX-License-Identifier: MIT
// JUL BLOCKTEAM PACA 2021 
pragma solidity ^0.8.0;


/*
    USAGE
        * create / launch Safe Wallet for putting ICO Token supply and ICO funds 
        * deploy a ERC20Token (with SafeWallet address in constructor)
        * deploy ENYTokenICO
        * Wallet Safe must approve ICO Contract for supply amount
        * use launchIco function 
*/

/*
    TODO
    =>  tokenRate au lieu de tokenPrice (1000 token / 1eth par ex)
    
        uint256 etherUsed = msg.value;      
        tokensToBuy = etherUsed * (10 ** IToken.decimals()) / 1 ether * tokenRate;

    => mettre en modifyer setIcoStatus => buyTokens
    
*/

/*  ************************************************************************
        Interface ERC20
*/
interface IToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function decimals() external returns (uint256);
}


contract ENYICO_JML {
    address payable admin;              // Wallet Safe
    address  owner = msg.sender;        // ICO sender 

    uint256  public tokensIcoTimeOut;   // date heure limite ( en s/01011970)
    uint256  public tokenIcoStart;      // timestamp lancement ICO 
    uint256  public tokenPrice;         // prix token wei
    uint256  public tokensSold;         // tokens vendu uint
    uint256  public tokenLeft;          // tokens dispo pour vente uint
    uint256  public tokenIcoSupply;     // totalsupply pour info uint
    address  public tokenContract;      // Token Contract address
    uint256  private tokenDecimals;     // Token Contract decimals
    uint256  public IcoBalance;         // ICO balance

    
    enum icoStates {WAITING, STARTED, ENDED, STOPPED}
    icoStates public icoState = icoStates.WAITING;  // statut ICO 
    
    struct Buyers {
        address addressBuyer;
        uint256 tokenOrder;
        uint256 totalPaid;
        bool    verifyed;
    }
    Buyers[] icoInvestors;                                                  // investors data 

    address payable refundBuyer;                                            // pour trop perçu ?
    

    /*  ************************************************************************
        EVENTS For the Front
    */
    event Buy(address _buyer, uint256 _tokens, uint256 _totalBalance, uint256 _totalInvestor, uint256 _tokenLeft);
    event directBuy(address _buyer, uint256 _tokens, uint256 _amount, bytes _data);

    /*  ************************************************************************
        modifyers 
    */
    modifier onlyAdmin {                                                        // Function that can be actioned only by the admin
        require(msg.sender == admin," Contract Admin use Only");
        _;
    }
    modifier onlyOwner {                                                        // Function that can be actioned only by the owner
        require(msg.sender == owner," Contract Owner use Only");
        _;
    }
    


    /*  ************************************************************************
        Launching ICO 
    */
        function launchIco (uint256 _icoStart, 
                            //uint256 _icoDurationMinute,                        // test only
                            uint256 _icoDurationDay,
                            uint256 _tokenPrice, uint256 _tokenIcoSupply, 
                            address payable _walletSafe, address _tokenContract)  external onlyOwner {   
                        
        require(icoState == icoStates.WAITING, "Sorry, this ICO stage already started");                                
        // voir avec Gnosis pour admin de ICO
        admin               = _walletSafe;
        tokenPrice          = _tokenPrice;
        tokenIcoSupply      = _tokenIcoSupply/(10**18);                             // human readable (at least jm readable)
        tokensIcoTimeOut    = _icoStart + multiply(_icoDurationDay,86400);
        tokenIcoStart       = _icoStart;
        tokenLeft           = tokenIcoSupply;
        tokenContract       = _tokenContract;
        tokenDecimals       = decimalsToken(_tokenContract);

        setIcoStatus();
    }


     /*  ************************************************************************
        ACHAT DE TOKEN par la value
    */
    function buyAmountTokens() payable public{
        uint256 numberOfTokens;
        uint256 totalNet;
        uint256 tropPercu;
        
        setIcoStatus();                                                                                 // ctrl et upate ico status

        require(icoState == icoStates.STARTED, "Sorry, this ICO stage is currently closed");
        require(tokenLeft > 0, "No more token to sell !");
        
        numberOfTokens = msg.value / tokenPrice;                                                        // calcul nb de token en fonction de la value
        if (numberOfTokens > tokenLeft) { numberOfTokens = tokenLeft;}                                  // livraison des tokens disponibles
        
        totalNet = multiply(numberOfTokens,tokenPrice);                                                 // calcul du totalNet reel -> rbst du trop percu
        require(msg.value >= totalNet, "Sorry, no sufficient funds ");
        tropPercu = msg.value - totalNet;
        if (tropPercu > 0) {                                                                            // trop percu : refund de la difference
            refundBuyer = payable(msg.sender);
            refundBuyer.transfer(tropPercu); 
        }

        icoInvestors.push(Buyers(msg.sender,numberOfTokens, msg.value, false));
        tokensSold += numberOfTokens;
        tokenLeft -= numberOfTokens;
        

        transferTokenFrom(tokenContract, admin, msg.sender, numberOfTokens*(10**18));                   // transfer vers le buyer (non remboursable)
        IcoBalance += totalNet;
        
        emit Buy(msg.sender, numberOfTokens, address(this).balance, icoInvestors.length, tokenLeft );  // Event pour le front
    }

    /*  ************************************************************************
        MAJ status ICO 
        
    */
    function setIcoStatus () internal{
        require (icoState != icoStates.STOPPED, "ICO stage STOPPED");
        if (tokensIcoTimeOut <= block.timestamp) { icoState = icoStates.ENDED; }
        else if (tokenIcoStart <= block.timestamp) { icoState = icoStates.STARTED; }
    }


    /*  ************************************************************************
        FORCE FIN ICO (MANUELLEMENT)
    */
    function endSale() public payable onlyAdmin{
        require(icoState != icoStates.STOPPED, " ICO already STOPPED ...");

        icoState = icoStates.STOPPED;                                               // change state before transfer
        admin.transfer(address(this).balance);                                      // transfer de la balance vers le Wallet Safe
        IcoBalance = address(this).balance;                                         // update balance ICO contract
        IToken(tokenContract).approve(address(this), 0);                            // RAZ allowance = disaprove this ICO = set allowance to 0 
                                                                                    // AJOUTER EVENT SUR ENDSALE        
    }

     /*  ************************************************************************
        appel interface sur Token (ERC20)
    */
    function transferTokenFrom(address _tokenContract, address _from, address _to, uint256 _amount) internal returns (bool){
            return IToken(_tokenContract).transferFrom(_from, _to, _amount);
    }
    function decimalsToken(address _tokenContract) internal returns (uint256){
            return IToken(_tokenContract).decimals();
    }


     /*  ************************************************************************
        Investisseurs de l'ICO 
    */
    function getInvestors() public view onlyAdmin returns (Buyers[] memory) {
        return (icoInvestors);
   }

     /*  ************************************************************************
        Safe MULT 
    */
    function multiply(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    /*  ************************************************************************
        FallBack & receive
    */
    fallback() external payable { 
        emit directBuy(msg.sender, (msg.value*(10**18) /tokenPrice), msg.value, "fallback");
        buyAmountTokens();
    }
    receive() external payable { 
        emit directBuy(msg.sender, (msg.value*(10**18) /tokenPrice), msg.value, "receive");
        buyAmountTokens();
    }


}


