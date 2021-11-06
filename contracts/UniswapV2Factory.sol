pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs; // token A, token B (토큰 페어)를 교환하기 위한 컨트랙트 주소 리스트

    event PairCreated(address indexed token0, address indexed token1, address pair, uint); //페어 만들었을때 

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter; // 시작될때 시행되는 생성자 함수. 수수료를 누구에게 보낼 지 설정. 
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }// 페어가 몇개 등록되어 있는지

    function createPair(address tokenA, address tokenB) external returns (address pair) { // input :교환하려는 토큰의 주소 를 인자로 받고, output: pair 교환하는 contract의 address 를 반환 . 
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);// 토큰의 주소를 오름차순으로 배열. 
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');//0이 가장 작은 주소 1은 확인 할 필요가 없음. 
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient // 기존에 없는 컨트랙트인지 확인 
        bytes memory bytecode = type(UniswapV2Pair).creationCode; 
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));// abi.encodepacked : 코드를 해석하는 과정. 
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        } // 새로 만드는 페어에 주소를 부여하는 과정. 
        IUniswapV2Pair(pair).initialize(token0, token1);//다른 컨트랙트에 있는 함수 실행. 
        getPair[token0][token1] = pair; // 매핑에 페어의 주소를 저장. 
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);// 배열에다가 주소를 push
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external { // input: 주소를 받음. 
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN'); // 자격 검증하는 과정. constructor 에서 설정됨. 
        feeTo = _feeTo; // 해당 페어에서 발생하는 수수료를 누구에게 줄까를 정함. 
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN'); // feetosetter 권한을 남에게 넘겨주는 함수. 
        feeToSetter = _feeToSetter;
    }
}
