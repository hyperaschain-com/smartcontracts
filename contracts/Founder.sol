// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Founder is Ownable,ReentrancyGuard

{
    using SafeERC20 for ERC20;
    ERC20 public sellToken;
    uint256 public salePrice;
    uint256 public saleDiv;
    ERC20 public buyToken;


    uint8 public currentRound;
    bool public tokenGenerationEvent = false;

    event ReleaseMyToken(uint256 _index);
    event ReleaseMyTokenEvent(uint256 _index);
    event TransferAndLock(address _lockedAddress,uint256 _amount,uint _releaseDays);
    event TransferAndLockEvent(address _address,uint256 _amount);
    event SetTokenGenerationEvent(bool _event);
    event SetPercentRelease(uint8 _index, uint8 _percent);
    event SetTotalTokenByRound(uint8 _index, uint256 _quantity);
    event SetCurrentRound(uint8 _round);
    event SetSalePrice(uint256 _salePrice, uint256 _saleDiv);
    event ChangeBuyToken(ERC20 _token) ;
    event ReleaseAllMyTokenEvent();
    


    
    struct LockItemByTime
    {
        uint256 amount;
        uint releaseDate;
        uint isRelease;
    }
    mapping (address => LockItemByTime[]) public lockListByTime;

    struct LockItemByEvent
    {
        uint256 amount;
        uint isRelease;
    }
    mapping (address => LockItemByEvent[]) public lockListByEvent;

    // round0: 90%, round1: 85, round2: 85
    uint8[] public percentRelease = [90, 85, 85];
    uint8[] public timesRelease = [12, 10, 9];
    uint256 public totalTokenSold;
    uint256[] public totalTokenByRound = [5_000_000_000 * (10**uint256(18)), 16_000_000_000 * (10**uint256(18)), 32_000_000_000 * (10**uint256(18)), 33_200_000_000 * (10**uint256(18))];
    
    
    constructor(ERC20 _sellToken,ERC20 _buyToken) {
        sellToken = _sellToken;
        buyToken = _buyToken;
        salePrice = 1;
        saleDiv = 1000;
        currentRound = 0;
    }

    function setTokenGenerationEvent(bool _tokenGenerationEvent)  external onlyOwner {
        tokenGenerationEvent = _tokenGenerationEvent;
        emit SetTokenGenerationEvent(tokenGenerationEvent);
    }

    function setPercentRelease(uint8 _index, uint8 _percent) external onlyOwner {
        percentRelease[_index] = _percent;
        emit SetPercentRelease(_index, _percent);
    }

    function setTotalTokenByRound(uint8 _index, uint256 _quantity) external onlyOwner {
        totalTokenByRound[_index] = _quantity;
        emit SetTotalTokenByRound(_index, _quantity);
    }

    function setCurrentRound(uint8 _round) external onlyOwner{
        currentRound = _round;
        emit SetCurrentRound(currentRound);
    }


    function buy(uint256 _amount)   external nonReentrant { 

        uint256 cost = _amount*salePrice/saleDiv;
        buyToken.safeTransferFrom(msg.sender, address(this), cost);

        if(totalTokenSold>totalTokenByRound[0]&&totalTokenSold<=totalTokenByRound[1])
        {
            currentRound = 1;
        }
        else if(totalTokenSold>totalTokenByRound[1]&&totalTokenSold<=totalTokenByRound[2])
        {
            currentRound = 2;
        }
        else if(totalTokenSold>totalTokenByRound[2]&&totalTokenSold<=totalTokenByRound[3])
        {
            currentRound = 3;
        }
        else{}
        
        if(currentRound>=0 && currentRound<3)
        {
            uint8 currentPercent = percentRelease[currentRound];
            uint256 tempAmount = _amount*currentPercent/100;
            uint8 currentTimes = timesRelease[currentRound];
            uint256 lockAmount = tempAmount/currentTimes;
            
            transferAndLockEvent(msg.sender, _amount-tempAmount);
            totalTokenSold += _amount-tempAmount;

            for(uint256 i = 1; i <= currentTimes; i++)
            {
                transferAndLock(msg.sender, lockAmount, 30*i);
            }
            
            totalTokenSold += tempAmount;
        }
        else if(currentRound == 3)
        {
            sellToken.safeTransfer(msg.sender, _amount);
            totalTokenSold += _amount;
        }
        else{}
        
        
    }
    function setSalePrice(uint256 _salePrice, uint256 _saleDiv) external onlyOwner {
        salePrice = _salePrice;
        saleDiv = _saleDiv;
        emit SetSalePrice(salePrice, saleDiv);
        
    }
    function changeSellToken(ERC20 _token) external onlyOwner {
        sellToken = _token;
    }

    function changeBuyToken(ERC20 _token) external onlyOwner {
        buyToken = _token;
        emit ChangeBuyToken(_token);
    }     

    function getLockedAmountAt(address _lockedAddress, uint256 _index) public view returns(uint256 _amount)
	{
	    return lockListByTime[_lockedAddress][_index].amount;
	}

    function getLockedEventAmountAt(address _lockedAddress, uint256 _index) public view returns(uint256 _amount)
    {
        return lockListByEvent[_lockedAddress][_index].amount;
    }

    function getLockedIsReleaseAt(address _lockedAddress, uint256 _index) public view returns(uint256 _isRelease)
	{  
	    return lockListByTime[_lockedAddress][_index].isRelease;
	}
    function getLockedEventIsReleaseAt(address _lockedAddress, uint256 _index) public view returns(uint256 _isRelease)
    {
        return lockListByEvent[_lockedAddress][_index].isRelease;
    }
    function getLockedTimeAt(address _lockedAddress, uint256 _index) public view returns(uint256 _time)
	{
        return lockListByTime[_lockedAddress][_index].releaseDate;
	}


    function getLockedListSize(address _lockedAddress) internal view returns(uint256 _length)
    {
            return lockListByTime[_lockedAddress].length;
    }

    function getLockedEventListSize(address _lockedAddress) internal view returns(uint256 _length)
    {
            return lockListByEvent[_lockedAddress].length;
    }

	function getAvailableAmount(address _lockedAddress) external view returns(uint256 _amount)
	{
	    uint256 availabelAmount =0;
	    for(uint256 j = 0;j<getLockedListSize(_lockedAddress);j++)
	    {
            uint isRelease = getLockedIsReleaseAt(_lockedAddress, j);
	        uint256 releaseDate = getLockedTimeAt(_lockedAddress,j);
	        if(releaseDate<=block.timestamp&&isRelease==0)
	        {
	            uint256 temp = getLockedAmountAt(_lockedAddress,j);
	            availabelAmount += temp;
	        }
	    }
	    return availabelAmount;
	}

    function getAvailableEventAmount(address _lockedAddress) external view returns(uint256 _amount)
    {
        uint256 availabelAmount =0;
        for(uint256 j = 0;j<getLockedEventListSize(_lockedAddress);j++)
        {
            uint isRelease = getLockedEventIsReleaseAt(_lockedAddress, j);
            if(isRelease==0)
            {
                uint256 temp = getLockedEventAmountAt(_lockedAddress,j);
                availabelAmount += temp;
            }
        }
        return availabelAmount;
    }

    function getLockedFullAmount(address _lockedAddress) external view returns(uint256 _amount)
    {
        uint256 lockedAmount =0;
        for(uint256 j = 0;j<getLockedListSize(_lockedAddress);j++) {
                    
            uint256 temp = getLockedAmountAt(_lockedAddress,j);
            lockedAmount += temp;
            
        }
        return lockedAmount;
    }

    function getLockedEventFullAmount(address _lockedAddress) external view returns(uint256 _amount)
    {
        uint256 lockedAmount =0;
        for(uint256 j = 0;j<getLockedEventListSize(_lockedAddress);j++) {
                    
            uint256 temp = getLockedEventAmountAt(_lockedAddress,j);
            lockedAmount += temp;
            
        }
        return lockedAmount;
    }

    function transferAndLock(address _lockedAddress,uint256 _amount,uint _releaseDays) internal
    {
        uint releasedDate = block.timestamp + _releaseDays * (1 days);
        LockItemByTime memory  lockItemByTime = LockItemByTime({amount:_amount, releaseDate:releasedDate,isRelease:0});
        lockListByTime[_lockedAddress].push(lockItemByTime);

        emit TransferAndLock(_lockedAddress, _amount, _releaseDays);
    }

    function transferAndLockEvent(address _lockedAddress,uint256 _amount) internal
    {
        
        LockItemByEvent memory  lockItemByEvent = LockItemByEvent({amount:_amount, isRelease:0});
        lockListByEvent[_lockedAddress].push(lockItemByEvent);

        emit TransferAndLockEvent(_lockedAddress, _amount);
    }


    function releaseMyToken(uint256 _index) public
    {
        if(getLockedTimeAt(msg.sender,_index)<=block.timestamp && getLockedIsReleaseAt(msg.sender,_index)==0)
        {
            lockListByTime[msg.sender][_index].isRelease=1;
            sellToken.safeTransfer(msg.sender, lockListByTime[msg.sender][_index].amount);
        }
        emit ReleaseMyToken(_index);

    }

    modifier  onTokenGenerationEvent{
        require(tokenGenerationEvent == true, "tokenGenerationEvent is false");
        _;
    }


    function releaseMyTokenEvent(uint256 _index) onTokenGenerationEvent public 
    {
        if(getLockedEventIsReleaseAt(msg.sender,_index)==0)
        {
            lockListByEvent[msg.sender][_index].isRelease=1;
            sellToken.safeTransfer(msg.sender, lockListByEvent[msg.sender][_index].amount);
        }
        emit ReleaseMyTokenEvent(_index);

    }

    function releaseAllMyToken() external
    {
        for(uint256 i=0; i<getLockedListSize(msg.sender); i++)
        {
            releaseMyToken(i);
        } 

    }

    function releaseAllMyTokenEvent() onTokenGenerationEvent external
    {
        for(uint256 i=0; i<getLockedEventListSize(msg.sender); i++)
        {
            releaseMyTokenEvent(i);
        } 
        emit ReleaseAllMyTokenEvent();
    }
    
    function withdraw() external onlyOwner {
       require(address(msg.sender) != address(0), "msg.sender is 0");
       address payable sender = payable(address(msg.sender));
       sender.transfer(address(this).balance);
    }

    function withdrawErc20(ERC20 token) external onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

}
