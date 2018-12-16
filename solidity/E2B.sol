pragma solidity ^0.4.21;


contract E2B{
    uint rate; // * 10000
    bool settled;
 
    mapping(address => uint) public balanceof;
    mapping(address => uint) public timeout;
    address alice;
    address ingrid;
    bytes32 root ;
    string leaf;

    function getBalance() public returns(uint){
        return address(this).balance;
    }
    function E2B(address address_i, uint _rate, bytes32 _root){
        alice = msg.sender;
        ingrid = address_i;
        // balanceof[msg.sender] = msg.value;
        balanceof[alice] = 0;
        balanceof[ingrid] = 0;
        rate = _rate;
        // timeout[alice] = block.timestamp + blocktime;
        root = _root;
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
    function showRoot() returns (bytes32){
        return root;
    }
    function refund(){
        require(msg.sender == alice);
        require(block.timestamp > timeout[alice]);
        require(settled == false);
        alice.transfer(address(this).balance);
        settled = true;
    }
    function Payout(uint v, string a, bytes32[] nodes, bool[] invert){

        require(msg.sender == ingrid);
        assert(balanceof[alice] > v);
        
        leaf = appendUintToString(a,v);
        bytes32 tmp = keccak256(leaf);
        for(uint i = 0; i<nodes.length; i++){
            if(invert[i] == true)
                tmp = keccak256(nodes[i],tmp);
            else
                tmp = keccak256(tmp,nodes[i]);
        }
        assert(root == tmp);
        //root = 0xA0C261D1767AE5B0E04587B465B75A83D916EF9AC09F211B83DCE7DC9A53293D
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
    
    
    //helper methods
    function keccakCalculator(bytes32 a, bytes32 b) view returns (bytes32)
    {

        bytes32 res = keccak256(a,b);
        uint tmp = 1;
        return res;
        
    }
    function appendUintToString(string inStr, uint v) private constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }
}