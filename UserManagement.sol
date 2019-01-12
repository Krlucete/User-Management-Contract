pragma solidity ^0.4.25;

contract Owned {
    address public owner;
    
    event TransferOwnerShip(address oldaddr, address newaddr);
    
    modifier onlyOwner() { if (msg.sender != owner) revert(); _; }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeOwner(address _new) onlyOwner public {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnerShip(oldaddr, owner);
    }
}

contract Members is Owned {
    address public coinAddr;
    MemberStatus[] public status;
    mapping(address => History) public tradingHistory;
    
    struct MemberStatus {
        string name;
        uint256 times;
        uint256 sum;
        int8 rate;
    }
    
    struct History { // user's transaction history 
        uint256 times;
        uint256 sum;
        uint256 statusIndex;
        string class;
    }
    
    modifier onlyCoin() { if(msg.sender == coinAddr) _; }
    
    function setCoin(address _addr) onlyOwner public {
        coinAddr = _addr;
    }
    
    function pushStatus(string _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public {
        status.push(MemberStatus({
            name: _name,
            times: _times,
            sum: _sum,
            rate: _rate
        }));
    }
    
    function editStatus(uint256 _index, string _name, uint256 _sum, uint256 _times, int8 _rate) onlyOwner public returns (bool) {
        if(_index < status.length) {
            status[_index].name = _name;
            status[_index].sum = _sum;
            status[_index].times = _times;
            status[_index].rate = _rate;
        }
        return true;
    }
    
    function updateHistory(address _member, uint256 _value) onlyCoin public {
        tradingHistory[_member].times += 1;
        tradingHistory[_member].sum += _value;
        
        uint256 index;
        int8 tmpRate;
        
        for(uint i=0; i<status.length; i++) {
            if(tradingHistory[_member].times >= status[i].times && tradingHistory[_member].sum >= status[i].sum && tmpRate < status[i].rate) {
                index = i;
            }
        }
        tradingHistory[_member].statusIndex = index;
        tradingHistory[_member].class = status[index].name;
    }
    
    function getCashBackRate(address _member) view public returns (int8 rate) {
        rate = status[tradingHistory[_member].statusIndex].rate;
    }
}

contract OreOreCoin is Owned {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => int8) public blackList;
    Members members;
    // mapping (address => Members) public members;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event CashBack(address indexed from, address indexed to, uint256 value);
    
    constructor(uint256 _supply, string _name, string _symbol, uint8 _decimals, address _membersContractAddr) public {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
        members = Members(_membersContractAddr);
    }
    
    function blackListing(address _addr) onlyOwner public {
        blackList[_addr] = 1;
        emit Blacklisted(_addr);
    }
    
    function deleteFromBlackList(address _addr) onlyOwner public {
        blackList[_addr] = 0;
        emit DeleteFromBlacklist(_addr);
    }
    
    function transfer(address _to, uint256 _value) public {
        if(balanceOf[msg.sender] < _value) revert();
        if(balanceOf[_to] + _value < balanceOf[_to]) revert();
        
        if(blackList[msg.sender] > 0) 
            emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
        else if(blackList[_to] > 0)
            emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
        else {
            uint256 cashback = 0;
            cashback = _value / 100 * uint256(members.getCashBackRate(msg.sender));
            members.updateHistory(msg.sender, _value);

            balanceOf[msg.sender] -= _value - cashback;
            balanceOf[_to] += _value - cashback;
            
            emit Transfer(msg.sender, _to, _value);
            emit CashBack(_to, msg.sender, cashback);
        }
    }
    
}