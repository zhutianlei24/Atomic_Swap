pragma solidity ^0.4.21;
//root:0x2be44bd0510c9b004f8f54e675a4f889700de294
contract E2B{
    uint rate; // * 10000
    bool settled;
 
    mapping(address => uint) public balanceof;
    mapping(address => uint) public timeout;
    address alice;
    address ingrid;
    bytes20 root ;
    string leaf;

    function getBalance() public returns(uint){
        return address(this).balance;
    }
    function E2B(address address_i, uint _rate, bytes20 _root){
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
    function Payout(uint v, string a, bytes20[] nodes, bool[] invert){

        require(msg.sender == ingrid);
        assert(balanceof[alice] > v);
        
        bytes20 hasha = hash160forstring(a);
        bytes20 hashn = hash160forint(v);
        bytes20 tmp = ripemd160(sha256(hasha,hashn));
        for(uint i = 0; i<nodes.length; i++){
            if(invert[i] == true)
                tmp = ripemd160(sha256(nodes[i],tmp));
            else
                tmp = ripemd160(sha256(tmp,nodes[i]));
        }
        assert(root == tmp);
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
    function hash160forint(uint text) private returns (bytes20)
    {
        return ripemd160(sha256(text));
    }




}
