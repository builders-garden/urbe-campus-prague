import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract FakeUSDC is ERC20 {
    constructor() ERC20("FakeUSDC", "fUSDC") {
        _mint(msg.sender, 1000000000000000000000000);
    }

    /* This is a fake USDC contract for testing purposes
     * Do not use this contract in production.
     * Do not replicate this function in production.
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
