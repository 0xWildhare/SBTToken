// contracts/SBTToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
  *this implementation of the ERC20 standard requires modification to stopTime
  *of the basic functions in the standard, namely the 'balanceOf', transfer, and ???
  *functions. Since some of these functions are not virtual in the standard ERC20
  *contract from OpenZeppelin, that contract would have had to be modified to be used
  *as a parent to this one. for simplicity, the entire ERC20 contract from OppenZepplin
  *was copied into this file, and the necessary functions modified accordingly.
  */


contract SBTToken is Context, IERC20 {
  /*
  *This section is unaltered from ERC20.
  */
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name = 'Slow Burn Token';
  string private _symbol = 'SBT';
  uint8 private _decimals = 18;


  /**
    *this section streamID, Struct, mapping and modifiers comes from the Sablier
    *contract, and has been modified to remove
    *the fields not used for this application (tokenAddress).
    */

    /**
   * @notice Counter for new stream ids.
   */
  uint256 public nextStreamId;

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

    /*** Modifiers from Sablier ***/

    /**
      * @dev Throws if the caller is not the sender of the recipient of the stream.
      */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /**
    * @dev Throws if the provided id does not point to a valid stream.
    */
    modifier streamExists(uint256 streamId) {
      require(streams[streamId].isEntity, "stream does not exist");
      _;
    }


    /*these mappings help to eliminate a large portion of the sablier logic that wasn't
      *directly applicable to this project, and to allow the balanceOf and transfer (and other)
      * functions to interface according to ERC20 standard
      */

      mapping(address => uint256) private streamSenders;
      mapping(address => uint256) private streamRecievers;


/*
  ***CONTRACT LOGIC STARTS HERE***
  */

    constructor(uint256 initialSupply) public {
        _mint(msg.sender, initialSupply); //Mints initial supply to deployer
        nextStreamId = 1; //from Sablier
    }

/*
  *the following functions (balanceOf, transfer, etc) are modified from ERC20
  */

    function balanceOf(address account) public view override returns (uint256) {
        uint calculatedBalance = _balances[account];
         //no streamsfor account, returns un-modified balance
        if(streamSenders[account] == 0 && streamRecievers[account] == 0) return calculatedBalance;
        //if there is a send stream for account, modify accordingly (only handles 1 send stream per account)
        if(streamSenders[account] != 0) {
          uint sendId = streamSenders[account];
          Stream memory streamS = streams[sendId];
          uint deltaS = deltaOf(sendId);
          uint sentBalance = deltaS.mul(streamS.ratePerSecond); //this is total amount sent, not necessarily transacted yet

          /*
          * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
          * We have to subtract the total amount withdrawn from the amount of money that has been
          * streamed until now.
          */

            if (streamS.deposit > streamS.remainingBalance) {
              uint totalSent = streamS.deposit.sub(streamS.remainingBalance);
              sentBalance = sentBalance.sub(totalSent);
            }
            calculatedBalance = calculatedBalance.sub(sentBalance);
        }
        //if there is a recieve stream for account, modify accordingly
        if(streamRecievers[account] != 0) {
          uint recieveId = streamRecievers[account];
          Stream memory streamR = streams[recieveId];
          uint deltaR = deltaOf(recieveId);
          uint recievedBalance = deltaR.mul(streamR.ratePerSecond);

          /*
          * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
          * We have to subtract the total amount withdrawn from the amount of money that has been
          * streamed until now.
          */

            if (streamR.deposit > streamR.remainingBalance) {
              uint totalRecieved = streamR.deposit.sub(streamR.remainingBalance);
              recievedBalance = recievedBalance.sub(totalRecieved);
            }
            calculatedBalance = calculatedBalance.add(recievedBalance);
        }
        return calculatedBalance;

      }










/*
****this section is adapted and simplified from Sablier***
*differences  - takes duration of stream instead of startTime and stopTime
              - does not take token address
              - allows tokens to be streamed to 0x0
              - allows tokens to be streamed to this contracts
              - automatically starts stream at current block timestamp

  *TODO: senders and rvievers should be unique (one address cannot send
  multiple Streams; one address cannot recieve multiple streams [with the exception of 0x0])


*/
event StreamCreated(uint streamId);

function createStream(address recipient, uint256 deposit, uint256 duration)
    public
    returns (uint256)
{

        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");

        require(deposit >= duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(deposit % duration == 0, "deposit not multiple of time delta");

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
            if(recipient != address(0x00)) {
              streamRecievers[recipient] = streamId;
            }

            nextStreamId = nextStreamId.add(1);
            emit StreamCreated(streamId);
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
    *The following functions come from Sablier.sol
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
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}
