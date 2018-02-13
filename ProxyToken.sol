pragma solidity ^0.4.18;

//from Zeppelin
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a);
        return c;
    }
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address newOwner;

    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract Finalizable is Owned {
    bool public finalized;

    function finalize() public onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        require(!finalized);
        _;
    }
}

contract IToken {
    function transfer(address _to, uint _value) public returns (bool);
    function balanceOf(address owner) public returns(uint);
}

contract TokenReceivable is Owned {
    event logTokenTransfer(address token, address to, uint amount);

    function claimTokens(address _token, address _to) public onlyOwner returns (bool) {
        IToken token = IToken(_token);
        uint balance = token.balanceOf(this);
        if (token.transfer(_to, balance)) {
            logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }
}

contract EventDefinitions {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is Finalizable, TokenReceivable, SafeMath, EventDefinitions {


    string public name = "Token";
    uint8 public decimals = 8;
    string public symbol = "TEST";

    Controller public controller;

    modifier onlyController() {
        assert(msg.sender == address(controller));
        _;
    }

    function setController(address _c) public onlyOwner notFinalized {
        controller = Controller(_c);
    }

    function balanceOf(address a) public constant returns (uint) {
        return controller.balanceOf(a);
    }

    function totalSupply() public constant returns (uint) {
        return controller.totalSupply();
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return controller.allowance(_owner, _spender);
    }

    function transfer(address _to, uint _value) public
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.transfer(msg.sender, _to, _value);
        if (success) {
            Transfer(msg.sender, _to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public
    onlyPayloadSize(3)
    returns (bool success) {
        success = controller.transferFrom(msg.sender, _from, _to, _value);
        if (success) {
            Transfer(_from, _to, _value);
        }
    }

    function approve(address _spender, uint _value) public
    onlyPayloadSize(2)
    returns (bool success) {
        //promote safe user behavior
        require(controller.allowance(msg.sender, _spender) == 0);

        success = controller.approve(msg.sender, _spender, _value);
        if (success) {
            Approval(msg.sender, _spender, _value);
        }
    }

    function increaseApproval (address _spender, uint _addedValue) public
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.increaseApproval(msg.sender, _spender, _addedValue);
        if (success) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
        }
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.decreaseApproval(msg.sender, _spender, _subtractedValue);
        if (success) {
            uint newval = controller.allowance(msg.sender, _spender);
            Approval(msg.sender, _spender, newval);
        }
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }

    function burn(uint _amount) public {
        controller.burn(msg.sender, _amount);
        Transfer(msg.sender, 0x0, _amount);
    }

    function controllerTransfer(address _from, address _to, uint _value) public
    onlyController {
        Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint _value) public
    onlyController {
        Approval(_owner, _spender, _value);
    }

    //multi-approve, multi-transfer

    bool public multilocked;

    modifier notMultilocked {
        assert(!multilocked);
        _;
    }

    //do we want lock permanent? I think so.
    function lockMultis() public onlyOwner {
        multilocked = true;
    }

    //multi functions just issue events, to fix initial event history

    function multiTransfer(uint[] bits) public onlyOwner notMultilocked {
        require (bits.length % 3 == 0);
        for (uint i=0; i<bits.length; i += 3) {
            address from = address(bits[i]);
            address to = address(bits[i+1]);
            uint amount = bits[i+2];
            Transfer(from, to, amount);
        }
    }

    function multiApprove(uint[] bits) public onlyOwner notMultilocked {
        require (bits.length % 3 == 0);
        for (uint i=0; i<bits.length; i += 3) {
            address owner = address(bits[i]);
            address spender = address(bits[i+1]);
            uint amount = bits[i+2];
            Approval(owner, spender, amount);
        }
    }

    string public motd;
    event Motd(string message);
    function setMotd(string _m) public onlyOwner {
        motd = _m;
        Motd(_m);
    }
}

contract Controller is Owned, Finalizable {
    Ledger public ledger;
    Token public token;
    address public oldToken;
    address public EtherDelta;

    function setEtherDelta(address _addr) public onlyOwner {
        EtherDelta = _addr;
    }

    function setOldToken(address _token) public onlyOwner {
        oldToken = _token;
    }

    function setToken(address _token) public onlyOwner {
        token = Token(_token);
    }

    function setLedger(address _ledger) public onlyOwner {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        require(msg.sender == address(token) || msg.sender == oldToken);
        _;
    }

    modifier onlyNewToken() {
        require(msg.sender == address(token));
        _;
    }

    function totalSupply() public constant returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) public onlyToken constant returns (uint) {
        return Ledger(ledger).balanceOf(_a);
    }

    function allowance(address _owner, address _spender) public
    onlyToken constant returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(address _from, address _to, uint _value) public
    onlyToken
    returns (bool success) {
        assert(msg.sender != oldToken || _from == EtherDelta);
        bool ok = ledger.transfer(_from, _to, _value);
        if (ok && msg.sender == oldToken)
            token.controllerTransfer(_from, _to, _value);
        return ok;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) public
    onlyToken
    returns (bool success) {
        assert(msg.sender != oldToken || _from == EtherDelta);
        bool ok = ledger.transferFrom(_spender, _from, _to, _value);
        if (ok && msg.sender == oldToken)
            token.controllerTransfer(_from, _to, _value);
        return ok;
    }

    function approve(address _owner, address _spender, uint _value) public
    onlyNewToken
    returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) public
    onlyNewToken
    returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) public
    onlyNewToken
    returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    function burn(address _owner, uint _amount) public onlyNewToken {
        ledger.burn(_owner, _amount);
    }
}

contract Ledger is Owned, SafeMath, Finalizable {
    uint256 constant a = 1;

    address public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;

    function setController(address _controller) public onlyOwner notFinalized {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function transfer(address _from, address _to, uint _value) public
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) public
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value) public
    onlyController
    returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) public
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) public
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    event LogMint(address indexed owner, uint amount);
    event LogMintingStopped();

    function mint(address _a, uint _amount) public onlyOwner mintingActive {
        balanceOf[_a] += _amount;
        totalSupply += _amount;
        LogMint(_a, _amount);
    }

    bool public mintingStopped;

    function stopMinting() public onlyOwner {
        mintingStopped = true;
        LogMintingStopped();
    }

    modifier mintingActive() {
        require(!mintingStopped);
        _;
    }

    function burn(address _owner, uint _amount) public onlyController {
        balanceOf[_owner] = safeSub(balanceOf[_owner], _amount);
        totalSupply = safeSub(totalSupply, _amount);
    }
}
