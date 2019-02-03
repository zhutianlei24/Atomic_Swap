pragma solidity ^0.4.21;

contract E2BMA{
    uint rate; // * 10000
    bool settled;
 
    mapping(address => uint) public balanceof;
    mapping(address => uint) public timeout;
    mapping(bytes20 => uint) public MA;
    address alice;
    address ingrid;

    function getBalance() public returns(uint){
        return address(this).balance;
    }
    function E2BMA(address address_i, uint _rate, bytes20[] key, uint[] value){
        alice = msg.sender;
        ingrid = address_i;

        balanceof[alice] = 0;
        balanceof[ingrid] = 0;
        rate = _rate;

        assert(key.length == value.length);
        for(uint i=0; i < key.length; i++)
        {
            MA[key[i]] = value[i];
        }
        settled = false;
    }
    function Payin(uint blocktime) payable{
        require(msg.sender == alice);
        balanceof[alice] = balanceof[alice] + msg.value;
        timeout[alice] = block.timestamp + blocktime;
        settled = false;
    }
    function show_rate() public view returns (uint)
    {
        return rate;
    }
    function refund(){
        require(msg.sender == alice);
        require(block.timestamp > timeout[alice]);
        require(settled == false);
        alice.transfer(address(this).balance);
        settled = true;
    }
    function Payout(string a){

        require(msg.sender == ingrid);
        assert(balanceof[alice] > v);
        bytes20 key = hash160forstring(a);
        uint v = MA[key];
        assert(v != 0);
        uint transfered_coins = rate*v*100000000000000;
        ingrid.transfer(transfered_coins);
        alice.transfer(balanceof[alice] - transfered_coins);
        balanceof[alice] = 0;
        settled = true;
        kill();
    }
    function kill() private
    {
        if(msg.sender == ingrid)
        {
            selfdestruct(ingrid);
        }
    }
    
    function hash160forstring(string text) private returns (bytes20)
    {
        return ripemd160(sha256(text));
    }

}