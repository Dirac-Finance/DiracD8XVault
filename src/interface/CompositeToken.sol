// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface CompositeToken {

    function registeredToken(address _user) external view returns (address _token);

    function registerAccount(address _token) external;
}
