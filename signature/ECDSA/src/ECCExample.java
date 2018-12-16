import org.bouncycastle.util.encoders.Hex;
import org.web3j.crypto.*;
import java.math.BigInteger;
import java.security.MessageDigest;

public class ECCExample {

    public static String compressPubKey(BigInteger pubKey) {
        String pubKeyYPrefix = pubKey.testBit(0) ? "03" : "02";
        String pubKeyHex = pubKey.toString(16);
        String pubKeyX = pubKeyHex.substring(0, 64);
        return pubKeyYPrefix + pubKeyX;
    }

    public static void main(String[] args) throws Exception {

        BigInteger privKey = new BigInteger("f2358c3a3a7055bfe3ee2ce035d3d6c84c962dceccb4e2e076b710ddbaf8ffe3", 16); //Bob
//        BigInteger privKey = new BigInteger("98fe5afc25bd420994f01f92c7180aac566c041732ab0ade13712994b24e4e79", 16); //Ingrid
        BigInteger pubKey = Sign.publicKeyFromPrivate(privKey);
        ECKeyPair keyPair = new ECKeyPair(privKey, pubKey);
        System.out.println("Private key: " + privKey.toString(16));
        System.out.println("Public key: " + pubKey.toString(16));
        System.out.println("Public key (compressed): " + compressPubKey(pubKey));
//        String msg = "01000000013dcd7d87904c9cb7f4b79f36b5a03f96e2e729284c09856238d5353e1182b002" +
//                "0000000085524067d4288c194a68a181c163f13177de9297b9afcae674cb99d21b047b6cc33e42b8269481" +
//                "72b60396bc354669a623ee4dce9429f5a2503b07c6013923df775281402587ea3b5bac342cc64c56a74b12b" +
//                "ea5d06eec929a768f1e3a1d5ee1eb2b44ae9b5e8a88ac0f88dfe8c769e679ec0bf5d1a9f01d44f0e54c870" +
//                "c3749cdaa6d7d52aeffffffff" + "0200e1f505000000001976a9144e2060ca5a550b8c8e45f78522f167c6" +
//                "1111c9a288ac00e9a435000000001976a9144e2060ca5a550b8c8e45f78522f167c61111c9a288ac00000000";

        String msg = "01000000" + //version
                "01" + //input count
                "3dcd7d87904c9cb7f4b79f36b5a03f96e2e729284c09856238d5353e1182b002" + //funding tx id
                "00000000" + //output index
                "85" + // PUSH_DATA_85  --> indicates the following data length
                "524067d4288c194a68a181c163f13177de9297b9afcae674cb99d21b047b6cc33e42b826948172b60396bc354669a623ee4dce9429f5a2503b07c6013923df775281" + //OP_2 PUSH_DATA_40 pubkey_ingrid
                "402587ea3b5bac342cc64c56a74b12bea5d06eec929a768f1e3a1d5ee1eb2b44ae9b5e8a88ac0f88dfe8c769e679ec0bf5d1a9f01d44f0e54c870c3749cdaa6d7d" + //PUSH_DATA_40 pubkey_bob
                "52ae" + // OP_2 CHECKMULTISIG
                "ffffffff" + // sequence
                "02" + // output count
                "00e1f50500000000" + // value --> 1BTC
                "19" + //output length
                "76a914" + //OP_DUP OP_HASH160 PUSHDATA_14
                "4e2060ca5a550b8c8e45f78522f167c61111c9a2" + //20 bytes pki hash
                "88ac" + // OP_EQUALITYVERIFY OP_CHECKSIG
                "00e9a43500000000" + // value --> 9 BTC
                "19" + // output length
                "76a914" + // OP_DUP OP_HASH160 PUSHDATA_14
                "4e2060ca5a550b8c8e45f78522f167c61111c9a2" + // 20 bytes pk hash, doesn't harm ingrid's interest
                "88ac" + // OP_EQUALITYVERIFY OP_CHECKSIG
                "00000000" + // blocktime --> 0
                "01000000"; // suffix pending, indicates SIGHASH_ALL. REMEBER to add 01 at the end of signature!!!

//        String msg = "0100000001c21ae5cfc3a73eba85ad9c7d06304840b1e3f0d147feea41f62ab3392dae2e08000000001976a91488b028348642ad1bbaa8fcc054273070eda045fe88acffffffff01c8320000000000001976a914f4f1d83d4ce7b5a3d2dfb2384af09f6d95c8279388ac0000000001000000";
//        String msg = "01000000" + //version
//                "01" + //input count
//                "c68db8fc6652dc9d7c7a58e48c118c42086f670dd8f87987625cc910ef9cfd4b" + //funding transaction id
//                "01000000" + // index = 1, second output
//                "c9"+ //PUSH_DATA_c9  --> length is c9
//                "5241041ce544058996033a34adb07be380e63956c588dd036d20824447d88700ec91f45a98894bbbdab68ac304b5e68f77ea2f614516d0ace35f76e3b376b9917d6c84"+ //OP_2 PUSH_DATA_41 PK_1
//                "4104db5efff14362653c0fc2e5437ac964dd3e093110c8fbcd5d9fd135ec3c98dc926d26b344def4397c3d99ebbd56e35c53cdd501e2c7a9a0cc5c2b04e7d0a38751" + //PUSH_DATA_41 PK_2
//                "41043b9264a9afb2c9dbc3602cf25ab9a5f5ee1f991e6edfb9c2982a9d31cd7e41c2c9c2a8ad2a8da0c8943b54192c9fea120bf5cce390b459269698efaadb42d649" + //PUSH_DATA_41 PK_3
//                "53ae" + //OP_3 CHECKMULTISIG
//                "ffffffff" + //Sequence
//                "01" + //output count 1
//                "605b030000000000" + //value
//                "19" + // output length
//                "76a914" + //OP_DUP OP_HASH160 PUSHDATA_14
//                "9bfdf3e906ce07448dac85ce385ab6bdad7e7b81" + //20 bytes pk hash
//                "88ac" + //OP_EQUALITYVERIFY OP_CHECKSIG
//                "00000000" + //blocktime --> 0
//                "01000000"; //suffix SIGHASH_ALL
        byte[] strb = hexStringToByteArray(msg);
        byte[] msgHash = Hash.sha256(strb);
        msgHash = Hash.sha256(msgHash);
        Sign.SignatureData signature = Sign.signMessage(msgHash, keyPair);

        System.out.println("Msg hash: " + Hex.toHexString(msgHash));
        System.out.printf("Signature: [v = %d, r = %s, s = %s]\n",
                signature.getV() - 27,
                Hex.toHexString(signature.getR()),
                Hex.toHexString(signature.getS()));

        System.out.println();

        BigInteger pubKeyRecovered = Sign.signedMessageToKey(msgHash, signature);
        System.out.println("Recovered public key: " + pubKeyRecovered.toString(16));

        boolean validSig = pubKey.equals(pubKeyRecovered);
        System.out.println("Signature valid? " + validSig);




    }
    public static byte[] hexStringToByteArray(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                    + Character.digit(s.charAt(i+1), 16));
        }
        return data;
    }
    public static String byteArrayToHex(byte[] a) {
        StringBuilder sb = new StringBuilder(a.length * 2);
        for(byte b: a)
            sb.append(String.format("%02x", b));
        return sb.toString();
    }
}
