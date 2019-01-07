pragma solidity ^0.4.25;

contract B2E{
    uint unit = 1000000000000000000;
    uint rate; // * 10000
    bool settled;
    
    mapping(address => uint) public balanceof;
    mapping(address => uint) public timeout;
    address alice;
    address ingrid;
    bytes Fhash;
    uint min;
    uint delta_time;
    uint bob_funds;
    bytes bob_pubkey;
    bytes ingrid_pubkey;
    bytes ingrid_compressed_pubkey;
    bool input_check = false;
    bool output_check = false;
    uint pay2alice = 0;
    bytes raw_transaction;
    bytes32 s_r;
    bytes32 s_s;
    
    //Ingrid's pubkey = 0x67d4288c194a68a181c163f13177de9297b9afcae674cb99d21b047b6cc33e42b826948172b60396bc354669a623ee4dce9429f5a2503b07c6013923df775281
    //Ingrid's compressedpubkey = 0x0367d4288c194a68a181c163f13177de9297b9afcae674cb99d21b047b6cc33e42
    //Bob's pubkey = 0x2587ea3b5bac342cc64c56a74b12bea5d06eec929a768f1e3a1d5ee1eb2b44ae9b5e8a88ac0f88dfe8c769e679ec0bf5d1a9f01d44f0e54c870c3749cdaa6d7d
    //Fhash= 0x3dcd7d87904c9cb7f4b79f36b5a03f96e2e729284c09856238d5353e1182b002
    function B2Emod(address _ingrid_eth_pk, bytes _bob_btc_pk, bytes _hash, uint _min, uint _rate, uint _deltaR, uint _bfund) public 
    {

        alice = msg.sender;
        ingrid = _ingrid_eth_pk;
        bob_pubkey = _bob_btc_pk;
        Fhash = _hash;
        min = _min;
        rate = _rate;
        delta_time = _deltaR;
        bob_funds = _bfund * 100000000; //unit -> satoshi
        settled = false;
    }
    function payin(uint blocktime, bytes _ingrid_btc_pk, bytes _ingrid_btc_compressed_pubkey) public payable {
        require(msg.sender == ingrid);
        require(msg.value >= min*unit);
        balanceof[ingrid] = msg.value;
        timeout[ingrid] =  block.timestamp + blocktime;
        ingrid_pubkey = _ingrid_btc_pk;
        ingrid_compressed_pubkey = _ingrid_btc_compressed_pubkey;
        settled = false;
    }
    function refund() public{
        require(settled == false);
        require(msg.sender == ingrid);
        require(block.timestamp > timeout[ingrid]);
        ingrid.transfer(address(this).balance);
        settled = true;
    }
    function check_input(bytes _bodyS) public returns (bool){
        require(settled == false);
        require(msg.sender == alice);
        
        uint base = 0;
        
        bytes memory version = new bytes(4);
        for(uint i=0; i<4; i++)
        {
            version[3 - i] = _bodyS[i + base]; //little endian
        }
        base = base + 4;
        require(version[3] == 0x01);//check if it is version 1
        
       
        require(_bodyS[base] == 0x01);//input count, fixed, only 1 input (funding)
        base = base + 1;
        
        
        bytes memory input_hash = new bytes(32);
        for(i=0; i<32; i++)
        {
            input_hash[i] = _bodyS[i + base]; //big endian;
        }
        base = base + 32;
        require(keccak256(string(Fhash)) == keccak256(string(input_hash))); //check if the funding tx is correct
        
        //output index, should be 0x00000000
        for(i=0; i<4; i++)
        {
            require(_bodyS[base + i] == 0x00);
        }
        base = base + 4;
        
        //then come to script len and scriptSig part, cause the siganture is made on a not signed version, so here we need use redeem script as scriptSig
        //script len, fixed as 0x85  133bytes
        require(_bodyS[base] == 0x87);
        base = base + 1;
        
        //check redeem script, fixed as OP_2 Push PK_I Push PK_B OP_2 CHECKMULTISIG
        require(_bodyS[base] == 0x52);
        base = base + 1;
        
        require(_bodyS[base] == 0x41);
        base = base + 1;
        
        require(_bodyS[base] == 0x04); //uncompressed ingrid_pubkey
        base = base + 1;
        
        bytes memory r_pki = new bytes(64);
        for(i=0; i<64; i++)
        {
            r_pki[i] = _bodyS[base + i];
        }
        base = base + 64;
        require(keccak256(string(r_pki)) == keccak256(string(ingrid_pubkey)));
        
        require(_bodyS[base] == 0x41);
        base = base + 1;
        
        require(_bodyS[base] == 0x04);
        base = base + 1;
        
        bytes memory r_pkb = new bytes(64);
        for(i=0; i<64; i++)
        {
            r_pkb[i] = _bodyS[base + i];
        }
        base = base + 64;
        require(keccak256(string(r_pkb)) == keccak256(string(bob_pubkey)));
        
        require(_bodyS[base] == 0x52);
        base = base + 1;
        
        require(_bodyS[base] == 0xae);
        base = base + 1;
        

        bytes memory sequence = new bytes(4);
        for(i=0; i<4; i++)
        {
            sequence[i] = _bodyS[i + base];
        }
        base =  base + 4;
        //dont know what does seq means, no check here
        
        input_check = true;
        raw_transaction = _bodyS;
        return input_check;
    }
    
    function check_output(bytes _bodyS) public returns (bool){
        require(settled == false);
        require(msg.sender == alice);
        require(input_check == true);
        // require((timeout[ingrid] - delta_time) > block.timestamp);
        
        uint test = 0;
        uint base = 0;
        
        require(_bodyS[base] == 0x02); //output count
        base = base + 1;

        
        //here we need value for Ingrid
        bytes memory i_value = new bytes(8);
        for(uint i=0; i<8; i++)
        {
            i_value[7 - i] = _bodyS[base + i];
        }
        base = base + 8;
        // test = test + bytesToUint(i_value);
        //1 BTC = 00e1f50500000000

        // uint256 i_ethers = bytesToUint(i_value);
        
        require(_bodyS[base] == 0x19); //script length, fixed
        base = base + 1;
 
        require(_bodyS[base] == 0x76); //OP_DUP
        base = base + 1;
        
        require(_bodyS[base] == 0xa9); //OP_HASH160
        base = base + 1;
        
        require(_bodyS[base] == 0x14); //OP_Push 20 bytes to the stack
        base = base + 1;
        
        
        bytes20 hash_ingrid_pk = ripemd160(sha256(ingrid_compressed_pubkey)); //20 bytes pk hash of Ingrid
        // bytes memory hash_ingrid_pk = new bytes(20);
        // bytes memory compressed_ingrid_pk = new bytes(33);
        // compressed_ingrid_pk[0] = 0x03;
        // for(i=1; i<33; i++)
        // {
        //     compressed_ingrid_pk[i] = ingrid_pubkey[i-1];
        // }
        // bytes20 hash_ingrid_pk = ripemd160(sha256(compressed_ingrid_pk));
        for(i=0; i<20;i++)
        {
            // hash_ingrid_pk[k] = _bodyS[base + k];
            require(hash_ingrid_pk[i] == _bodyS[base + i]);
        }
        
        base = base + 20;
       
        
        require(_bodyS[base] == 0x88); //OP_EQUALITYVERIFY
        base = base + 1;
        
        require(_bodyS[base] == 0xac); //OP_CHECKSIGNATURE
        base = base + 1;
        


        //here we need value for Bob
        bytes memory b_value = new bytes(8);
        for(i=0; i<8; i++)
        {
            b_value[7 - i] = _bodyS[base + i];
        }
        base = base + 8;
        // test = test + bytesToUint(b_value);
        
        
        require(_bodyS[base] == 0x19); //fixed length 25 bytes
        base = base + 1;
        
        require(_bodyS[base] == 0x76); //OP_DUP
        base = base + 1;
              
        require(_bodyS[base] == 0xa9); //OP_HASH160
        base = base + 1;
        
        require(_bodyS[base] == 0x14); //push 20 bytes into stack
        base = base + 1;
        
        //here we don't care who can spend this
        base = base + 20;
        
        require(_bodyS[base] == 0x88); //OP_EQUALITYVERIFY
        base = base + 1;
        
        require(_bodyS[base] == 0xac); //OP_CHECKSIGNATURE
        base = base + 1;
        

        for(i=0; i<4; i++)//locktime
        {
            require(_bodyS[base + i] == 0x00);
        }
        base = base + 4;
        
        require(_bodyS[base] == 0x01);
        base = base + 1;
        
        require(_bodyS[base] == 0x00);
        base = base + 1;
        
        require(_bodyS[base] == 0x00);
        base = base + 1;
        
        require(_bodyS[base] == 0x00);
        base = base + 1;
     
        require(bob_funds >= (bytesToUint(i_value) + bytesToUint(b_value)));
        pay2alice = bytesToUint(i_value)*1000000*rate;
        
        output_check =true;

        raw_transaction = MergeBytes(raw_transaction, _bodyS);
        return output_check;
    }
    
    function payout_by_signature(bytes _tx, bytes32 _r, bytes32 _s) returns (bool)
    {
        require(input_check == true);
        require(output_check == true);
        require(msg.sender == alice);
        require(settled == false);
        require((timeout[ingrid] - delta_time) >= block.timestamp);
        // bytes memory suffix = new bytes(4);
        // suffix[0] = 0x01;
        // suffix[1] = 0x00;
        // suffix[2] = 0x00;
        // suffix[3] = 0x00;
        // raw_transaction = MergeBytes(raw_transaction, suffix);
        require(sha256(_tx) == sha256(raw_transaction));
        
        bool result = false;
        address recoverd_add1 = pubkey_recover(_tx, 27, _r, _s);
        address recoverd_add2 = pubkey_recover(_tx, 28, _r, _s);
        address target_add = calculate_address(bob_pubkey);
        if(recoverd_add1 == target_add)
        {
            result = true;
        }
        else if(recoverd_add2 == target_add)
        {
            result = true;
        }
        require(result == true);
        s_r = _r;
        s_s = _s;
        alice.transfer(pay2alice);
        ingrid.transfer(balanceof[ingrid] - pay2alice);
        balanceof[ingrid] = 0;
        settled = true;
        return result;
        
    }
    function kill() public
    {
        require(msg.sender == ingrid);
        require(settled == true);
        selfdestruct(ingrid);
    }
    function pubkey_recover(bytes _msg, uint8 _v, bytes32 _r, bytes32 _s) private returns (address)
    {
        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _msghash = sha256(_msg);
        // _msghash = keccak256(_msghash);
        _msghash = sha256(_msghash);
        return ecrecover(_msghash,_v,_r,_s);
    }
    function bytesToUint(bytes b) private returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    // function calculate_msg_hash(bytes msg) private returns (bytes32)
    // {
    //     bytes32 msghash = sha256(msg);
    //     return msghash;
    // }
     function calculate_address(bytes msg) private returns (address)
    {
        bytes32 msghash = keccak256(msg);
        return address(msghash);
    }
    // function calculate_PK_hash(bytes pubkey) private returns (bytes20)
    // {
    //     bytes20 pk_hash = ripemd160(sha256(pubkey));
    //     return pk_hash;
    // }
    function show_rate() public view returns (uint)
    {
        return rate;
    }
    
    function show_deltaR() public view returns (uint)
    {
        return delta_time;
    }
    function show_raw_transaction() public view returns (bytes)
    {
        return raw_transaction;
    }
    function show_bob_signature() public view returns (bytes32, bytes32)
    {
        return (s_r, s_s);
    }
    

    function MergeBytes(bytes memory a, bytes memory b) public pure returns (bytes memory c) 
    {
        // Store the length of the first array
        uint alen = a.length;
        // Store the length of BOTH arrays
        uint totallen = alen + b.length;
        // Count the loops required for array a (sets of 32 bytes)
        uint loopsa = (a.length + 31) / 32;
        // Count the loops required for array b (sets of 32 bytes)
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            // Load the length of both arrays to the head of the new bytes array
            mstore(m, totallen)
            // Add the contents of a to the array
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            // Add the contents of b to the array
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
    
    function testhashpk(bytes pk) public returns (bytes20)
    {
         bytes20 hash_pk = ripemd160(sha256(pk));
         return hash_pk;
    }


}