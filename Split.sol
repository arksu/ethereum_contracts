pragma solidity ^0.4.18;

//from Zeppelin
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract PayToken {
    using SafeMath for uint256;

    address[] receivers = new address[](11);

    function PayToken() {
        receivers[0] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C42;
        receivers[1] = 0x6466DB56597c791aFcFA31BbdAAE913fd1f49c43;
        receivers[2] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C44;
        receivers[3] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C45;
        receivers[4] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C46;
        receivers[5] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C47;
        receivers[6] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C48;
        receivers[7] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C49;
        receivers[8] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C4a;
        receivers[9] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C4b;
        receivers[10] = 0x6466Db56597c791AfCfA31BbDAaE913FD1f49C4c;
    }

    function() public payable {
        uint256 half = msg.value.div(2);
        receivers[0].transfer(half);

        uint256 ostatok = msg.value.sub(half);
        uint256 part = ostatok.div(10);
        uint256 ostatok2 = ostatok - part.mul(9);

        for (uint8 i = 1; i < 10; i++) {
            receivers[i].transfer(part);
        }

        receivers[10].transfer(ostatok2);
    }

}


