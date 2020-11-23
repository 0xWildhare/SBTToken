// contracts/SBTToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
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


contract SBTToken is IERC20, ReentrancyGuard, Ownable {
  /*
  *This section is unaltered from ERC20.
  */
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name = 'Slow Burn Token v.2';
  string private _symbol = 'SB2';
  uint8 private _decimals = 18;


  /**
    *****These items adapted from Sablier******

   * @notice Counter for new stream ids.
   */
  uint256 public nextStreamId;

  //for person to person streams
  struct Stream {
    uint256 deposit;
    uint256 ratePerSecond;
    uint256 remainingBalance;
    uint256 startTime;
    uint256 stopTime;
    address recipient;
    address sender;
    //address tokenAddress;
    bool isEntity;
  }

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


    /*the two mappings help to eliminate a large portion of the sablier logic that wasn't
      *directly applicable to this project, and to allow the balanceOf and transfer (and other)
      * functions to interface according to ERC20 standard.
      */
      mapping(address => uint256) private streamSenders;
      mapping(address => uint256) private streamRecievers;

      //for streams to DAO
      //identifiable by sender address
      mapping(address => uint256) private toDAOStreams;

      //for streams to 0x0
      //identifiable by sender address
      mapping(address => uint256) private to0x0Streams;

      //for streams from DAO
      //identifiable by recipient address
      mapping(address => uint256) private fromDAOStreams;

      //global stream time set by DAO
      uint public globalStreamTime = 2500000; //approx 29 days

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
    }

    /*
      * onlyOwner functions
      */

    function mint(uint amount) public onlyOwner {
      _mint(msg.sender, amount);
    }

    /*
      * changes the streamrate to the DAO, or to 0x0, only settable by DAO
      * uints are Gwei/second.
      */
    function changeStreamTime(uint newTime) public onlyOwner {
      require(newTime != 0, "time cannot be 0");
      globalStreamTime = newTime;
    }

    /*
      *changes the stream time modifier for a specific address
      */
    function changeStreamTimeModifier(address _address, uint _modifier) public onlyOwner{
      streamTimeModifier[_address] = _modifier;
    }

        function checkModifier(address _address) public view returns (uint) {
          address owner = owner();
          require(msg.sender == _address || msg.sender == owner, "not authorized to view");
          return(streamTimeModifier[_address]);
        }

/*
  ****the following functions (balanceOf, _beforeTokenTransfer) are heavily modified from ERC20***
  */

    function balanceOf(address account) public view override returns (uint256) {
        uint calculatedBalance = _balances[account];

        //if there is a send stream for account, modify accordingly (only handles 1 send stream per account)
        if(streamSenders[account] != 0) {
          uint sentBalance = _getStreamSentBalance(streamSenders[account]);
          calculatedBalance = calculatedBalance.sub(sentBalance);
        }

        //if there is a recieve stream for account, modify accordingly
        if(streamRecievers[account] != 0) {
          uint recievedBalance = _getStreamSentBalance(streamRecievers[account]);
          calculatedBalance = calculatedBalance.add(recievedBalance);
        }

        //if there is a stream to DAO for account, modify accordingly
        if(toDAOStreams[account] != 0) {
          uint sentToDAOBalance = _getStreamSentBalance(toDAOStreams[account]);
          calculatedBalance = calculatedBalance.sub(sentToDAOBalance);
        }

        //if there is a stream to 0x0 for account, modify accordingly
        if(to0x0Streams[account] != 0) {
          uint sentTo0x0Balance = _getStreamSentBalance(to0x0Streams[account]);
          calculatedBalance = calculatedBalance.sub(sentTo0x0Balance);
        }

        //if there is a stream to DAO for account, modify accordingly
        if(fromDAOStreams[account] != 0) {
          uint sentfromDAOBalance = _getStreamSentBalance(fromDAOStreams[account]);
          calculatedBalance = calculatedBalance.add(sentfromDAOBalance);
        }

        return calculatedBalance;

      }


      //this function cleans up redundant code in  the balanceOf function
      function _getStreamSentBalance(uint streamId) internal view returns(uint) {
        Stream memory stream = streams[streamId];
        uint delta = deltaOf(streamId);
        uint sentBalance = delta.mul(stream.ratePerSecond);

        /*
        * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
        * We have to subtract the total amount withdrawn from the amount of money that has been
        * streamed until now.
        */
          if (stream.deposit > stream.remainingBalance) {
            uint totalSent = stream.deposit.sub(stream.remainingBalance);
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


      function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {




        if(streams[streamSenders[from]].isEntity) updateStream(streamSenders[from]);
        if(streams[streamRecievers[from]].isEntity) updateStream(streamRecievers[from]);
        if(streams[streamSenders[to]].isEntity) updateStream(streamSenders[to]);
        if(streams[streamRecievers[to]].isEntity)updateStream(streamRecievers[to]);

        //same for DAO streams
        if(streams[toDAOStreams[from]].isEntity) updateStream(toDAOStreams[from]);
        if(streams[toDAOStreams[to]].isEntity) updateStream(toDAOStreams[to]); //don't know that it is necessary to update all of "to's" streams.

        //same for 0x0 streams
        if(streams[to0x0Streams[from]].isEntity) updateStream(to0x0Streams[from]);
        if(streams[to0x0Streams[to]].isEntity) updateStream(to0x0Streams[to]); //don't know that it is necessary to update all of "to's" streams.

        //same for streams from DAO
        if(streams[fromDAOStreams[from]].isEntity) updateStream(fromDAOStreams[from]);
        if(streams[fromDAOStreams[to]].isEntity) updateStream(fromDAOStreams[to]); //don't know that it is necessary to update all of "to's" streams.

        //require sender has enough to cover remaining balance after sending amount.
        //unless its the mint function, thus coming from 0
        uint sendersStreamRemainingBalance =
        streams[streamSenders[from]].remainingBalance.add(  //person to person stream
          streams[toDAOStreams[from]].remainingBalance.add( //to DAO stream
            streams[to0x0Streams[from]].remainingBalance    //to 0x0 stream
            ));

        uint sendersAvailableBalance = _balances[from].sub(sendersStreamRemainingBalance);
        if(from != address(0)) require(sendersAvailableBalance >= amount, "not enough money");
       }

       /*
        *This function is a new creation to help bridge the gap between the sablier
        *functionality and the ERC20 standard.
        */
        function updateStream(uint streamId) public {
            require(streams[streamId].isEntity, "Not an active stream."); //this line should be redundant.
            Stream storage stream = streams[streamId];
            uint streamedBalance = _getStreamSentBalance(streamId);
            stream.remainingBalance = stream.remainingBalance.sub(streamedBalance);
            if(stream.sender != address(0)) _balances[stream.sender] = _balances[stream.sender].sub(streamedBalance);
            if(stream.recipient != address(0)) _balances[stream.recipient] = _balances[stream.recipient].add(streamedBalance);
            if(stream.sender == address(0)) _totalSupply = _totalSupply.add(streamedBalance);
            if(stream.recipient == address(0)) _totalSupply = _totalSupply.sub(streamedBalance);
            emit Transfer(stream.sender, stream.recipient, streamedBalance);

            if (stream.remainingBalance == 0){
              if(fromDAOStreams[stream.recipient] == streamId) delete fromDAOStreams[stream.recipient];
              else if (to0x0Streams[stream.sender] == streamId) delete to0x0Streams[stream.sender];
              else if (toDAOStreams[stream.sender] == streamId) delete toDAOStreams[stream.sender];
              else {
                delete streamSenders[stream.sender];
                delete streamRecievers[stream.recipient];
              }
              delete streams[streamId];
            }

        }

        /*
          * this function can be used to cancel the stream - this will most likely
          * be limited to the DAO, the stream sender and the stream reciever.
          */
        function cancelStream(uint _streamId) public {
          address owner = owner();
          Stream memory stream = streams[_streamId];
          address sender = stream.sender;
          address recipient = stream.recipient;
          require(msg.sender == owner || msg.sender == sender || msg.sender == recipient, "not authorized to cancel this stream");
          updateStream(_streamId);

          if(fromDAOStreams[stream.recipient] == _streamId) delete fromDAOStreams[stream.recipient];
          else if (to0x0Streams[stream.sender] == _streamId) delete to0x0Streams[stream.sender];
          else if (toDAOStreams[stream.sender] == _streamId) delete toDAOStreams[stream.sender];
          else {
            delete streamSenders[stream.sender];
            delete streamRecievers[stream.recipient];
          }
          delete streams[_streamId];
        }

        /*
          *this seems bulky - and does not seem to add much utility over merely canceling and starting
          *a new stream, but it is easy to build, so here it is (probably for testing purposes only).
          *only the deposit value is editable (in this iteration - may change later). also - this seems
          *like ripe territoy for attackers.
          */
        event StreamEdited(uint streamId);

        function editStream(uint _streamId, uint deposit) public {
          Stream memory stream = streams[_streamId];
          _beforeTokenTransfer(msg.sender, stream.recipient, deposit);
          require(streams[_streamId].isEntity, "stream does not exist, or has ended");
          require(msg.sender == stream.sender, "not authorized to modify this stream");
          //require(owner() != stream.recipient, "cannot edit streams to DAO"); //Don't know if this is necessary

          uint remainingDuration = stream.stopTime.sub(block.timestamp);
          uint ratePerSecond = deposit.div(remainingDuration);

          /* edit the stream object. */

          stream.remainingBalance = deposit;
          stream.deposit = deposit;
          stream.isEntity = true;
          stream.ratePerSecond = ratePerSecond;
          stream.recipient = stream.recipient;
          stream.sender = msg.sender;
          stream.startTime = block.timestamp;
          stream.stopTime = stream.stopTime;

          emit StreamEdited(_streamId);
        }


/*
****this section is adapted and simplified from Sablier***
*differences  - takes duration of stream instead of startTime and stopTime
              - does not take token address
              - allows tokens to be streamed to 0x0
              - allows tokens to be streamed to this contracts
              - automatically starts stream at current block timestamp




*/
event StreamCreated(uint streamId);

function createStream(address recipient, uint256 deposit, uint256 duration)
    public
    nonReentrant
    returns (uint256)
{

        require(recipient != msg.sender, "cannot stream to the caller");
        require(recipient != address(this), "cannot stream to the contract");
        require(recipient != owner(), "cannot stream to the DAO");
        require(recipient != address(0), "cannot stream to the 0x0");

        require(deposit > 0, "deposit is zero");

        require(deposit >= duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(deposit % duration == 0, "deposit not multiple of time delta");

        /*
        *unique senders and recievers(each address can have only one sender stream and one reciever
        *stream) simplifies much of the other logic. If it is necessary for each address to have multiple
        *streams then a workaround would be to change the streamSenders and streamRecievers mappings
        *to map an array to each address, and iterate through these in the balanceOf and _beforeTokenTransfer
        *functions as necessary. the 0x0 address can recieve multiple streams.
        */


        _beforeTokenTransfer(msg.sender, recipient, deposit);

        require(streamSenders[msg.sender] == 0, "Only allowed to send one stream at a time");
        require(streamRecievers[recipient] == 0, "Can only recieve one stream at a time");



        uint ratePerSecond = deposit.div(duration);
        uint stopTime = block.timestamp.add(duration);

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: block.timestamp,
            stopTime: stopTime
            });

            streamSenders[msg.sender] = streamId;
            streamRecievers[recipient] = streamId;


            nextStreamId = nextStreamId.add(1);
            emit StreamCreated(streamId);
            return(streamId);
}

event StreamToDAOCreated(uint streamId);

function createStreamToDAO(uint deposit) public returns(uint){
  require(deposit > 0, "deposit is zero");

  uint _globalStreamTime = globalStreamTime;
  if(streamTimeModifier[msg.sender] != 0) {
    _globalStreamTime = (globalStreamTime.div(1000)).mul(streamTimeModifier[msg.sender]);
  }

  require(deposit >= _globalStreamTime, "deposit smaller than time delta");
  require(deposit % _globalStreamTime == 0, "deposit must be divisible by stream time");


  //not sure how the _beforeTokenTransfer function should be called. using address(0) as a placeholder.
  _beforeTokenTransfer(msg.sender, address(0), deposit);
  require(toDAOStreams[msg.sender] == 0, "sender has existing stream");


  uint stopTime = block.timestamp.add(_globalStreamTime);
  uint ratePerSecond = deposit.div(_globalStreamTime);

  /* Create and store the stream object. */
  uint256 streamId = nextStreamId;
  streams[streamId] = Stream({
      remainingBalance: deposit,
      deposit: deposit,
      isEntity: true,
      ratePerSecond: ratePerSecond,
      recipient: owner(),
      sender: msg.sender,
      startTime: block.timestamp,
      stopTime: stopTime
      });

      toDAOStreams[msg.sender] = streamId;

      nextStreamId = nextStreamId.add(1);
      emit StreamToDAOCreated(streamId);
      return(streamId);
}

event StreamTo0x0Created(uint streamId);

function createStreamTo0x0(uint deposit) public returns(uint){
  require(deposit > 0, "deposit is zero");

  uint _globalStreamTime = globalStreamTime;
  if(streamTimeModifier[msg.sender] != 0) {
    _globalStreamTime = (globalStreamTime.div(1000)).mul(streamTimeModifier[msg.sender]);
  }

  require(deposit >= _globalStreamTime, "deposit smaller than time delta");
  require(deposit % _globalStreamTime == 0, "deposit must be divisible by stream time");


  //not sure how the _beforeTokenTransfer function should be called. using address(0) as a placeholder.
  _beforeTokenTransfer(msg.sender, address(0), deposit);
  require(toDAOStreams[msg.sender] == 0, "sender has existing stream");



  uint stopTime = block.timestamp.add(_globalStreamTime);
  uint ratePerSecond = deposit.div(_globalStreamTime);

  /* Create and store the stream object. */
  uint256 streamId = nextStreamId;
  streams[streamId] = Stream({
      remainingBalance: deposit,
      deposit: deposit,
      isEntity: true,
      ratePerSecond: ratePerSecond,
      recipient: address(0),
      sender: msg.sender,
      startTime: block.timestamp,
      stopTime: stopTime
      });

      to0x0Streams[msg.sender] = streamId;

      nextStreamId = nextStreamId.add(1);
      emit StreamTo0x0Created(streamId);
      return(streamId);
}

event StreamFromDAOCreated(uint streamId);

function createStreamFromDAO(address recipient, uint amount, uint duration) public onlyOwner returns(uint){
  require(amount > 0, "deposit is zero");


  require(amount >= duration, "deposit smaller than duration");
  require(amount % duration == 0, "deposit must be divisible by duration");


  //not sure how the _beforeTokenTransfer function should be called. using address(0) as a placeholder.
  _beforeTokenTransfer(address(0), recipient, amount);
  require(fromDAOStreams[recipient] == 0, "recipient has existing stream from DAO");


  uint stopTime = block.timestamp.add(duration);
  uint ratePerSecond = amount.div(duration);

  /* Create and store the stream object. */
  uint256 streamId = nextStreamId;
  streams[streamId] = Stream({
      remainingBalance: amount,
      deposit: amount,
      isEntity: true,
      ratePerSecond: ratePerSecond,
      recipient: recipient,
      sender: address(0),
      startTime: block.timestamp,
      stopTime: stopTime
      });

      fromDAOStreams[recipient] = streamId;

      nextStreamId = nextStreamId.add(1);
      emit StreamFromDAOCreated(streamId);
      return(streamId);
}




function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
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
         *replaced above

        function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
             */

    }
