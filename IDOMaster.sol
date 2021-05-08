pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./IDOPool.sol";

contract IDOMaster is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Burnable;
    using SafeERC20 for ERC20;

    ERC20Burnable public feeToken;
    address public feeWallet;
    uint256 public feeAmount;
    uint256 public burnPercent;
    uint256 public divider;

    event IDOCreated(address owner, address idoPool,
        uint256 tokenPrice,
        address rewardToken,
        uint256 startTimestamp,
        uint256 finishTimestamp,
        uint256 startClaimTimestamp,
        uint256 minEthPayment,
        uint256 maxEthPayment,
        uint256 maxDistributedTokenAmount);

    event TokenFeeUpdated(address newFeeToken);
    event FeeAmountUpdated(uint256 newFeeAmount);
    event BurnPercentUpdated(uint256 newBurnPercent, uint256 divider);
    event FeeWalletUpdated(address newFeeWallet);

    constructor(
        ERC20Burnable _feeToken,
        address _feeWallet,
        uint256 _feeAmount,
        uint256 _burnPercent
    ) public {
        feeToken = _feeToken;
        feeAmount = _feeAmount;
        feeWallet = _feeWallet;
        burnPercent = _burnPercent;
        divider = 100;
    }

    function setFeeToken(address _newFeeToken) external onlyOwner {
        require(isContract(_newFeeToken), "New address is not a token");
        feeToken = ERC20Burnable(_newFeeToken);

        emit TokenFeeUpdated(_newFeeToken);
    }

    function setFeeAmount(uint256 _newFeeAmount) external onlyOwner {
        feeAmount = _newFeeAmount;

        emit FeeAmountUpdated(_newFeeAmount);
    }

    function setFeeWallet(address _newFeeWallet) external onlyOwner {
        feeWallet = _newFeeWallet;

        emit FeeWalletUpdated(_newFeeWallet);
    }

    function setBurnPercent(uint256 _newBurnPercent, uint256 _newDivider)
        external
        onlyOwner
    {
        require(_newBurnPercent <= _newDivider, "Burn percent must be less than divider");
        burnPercent = _newBurnPercent;
        divider = _newDivider;

        emit BurnPercentUpdated(_newBurnPercent, _newDivider);
    }

    function createIDO(
        uint256 _tokenPrice,
        ERC20 _rewardToken,
        uint256 _startTimestamp,
        uint256 _finishTimestamp,
        uint256 _startClaimTimestamp,
        uint256 _minEthPayment,
        uint256 _maxEthPayment,
        uint256 _maxDistributedTokenAmount
    ) external {
        if(feeAmount > 0){
            uint256 burnAmount = feeAmount.mul(burnPercent).div(divider);

            feeToken.safeTransferFrom(
                msg.sender,
                feeWallet,
                feeAmount.sub(burnAmount)
            );
            feeToken.safeTransferFrom(msg.sender, address(this), burnAmount);
            feeToken.burn(burnAmount);
        }
        IDOPool idoPool =
            new IDOPool(
                _tokenPrice,
                _rewardToken,
                _startTimestamp,
                _finishTimestamp,
                _startClaimTimestamp,
                _minEthPayment,
                _maxEthPayment,
                _maxDistributedTokenAmount
            );
        idoPool.transferOwnership(msg.sender);

        _rewardToken.safeTransferFrom(
            msg.sender,
            address(idoPool),
            _maxDistributedTokenAmount
        );

        emit IDOCreated(msg.sender, 
                        address(idoPool),
                        _tokenPrice,
                        address(_rewardToken),
                        _startTimestamp,
                        _finishTimestamp,
                        _startClaimTimestamp,
                        _minEthPayment,
                        _maxEthPayment,
                        _maxDistributedTokenAmount);
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}