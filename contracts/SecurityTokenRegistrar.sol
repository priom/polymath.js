pragma solidity ^0.4.18;

/*
  The Polymath Security Token Registrar provides a way to lookup security token details
  from a single place and allows wizard creators to earn POLY fees by uploading to the
  registrar.
*/

import './interfaces/ISTRegistrar.sol';
import './interfaces/IERC20.sol';
import './SecurityToken.sol';
import './Compliance.sol';

/**
 * @title SecurityTokenRegistrar
 * @dev Contract use to register the security token on Polymath platform
 */

contract SecurityTokenRegistrar is ISTRegistrar {

    string public VERSION = "1";
    SecurityToken securityToken;
    address public polyTokenAddress;                                // Address of POLY token
    address public polyCustomersAddress;                            // Address of the polymath-core Customers contract address
    address public polyComplianceAddress;                           // Address of the polymath-core Compliance contract address

    // Security Token
    struct SecurityTokenData {                                      // A structure that contains the specific info of each ST
      uint256 totalSupply;                                          // created ever using the Polymath platform
      address owner;
      uint8 decimals;
      string ticker;
      uint8 securityType;
    }
    mapping(address => SecurityTokenData) securityTokens;           // Array contains the details of security token corresponds to security token address
    mapping(string => address) tickers;                             // Mapping of ticker name to Security Token

    event LogNewSecurityToken(string ticker, address securityTokenAddress, address owner, address host, uint256 fee, uint8 _type);
    /**
     * @dev Constructor use to set the essentials addresses to facilitate
     * the creation of the security token
     */
    function SecurityTokenRegistrar(
      address _polyTokenAddress,
      address _polyCustomersAddress,
      address _polyComplianceAddress
    ) public
    {
      polyTokenAddress = _polyTokenAddress;
      polyCustomersAddress = _polyCustomersAddress;
      polyComplianceAddress = _polyComplianceAddress;
      // Creating the instance of the compliance contract and assign the STR contract 
      // address (this) into the compliance contract
      Compliance PolyCompliance = Compliance(polyComplianceAddress);
      require(PolyCompliance.setRegsitrarAddress(this));
    }

    /**
     * @dev Creates a new Security Token and saves it to the registry
     * @param _name Name of the security token
     * @param _ticker Ticker name of the security
     * @param _totalSupply Total amount of tokens being created
     * @param _decimals Decimals value for token
     * @param _owner Ethereum public key address of the security token owner
     * @param _maxPoly Amount of maximum poly issuer want to raise
     * @param _host The host of the security token wizard
     * @param _fee Fee being requested by the wizard host
     * @param _type Type of security being tokenized
     * @param _lockupPeriod Length of time raised POLY will be locked up for dispute
     * @param _quorum Percent of initial investors required to freeze POLY raise
     */
    function createSecurityToken (
      string _name,
      string _ticker,
      uint256 _totalSupply,
      uint8 _decimals,
      address _owner,
      uint256 _maxPoly,
      address _host,
      uint256 _fee,
      uint8 _type,
      uint256 _lockupPeriod,
      uint8 _quorum
    ) external
    {
      require(_totalSupply > 0 && _maxPoly > 0 && _fee > 0);
      require(tickers[_ticker] == 0x0);
      require(_lockupPeriod >= now);
      require(_owner != address(0) && _host != address(0));
      require(bytes(_name).length > 0 && bytes(_ticker).length > 0);
      IERC20 POLY = IERC20(polyTokenAddress);
      POLY.transferFrom(msg.sender, _host, _fee);
      address newSecurityTokenAddress = initialiseSecurityToken(_name, _ticker, _totalSupply, _decimals, _owner, _maxPoly, _type, _lockupPeriod, _quorum);
      LogNewSecurityToken(_ticker, newSecurityTokenAddress, _owner, _host, _fee, _type);
    }

    function initialiseSecurityToken(
      string _name,
      string _ticker,
      uint256 _totalSupply,
      uint8 _decimals,
      address _owner,
      uint256 _maxPoly,
      uint8 _type,
      uint256 _lockupPeriod,
      uint8 _quorum
    ) internal returns (address)
    {
      address newSecurityTokenAddress = new SecurityToken(
        _name,
        _ticker,
        _totalSupply,
        _decimals,
        _owner,
        _maxPoly,
        _lockupPeriod,
        _quorum,
        polyTokenAddress,
        polyCustomersAddress,
        polyComplianceAddress
      );
      tickers[_ticker] = newSecurityTokenAddress;
      securityTokens[newSecurityTokenAddress] = SecurityTokenData(
        _totalSupply,
        _owner,
        _decimals,
        _ticker,
        _type
      );
      return newSecurityTokenAddress;
    }

    //////////////////////////////
    ///////// Get Functions
    //////////////////////////////
    /**
     * @dev Get security token address by ticker name
     * @param _ticker Symbol of the Scurity token
     * @return address _ticker
     */
    function getSecurityTokenAddress(string _ticker) public constant returns (address) {
      return tickers[_ticker];
    }

    /**
     * @dev Get Security token details by its ethereum address
     * @param _STAddress Security token address
     */
    function getSecurityTokenData(address _STAddress) public constant returns (
      uint256 totalSupply,
      address owner,
      uint8 decimals,
      string ticker,
      uint8 securityType
    ) {
      return (
        securityTokens[_STAddress].totalSupply,
        securityTokens[_STAddress].owner,
        securityTokens[_STAddress].decimals,
        securityTokens[_STAddress].ticker,
        securityTokens[_STAddress].securityType
      );
    }

}
