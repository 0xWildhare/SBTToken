// contracts/SBToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
  *this implementation of the ERC20 standard requires modification to stopTime
  *of the basic functions in the standard, namely the 'balanceOf', transfer, and ???
  *functions. Since some of these functions are not virtual in the standard ERC20
  *contract from OpenZeppelin, that contract would have had to be modified to be used
  *as a parent to this one. for simplicity, the entire ERC20 contract from OppenZepplin
  *was copied into this file, and the necessary functions modified accordingly.
  */


contract SBToken is IERC20, ReentrancyGuard, Ownable {
  /*
  *This section is unaltered from ERC20.
  */
  using SafeMath for uint256;
//  using Address for address;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name = 'Slow Burn Token v0.3';
  string private _symbol = 'SB3';
  uint8 private _decimals = 18;


  /**
    *****These items adapted from Sablier******

   * @notice Counter for new stream ids.
   */
  uint256 public nextStreamId;

  //for person to person streams
  struct Stream {
    uint256 amount;
    uint256 ratePerSecond;
    uint256 remainingBalance;
    uint256 startTime;
    uint256 stopTime;
    address recipient;
    address sender;
    //address tokenAddress;
    bool isEntity;
  }

  /*
    * for the streamsIndex mapping, the stream indicies stored in the array will be:
    * 0 - P2P sender,
    * 1 - to burn,
    * 2 - To Bonding,
    * 3 - from Bonding,
    * 4 - P2P recipient,
    */

  mapping(address => uint[5]) private streamsIndex;

  /**
   * @notice The stream objects identifiable by their unsigned integer ids.
   */
  mapping(uint256 => Stream) private streams;


      /**
    * @dev Throws if the provided id does not point to a valid stream.
    */
    modifier streamExists(uint256 streamId) {
      require(streams[streamId].isEntity, "stream does not exist");
      _;
    }

      address private _bondingContract;
      address private _couponContract;
      //for the remainders from streamSenders
      address private _dustCollector;

      //global stream time set by DAO
      uint public globalStreamTime = 25000; //approx 7 days

      /* global stream time modifier (pay for shorter times)
        * number is in 1/1000ths i.e. 1000 = 1, 800 = 0.8x
        * only affects to DAO and 0x0 stream times
        */
      mapping(address => uint) private streamTimeModifier;

/*
  ***CONTRACT LOGIC STARTS HERE***
  */

    constructor(uint256 initialSupply) public {
        _mint(msg.sender, initialSupply); //Mints initial supply to deployer
        nextStreamId = 1; //from Sablier
        _bondingContract = msg.sender;
        _couponContract = msg.sender;
        _dustCollector = msg.sender;
    }

    /*
      * onlyOwner functions
      */


    function changeCouponContract(address newCouponContract) public onlyOwner {
      _couponContract = newCouponContract;
    }

    function changeBondingContract(address newBondingContract) public onlyOwner {
      _bondingContract = newBondingContract;
    }

    function changeDustCollector(address newDustCollector) public onlyOwner {
      _dustCollector = newDustCollector;
    }

    function getBondingContract() public view returns(address){
      return _bondingContract;
    }

    function getCouponContract() public view returns(address){
      return _couponContract;
    }

    function getDustCollector() public view returns(address){
      return _dustCollector;
    }

    function getStreamIndicies(address _address) public view returns(uint[5] memory) {
      return streamsIndex[_address];
    }

    /*
      * changes the streamrate to the DAO, or to 0x0, only settable by DAO
      * uints are Gwei/second.
      */
    function globalChangeStreamTime(uint newTime) public onlyOwner {
      require(newTime != 0, "time cannot be 0");
      globalStreamTime = newTime;
    }

    /*
      *changes the stream time modifier for a specific address
      */
    function globalChangeStreamTimeModifier(address _address, uint _modifier) public onlyOwner{
      streamTimeModifier[_address] = _modifier;
    }

    function checkModifier(address _address) public view returns (uint) {
      return(streamTimeModifier[_address]);
    }

    function mint(uint amount) public {
      address owner = owner();
      require(msg.sender == owner || msg.sender == _bondingContract || msg.sender == _couponContract, "cannot mint");
      _mint(msg.sender, amount);
    }

/*
  ****the following functions (balanceOf, _beforeTokenTransfer) are heavily modified from ERC20***
  */

    function balanceOf(address account) public view override returns (uint256) {
        uint calculatedBalance = _balances[account];

        //if there are send streams for account, calculate accordingly
        for(uint i = 0; i <= 2; i++){
          if(streamsIndex[account][i] != 0) {
            uint sentBalance = _getStreamSentBalance(streamsIndex[account][i]);
            calculatedBalance = calculatedBalance.sub(sentBalance);
          }
        }
        //if there are recieve streams for account, calculate accordingly
        for(uint i = 3; i <= 4; i++){
          if(streamsIndex[account][i] != 0) {
            uint recievedBalance = _getStreamSentBalance(streamsIndex[account][i]);
            calculatedBalance = calculatedBalance.add(recievedBalance);
          }
        }
        return calculatedBalance;
      }


      //this function cleans up redundant code in  the balanceOf function
      function _getStreamSentBalance(uint streamId) internal view returns(uint) {
        Stream memory stream = streams[streamId];
        uint delta = deltaOf(streamId);
        uint sentBalance = delta.mul(stream.ratePerSecond);

        /*
        * If the stream `balance` does not equal `amount`, it means there have been withdrawals.
        * We have to subtract the total amount withdrawn from the amount of money that has been
        * streamed until now.
        */
          if (stream.amount > stream.remainingBalance) {
            uint totalSent = stream.amount.sub(stream.remainingBalance);
            sentBalance = sentBalance.sub(totalSent);
          }
        return(sentBalance);
      }

      /**
       * @dev Hook that is called before any transfer of tokens. This includes
       * minting and burning.
       *
       * Calling conditions:
       *
       * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
       * will be to transferred to `to`.
       * - when `from` is zero, `amount` tokens will be minted for `to`.
       * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
       * - `from` and `to` are never both zero.
       *
       * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
           */
      function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal virtual {
        //update all sender and recipient streams
        for(uint i = 0; i <= 4; i++){
          if(streams[streamsIndex[sender][i]].isEntity) updateStream(streamsIndex[sender][i]);
          if(streams[streamsIndex[recipient][i]].isEntity) updateStream(streamsIndex[recipient][i]);
        }

        //require sender has enough to cover remaining balance after sending amount.
        //unless its the mint function, thus coming from 0
        uint sendersStreamRemainingBalance;
        for(uint i = 0; i <= 2; i++){
          sendersStreamRemainingBalance = sendersStreamRemainingBalance.add(
            streams[streamsIndex[sender][i]].remainingBalance);
        }
        uint sendersAvailableBalance = _balances[sender].sub(sendersStreamRemainingBalance);
        if(sender != address(0)) require(sendersAvailableBalance >= amount, "not enough money");
       }

       /*
        *This function is a new creation to help bridge the gap between the sablier
        *functionality and the ERC20 standard.
        */
      function updateStream(uint streamId) public streamExists(streamId) {
          Stream storage stream = streams[streamId];
          uint streamedBalance = _getStreamSentBalance(streamId);
          stream.remainingBalance = stream.remainingBalance.sub(streamedBalance);

          _balances[stream.sender] = _balances[stream.sender].sub(streamedBalance);
          _balances[stream.recipient] = _balances[stream.recipient].add(streamedBalance);

          /*
            * these lines only used if streams to/from 0x0 are allowed
            * in the current rev, they are not - so they are commented out
            *
          if(stream.sender == address(0)) _totalSupply = _totalSupply.add(streamedBalance);
          if(stream.recipient == address(0)) _totalSupply = _totalSupply.sub(streamedBalance);
            *
            */

          emit Transfer(stream.sender, stream.recipient, streamedBalance);

          if (stream.remainingBalance == 0){
            _killStream(streamId);
          }
      }

        /*
          * this function can be used to cancel the stream - this will most likely
          * be limited to the DAO, the stream sender and the stream recipient.
          */
      function cancelStream(uint _streamId) public {
        address owner = owner();
        Stream memory stream = streams[_streamId];
        require(msg.sender == owner || msg.sender == stream.sender || msg.sender == stream.recipient, "not authorized to cancel this stream");
        require(stream.recipient != _bondingContract || msg.sender == _bondingContract, 'use bondingContract');
        require(stream.sender != _bondingContract || msg.sender == _bondingContract, 'use bondingContract');
        updateStream(_streamId);
        _killStream(_streamId);

      }

      event StreamEnded(uint streamId);

      function _killStream(uint _streamId) private {
        Stream memory stream = streams[_streamId];
        if(streamsIndex[stream.recipient][3] == _streamId) delete streamsIndex[stream.recipient][3];
        else if (streamsIndex[stream.sender][1] == _streamId) delete streamsIndex[stream.sender][1];
        else if (streamsIndex[stream.sender][2] == _streamId) delete streamsIndex[stream.sender][2];
        else {
          delete streamsIndex[stream.sender][0];
          delete streamsIndex[stream.recipient][4];
        }
        delete streams[_streamId];
        emit StreamEnded(_streamId);
      }


      /* stream amounts must be divisible by the stream duration.
        * to avoid unwanted errors when creating streams (improving UX),
        * the remainder is removed from the amount, and the dust set to the
        * dustCollector contract - use tbd by DAO.
        * users should avoid long stream times, as can will generate larger remainders
        */

      function _collectDust(address sender, uint amount, uint duration) private returns(uint newAmount) {
        uint dust = amount % duration;
        _balances[sender] = _balances[sender].sub(dust);
        _balances[_dustCollector] = _balances[_dustCollector].add(dust);
        newAmount = amount.sub(dust);
        emit Transfer(sender, _dustCollector, dust);
      }


      event StreamEdited(uint streamId);

      function editStream(uint streamId, uint amount) public streamExists(streamId){
        Stream memory stream = streams[streamId];
        _beforeTokenTransfer(msg.sender, stream.recipient, amount);
        require(msg.sender == stream.sender, "not authorized to modify");

        uint duration = stream.stopTime.sub(block.timestamp);

        _createStream(msg.sender, stream.recipient, amount, duration, streamId);

        emit StreamEdited(streamId);
        }


/*
****this section is adapted from Sablier***

*/
      event StreamCreated(uint streamId);

      function _createStream(
        address sender,
        address recipient,
        uint256 amount,
        uint256 duration,
        uint256 streamId
        )
        private {
          require(recipient != sender, "cannot stream to self");
          require(recipient != address(0), "cannot stream to 0x0");
          require(amount > 0, "amount is zero");
          require(amount >= duration, "amount < time delta");
          amount = _collectDust(sender, amount, duration);

          uint ratePerSecond = amount.div(duration);
          uint stopTime = block.timestamp.add(duration);

          streams[streamId] = Stream({
            remainingBalance: amount,
            amount: amount,
            isEntity: true,
            ratePerSecond: ratePerSecond,
            recipient: recipient,
            sender: sender,
            startTime: block.timestamp,
            stopTime: stopTime
            });
      }

      function createStream(address recipient, uint256 amount, uint256 duration)
          public
          nonReentrant
          returns (uint256)
      {
              require(recipient != address(this), "cannot stream to the contract");
              require(recipient != _couponContract, "use streamToCouponContract method");
              require(recipient != _bondingContract, "use streamToBondingContract method");
            /*
              *unique senders and recipients(each address can have only one sender stream and one recipient
              *stream) simplifies much of the other logic. If it is necessary for each address to have multiple
              *streams then a workaround would be to change the streamSenders and streamRecipients mappings
              *to map an array to each address, and iterate through these in the balanceOf and _beforeTokenTransfer
              *functions as necessary. the 0x0 address can recieve multiple streams.
              */
              _beforeTokenTransfer(msg.sender, recipient, amount);
              require(streamsIndex[msg.sender][0] == 0, "Can only send one stream");
              require(streamsIndex[recipient][4] == 0, "Can only recieve one stream");

              /* Create and store the stream object. */
              uint256 streamId = nextStreamId;
              _createStream(msg.sender, recipient, amount, duration, streamId);

                  streamsIndex[msg.sender][0] = streamId;
                  streamsIndex[recipient][4] = streamId;

                  nextStreamId = nextStreamId.add(1);
                  emit StreamCreated(streamId);
                  return(streamId);
        }

        event StreamToBondingCreated(uint streamId);

        function createStreamToBonding(address sender, uint amount) external returns(uint){
          require(msg.sender == _bondingContract, "!bondingContract");

          uint _globalStreamTime = globalStreamTime;
          if(streamTimeModifier[sender] != 0) {
            _globalStreamTime = (globalStreamTime.div(1000)).mul(streamTimeModifier[sender]);
          }

          _beforeTokenTransfer(sender, _bondingContract, amount);
          require(streamsIndex[sender][2] == 0, "sender has existing stream");

          /* Create and store the stream object. */
          uint256 streamId = nextStreamId;
          _createStream(sender, _bondingContract, amount, _globalStreamTime, streamId);
          streamsIndex[sender][2] = streamId;

          nextStreamId = nextStreamId.add(1);
          emit StreamToBondingCreated(streamId);
          return(streamId);
        }

        event StreamToBurnCreated(uint streamId);

        function createStreamToBurn(uint amount) public returns(uint){

          uint _globalStreamTime = globalStreamTime;
          if(streamTimeModifier[msg.sender] != 0) {
            _globalStreamTime = (globalStreamTime.div(1000)).mul(streamTimeModifier[msg.sender]);
          }

          _beforeTokenTransfer(msg.sender, _couponContract, amount);
          require(streamsIndex[msg.sender][1] == 0, "sender has existing stream");

          /* Create and store the stream object. */
          uint256 streamId = nextStreamId;
          _createStream(msg.sender, _couponContract, amount, _globalStreamTime, streamId);
          streamsIndex[msg.sender][1] = streamId;

          nextStreamId = nextStreamId.add(1);
          emit StreamToBurnCreated(streamId);
          return(streamId);
        }

        event StreamFromBondingCreated(uint streamId);

        function createStreamFromBonding(address recipient, uint amount, uint duration) public returns(uint){
          require(msg.sender == _bondingContract, '!bondingContract');
          _beforeTokenTransfer(_bondingContract, recipient, amount);
          require(streamsIndex[recipient][3] == 0, "recipient has existing stream");

          /* Create and store the stream object. */
          uint256 streamId = nextStreamId;
          _createStream(_bondingContract, recipient, amount, duration, streamId);
          streamsIndex[recipient][3] = streamId;

          nextStreamId = nextStreamId.add(1);
          emit StreamFromBondingCreated(streamId);
          return(streamId);
        }




        function getStream(uint256 streamId)
          external
          view
          streamExists(streamId)
          returns (
              address sender,
              address recipient,
              uint256 amount,
              uint256 startTime,
              uint256 stopTime,
              uint256 remainingBalance,
              uint256 ratePerSecond
          )
          {
              sender = streams[streamId].sender;
              recipient = streams[streamId].recipient;
              amount = streams[streamId].amount;
              startTime = streams[streamId].startTime;
              stopTime = streams[streamId].stopTime;
              remainingBalance = streams[streamId].remainingBalance;
              ratePerSecond = streams[streamId].ratePerSecond;
          }




    /*
    *This function is copied directly from Sablier.sol
    */

    /**
       * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
       *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
       *  `startTime`, it returns 0.
       * @dev Throws if the id does not point to a valid stream.
       * @param streamId The id of the stream for which to query the delta.
       * gives The time "delta" in seconds.
       */
    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
      Stream memory stream = streams[streamId];
      if (block.timestamp <= stream.startTime) return 0;
      if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
      return stream.stopTime - stream.startTime;
    }


/**
  *the remainder of this contract is copied directly from the OppenZepplin ERC20.solidity
  */

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */

     /*
     *replaced above
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    */

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
         _transfer(_msgSender(), recipient, amount);
         return true;
     }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
*/


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    }
