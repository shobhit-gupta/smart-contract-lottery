// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

interface ILessonNine {
    function solveChallenge(
        uint256 randomGuess,
        string memory yourTwitterHandle
    ) external;
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Challenge is IERC721Receiver {
    ILessonNine private constant CHALLENGE =
        ILessonNine(0x33e1fD270599188BB1489a169dF1f0be08b83509);
    IERC721 private constant NFT =
        IERC721(0x76B50696B8EFFCA6Ee6Da7F6471110F334536321);

    address private immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    function solve(string calldata twitter) external {
        uint256 ans = uint256(
            keccak256(
                abi.encodePacked(
                    address(this),
                    block.prevrandao,
                    block.timestamp
                )
            )
        ) % 100000;
        CHALLENGE.solveChallenge(ans, twitter);
    }

    function withdraw(uint256 tokenId) external onlyOwner {
        NFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
