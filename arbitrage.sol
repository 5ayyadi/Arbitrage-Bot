pragma solidity >=0.5.0;


/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract ArbitrageBot is Ownable {

    uint16 public gasPercent;
    address[] public factories;
    mapping(address => uint16) lpFees;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event Swap(
        address indexed fromToken,
        address indexed toToken,
        uint amountIn,
        uint amountOut
        );

    function setGasPercent(uint16 _percentage) external onlyOwner {
      gasPercent = _percentage;
    }

    function addFactories(address[] memory _factories, uint16[] memory _fees) public onlyOwner {
        for (uint i = 0; i < _factories.length; i++) {
          factories.push(_factories[i]);
          lpFees[_factories[i]] = _fees[i];
      }
    }

    function allFactories() public view returns(address[] memory){
        return factories;
    }

    function getFee(address _factory) public view returns(uint16){
      return factories[_factory];
    }

    function swapUsingStableCoin(address _stableCoin,uint _amountIn) external payable{
      (address firstPair, uint middleAmount) = _bestPair(WETH, _stableCoin, _amountIn);
      (address secondPair, uint amountOut) = _bestPair(_stableCoin, WETH, middleAmount);
      require(amountOut > _amountIn, "Amount Out less than amount in");
      uint difference = amountOut - _amountIn;
      // spend 50% of difference as gas.
      uint gas = gasPercent * difference / 1000;
      require(gas >= tx.gas, "Gas is higher than difference, no benefits.");
      emit Swap(WETH, _stableCoin, WETH, amountOut);
    }

    // gas must be passed in dollars.
    function swapUsingEth(address _tokenIn, address _tokenOut, uint _amountIn, uint _gas) external payable{
        // find best pair between token0 and native token
        (address firstPair,uint middleAmount) = _bestPair(_tokenIn, WETH, _amountIn);
        (address secondPair,uint amountOut) = _bestPair(WETH, _tokenOut, middleAmount);
        require(amountOut > _amountIn, "Amount Out less than amount in");
        // calculate difference in native token.
        uint difference = amountOut - _amountIn;
        // spend 50% of difference as gas.
        uint gas = gasPercent * difference / 1000;
        require(gas >= _gas, "Gas is higher than difference, no benefits.");
        // call _swap function
        emit Swap(_tokenIn, _tokenOut, _amountIn, amountOut);
    }

    function _bestPair(address _token0, address _token1, uint _amountIn) internal view returns(address, uint){
        uint bestAmount = uint(0);
        address bestPair = address(0);
        uint _reserve0;
        uint _reserve1;
        address pair;
        uint16 fee;
        uint _aOut;
        for (uint i = 0; i < factories.length; i++) {
            pair = IUniswapV2Factory(factories[i]).getPair(_token0, _token1);
            fee = getFee(factories[i]);
            uint _aIn = _amountIn * fee / (10**4);
            (_reserve0, _reserve1,) = IUniswapV2Pair(pair).getReserves();
            if(_token0 == IUniswapV2Pair(pair).token0()){
            /// @dev should always pass starting token as first parameter
              _aOut = _calculate_amount_out(_reserve0, _reserve1, _aIn);
            } else {
              _aOut = _calculate_amount_out(_reserve1, _reserve0, _aIn);
            }
            if (_aOut >= bestAmount){
              bestAmount = _aOut;
              bestPair = pair;
            }
        }
        return (bestPair, bestAmount);
    }

    function _calculate_amount_out(uint _reserve0, uint _reserve1, uint _amountIn) internal pure returns(uint){
      uint K = _reserve0 * _reserve1;
      return _reserve1 - (K / (_reserve0 + _amountIn));
    }

    function Withdraw(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            require(IERC20(_token).transfer(owner(), balance));
        }
    }

}