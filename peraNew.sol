pragma solidity 0.6.12;
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}
contract BEP20 {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

    contract TEST {
    string public name;
    address public manager;
    string public symbol;
    uint256 public decimals = 9;
    uint256 private LPTokenDecimals = 18;
    uint256 public genesisBlock = block.number;
    uint256 public PERASupply = 83000000 * 10 ** uint256(decimals);
    uint256 private constant transferRateInitial = ~uint240(0);
    uint256 public transferRate = (transferRateInitial - (transferRateInitial % PERASupply))/PERASupply;
    uint public datumIndexLP = 0;
    uint public totalStakedLP = 0;
    uint private dailyRewardForTC = 5600 * 10 ** uint256(decimals);
    uint8 private totalTCwinners = 10;
    uint private decimalLossLP = 10 ** 18;
    uint256 public totalSupply;
    mapping (address => uint256) private userbalanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    address[] public _excluded;
    mapping (uint256 => uint256) public totalRewardforTC;

    uint private BlockSizeForTC = 28800;
    uint private oneWeekasBlock = BlockSizeForTC * 7;
    uint private tenYearsasBlock = oneWeekasBlock * 520;
    uint private blockRewardLP = 5 * 10 ** uint256(decimals);

    uint private tradingCompFee = 50;
    uint private holderFee = 75;
    uint private liqproviderFee = 75;

    address lpTokenAddress;

    using SafeMath for uint;

   struct UserLP {
        uint liq;
        uint dp;
    }

    mapping (address => UserLP) usersLP;

    struct DatumpointlistLP {
       uint liqsum;
       uint prosum;
       uint block;
   }

   mapping (uint => DatumpointlistLP) dlistLP;

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol

    ) public {
        initialSupply = PERASupply.mul(transferRate);
        tokenName = "TEST";
        tokenSymbol = "TEST";
        manager = msg.sender;
        userbalanceOf[msg.sender] = initialSupply.mul(10).div(83);
        userbalanceOf[address(this)] = initialSupply.mul(73).div(83);
        totalSupply =  PERASupply;
        name = tokenName;
        symbol = tokenSymbol;
    }


    function balanceOf(address _addr) public view returns (uint256) {
      if (_isExcluded(_addr)){
          return userbalanceOf[_addr];
      } else{
          return balanceRebalance(userbalanceOf[_addr]);
      }
    }

    function balanceRebalance(uint256 userBalances) private view returns(uint256) {
      return userBalances.div(transferRate);
    }

    function transferOwnership(address newOwner) public{
        require(msg.sender == manager);   // Check if the sender is manager
        if (newOwner != address(0)) {
            manager = newOwner;
        }
    }

    function excludeAccount(address account) public {
        require(msg.sender == manager);
        require(!_isExcluded(account));
        _excluded.push(account);
        userbalanceOf[account] = userbalanceOf[account].div(transferRate);
    }

    function includeAccount(address account) public {
    require(msg.sender == manager);
    require(_isExcluded(account));
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                userbalanceOf[account] = userbalanceOf[account].mul(transferRate);
                break;
            }
        }
    }


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));

        if(!_isExcluded(_from)){
            require(userbalanceOf[_from].div(transferRate) >= _value);
            require(userbalanceOf[_to].div(transferRate) + _value >= userbalanceOf[_to].div(transferRate));
        }else{
            require(userbalanceOf[_from] >= _value);
            require(userbalanceOf[_to] + _value >= userbalanceOf[_to]);
        }

        uint256 tenthousandthofamonut = _value.div(10000);

        if (isManager(_from)){
            tenthousandthofamonut = 0;
        }

        uint256 _bnum = (block.number - genesisBlock)/BlockSizeForTC;

        totalRewardforTC[_bnum]  +=  uint(tenthousandthofamonut.mul(tradingCompFee));
        dlistLP[datumIndexLP].prosum  +=  uint(tenthousandthofamonut.mul(liqproviderFee));

        uint totalOut = uint(tenthousandthofamonut.mul(tradingCompFee)) + uint(tenthousandthofamonut.mul(holderFee)) + uint(tenthousandthofamonut.mul(liqproviderFee));

        if ((_isExcluded(_to)) && (_isExcluded(_from))){
            userbalanceOf[_from] -= _value;
            userbalanceOf[_to] +=   (_value).sub(totalOut);
        } else if(_isExcluded(_to)){
            userbalanceOf[_from] -= _value.mul(transferRate);
            userbalanceOf[_to] +=   (_value).sub(totalOut);
        } else if (_isExcluded(_from)){
            userbalanceOf[_from] -= _value;
            uint transferAmount = (_value).sub(totalOut);
            userbalanceOf[_to] +=  transferAmount.mul(transferRate);
        } else{
            userbalanceOf[_from] -= _value.mul(transferRate);
            uint transferAmount = (_value).sub(totalOut);
            userbalanceOf[_to] +=   transferAmount.mul(transferRate);
        }

        uint includedRewards = tenthousandthofamonut.mul(holderFee);
        userbalanceOf[address(this)] += (totalOut - includedRewards);

        uint transactionStakerFee = includedRewards.mul(transferRate);

        if(PERASupply.sub(_removeExcludedAmounts().add(includedRewards)) < 1){
            userbalanceOf[address(this)] += includedRewards;
        }else{
            uint reduceTransferRate = transactionStakerFee.div(PERASupply.sub(_removeExcludedAmounts()));
            transferRate -= reduceTransferRate;
        }

        tradingComp(_value, _from, _bnum); //BNUM DEĞERİ FONKSİYONA EKLENDİ
        if(_isExcluded(_from) && !isManager(_from) && !_isExcluded(_to)){
                tradingComp(_value, _to, _bnum);
        }
        emit Transfer(_from, _to, uint(_value).sub(totalOut));
    }


   mapping (string => bool) public isPaid;
   mapping (string => bool) public isTraderIn;

    //İLK 10 TRADER'IN ADRES VE HACİM BİLGİSİ TUTULUYOR
    struct topTraders {
      address traderAddress;
      uint256 traderVolume;
    }
    mapping(uint => topTraders[]) tTraders;

    //BELİRLİ BİR GÜNE AİT İLK 10DA SON SIRAYA AİT HACİM VE INDEX BİLGİLERİ TUTULUYOR
    struct findTopLast {
      uint256 lastTVolume;
      uint256 lastTIndex;
    }

    mapping(uint256 => findTopLast) findTLast;


    function isManager(address _addr) view private returns(bool) {
        bool isManagerCheck = false;
        if(_addr == manager){
            isManagerCheck = true;
        }
    return  isManagerCheck;
    }


    function tradingComp(uint256 _value, address _addr, uint _bnum) internal {
        if((_value > 100 * 10 ** decimals) && (!_isExcluded(_addr))){
        string memory TCX = nMixAddrandSpBlock(_addr, _bnum);

            if(!isTraderIn[TCX]){                      //KULLANICI DAHA ÖNCE TRADER LİSTESİNE GİRMİŞ MİYDİ?
               isTraderIn[TCX] = true;
                tcdetailz[TCX] = _value;

                if(tTraders[_bnum].length < totalTCwinners){
                    tTraders[_bnum].push(topTraders(_addr, _value));    //GÜN BAŞLANGICINDA 10 KULLANICIYI DİREKT LİSTEYE YERLEŞTİRİYOR
                    if(tTraders[_bnum].length == totalTCwinners){                   //LİSTE DOLDUĞUNDA SON SIRADAKİ KULLANICININ INDEX VE HACİM BİLGİSİNİ BUL
                            uint minVolume = _value;
                            uint minIndex = totalTCwinners-1;
                        for(uint i=0; i<tTraders[_bnum].length; i++){   //LİSTEDEKİ 10 KİŞİYİ GEZEREK İÇLERİNDEN MİN HACİM VE INDEX DEĞERİNİ BUL
                            if(tTraders[_bnum][i].traderVolume < minVolume){
                                minVolume = tTraders[_bnum][i].traderVolume; //İLK 10DAKİ EN DÜŞÜK HACİM DEĞERİ
                                minIndex = i;                                //İLK 10DA EN DÜŞÜK HACİME KARŞILIK GELEN INDEX DEĞERİ
                            }
                        }
                    findTLast[_bnum].lastTVolume = minVolume; //İLK 10DAKİ MİNİMUM HACİM VE KARŞILIK GELEN INDEX DEĞERİ
                    findTLast[_bnum].lastTIndex = minIndex;
                    }
                }

                else{ //LİSTEYE GÜN BAŞINDA 10 KİŞİ EKLENDİKTEN SONRA 296-307 ARASI KULLANILMIYOR, BURADAN SONRAKİ İŞLEMLER YAPILIYOR
                    if(_value > findTLast[_bnum].lastTVolume){
                        topTradersList(_value, _bnum, _addr);
                    }
                }

            }else{
                tcdetailz[TCX] += _value;

                if(tTraders[_bnum].length != totalTCwinners){
                    uint256 updateIndex = findTraderIndex(_bnum, _addr);
                    tTraders[_bnum][updateIndex].traderVolume += _value;
                }else{
                    if(tcdetailz[TCX] > findTLast[_bnum].lastTVolume){
                        if(!isTopTrader(_bnum, _addr)){
                            topTradersList(tcdetailz[TCX], _bnum, _addr);
                        }else if(tTraders[_bnum][findTLast[_bnum].lastTIndex].traderAddress == _addr){
                            topTradersList(tcdetailz[TCX], _bnum, _addr);
                        }else if(isTopTrader(_bnum, _addr) && tTraders[_bnum][findTLast[_bnum].lastTIndex].traderAddress != _addr){
                            uint256 updateIndex = findTraderIndex(_bnum, _addr);
                            tTraders[_bnum][updateIndex].traderVolume += _value;
                        }
                    }
                }
            }
        }
    }

    function topTradersList(uint256 _value, uint256 _bnum, address _addr) internal {

        uint minVolume = _value;
        uint minIndex;

        tTraders[_bnum][findTLast[_bnum].lastTIndex].traderAddress = _addr;
        tTraders[_bnum][findTLast[_bnum].lastTIndex].traderVolume = _value;
        for(uint i=0; i<tTraders[_bnum].length; i++){   //LİSTEDEKİ 10 KİŞİYİ GEZEREK İÇLERİNDEN MİN HACİM VE INDEX DEĞERİNİ BUL
            if(tTraders[_bnum][i].traderVolume < minVolume){
                minVolume = tTraders[_bnum][i].traderVolume; //İLK 10DAKİ EN DÜŞÜK HACİM DEĞERİ
                minIndex = i;                                //İLK 10DA EN DÜŞÜK HACİME KARŞILIK GELEN INDEX DEĞERİ
            }
        }
        findTLast[_bnum].lastTVolume = minVolume;
        findTLast[_bnum].lastTIndex = minIndex;
    }

    function _isExcluded(address _addr) view public returns (bool) { //WHILE KULLANILARAK TRUE OLDUĞU ANDA LOOP DURDURULABİLİR Mİ?
        for(uint i=0; i < _excluded.length; i++){
            if(_addr == _excluded[i]){
                return  true;
            }
        }
    return false;
    }

    function isTopTrader(uint _bnum, address _addr) view public returns(bool) {
        bool checkTopTrader = false;
        for(uint i=0; i < tTraders[_bnum].length; i++){
        if(tTraders[_bnum][i].traderAddress == _addr){
            checkTopTrader = true;
        }
      }
      return  checkTopTrader;
   }

    function findTraderIndex(uint _bnum, address _addr) view public returns(uint256) {
        uint256 checkIndex = 0;
        for(uint i=0; i < tTraders[_bnum].length; i++){
        if(tTraders[_bnum][i].traderAddress == _addr){
            checkIndex = i;
        }
      }
      return  checkIndex;
   }



    function checkTopTraderList(uint _bnum, uint _Ranking) view public returns(address) {
      return  tTraders[_bnum][_Ranking].traderAddress;
   }


    function sortTraders(uint _bnum) view public returns(address[] memory) {
      uint8 wlistlimit = totalTCwinners;
      address[] memory dailyTCWinners = new address[](wlistlimit);
      uint maxTradedNumber = 0;
      address maxTraderAdd;

      for(uint k=0; k<wlistlimit; k++){
          for(uint j=0; j < tTraders[_bnum].length; j++){
                if(!isUserWinner(dailyTCWinners, tTraders[_bnum][j].traderAddress)){
                    if(tTraders[_bnum][j].traderVolume > maxTradedNumber) {
                        maxTradedNumber = tTraders[_bnum][j].traderVolume;
                        maxTraderAdd = tTraders[_bnum][j].traderAddress;
                        dailyTCWinners[k] = maxTraderAdd;
                    }
                } else {
                   maxTraderAdd = address(0);
                }
          }
          maxTradedNumber = 0;
       }
      return  dailyTCWinners;
      }


    function isUserWinner(address[] memory dailyTCList,address _addr) view private returns (bool) {
        for(uint l=0; l < dailyTCList.length; l++){
            if(_addr == dailyTCList[l]){
                return  true;
            }
        }
    return false;
    }


    function _removeExcludedAmounts() view private returns (uint) {
     uint totalRemoved = 0;
         for(uint i=0; i < _excluded.length; i++){
            totalRemoved += userbalanceOf[_excluded[i]];
         }
    return totalRemoved;
    }

    mapping(string => uint256) tcdetailz;



    function nMixAddrandSpBlock(address _addr, uint256 bnum)  public view returns(string memory) {
         return append(uintToString(nAddrHash(_addr)),uintToString(bnum));
    }

    function checkUserVolume(address _addr, uint256 bnum)  public view returns(uint) {
         string memory TCX = nMixAddrandSpBlock(_addr, bnum);
         return tcdetailz[TCX];
    }


      function checkUserTCPosition(address[] memory userinTCList,address _addr) view private returns (uint) {
         for(uint l=0; l < userinTCList.length; l++){
             if(_addr == userinTCList[l]){
                 return  l;
             }
         }
         return totalTCwinners;
       }

    function calculateUserTCreward(address _addr, uint _bnum)  public view returns(uint256, uint256, uint) {
     if(_addr == address(0x0)) { return (404,404,404); } else {
     address[] memory getLastWinners = new address[](totalTCwinners);
     uint rDayDifference = (block.number.sub(genesisBlock.add(_bnum.mul(BlockSizeForTC)))).div(BlockSizeForTC);
     _bnum = _bnum.sub(1);
     if(rDayDifference > 7){rDayDifference=7;}
     uint256 onepercentofamount = (totalRewardforTC[_bnum].add(dailyRewardForTC)).mul(decimalLossLP).div(100);
     getLastWinners = sortTraders(_bnum);
     if(isUserWinner(getLastWinners, _addr)){
         uint winnerIndex = checkUserTCPosition(getLastWinners, _addr);
         if(!isPaid[nMixAddrandSpBlock(msg.sender, _bnum)]){
            uint256 rewardRate = uint(19).sub(uint(2).mul(winnerIndex));
            uint reward = onepercentofamount.mul(rewardRate);
            uint rewardEligible = reward.mul(51+(7*rDayDifference)).div(100);
            return (reward.div(decimalLossLP), rewardEligible.div(decimalLossLP), winnerIndex);
         } else {return (404,404,404);}
     } else {return (404,404,404);} }
    }


    function getTCreward(uint _bnum) external {
         require(_bnum > 0,"min 1 ended TC is required.");
         require(_bnum.sub(1) < showBnum());
         if((_bnum*BlockSizeForTC) > tenYearsasBlock){ dailyRewardForTC = 0;}
         (uint256 reward, uint256 rewardEligible, uint winnerIndex) = calculateUserTCreward(msg.sender, _bnum);
         require(rewardEligible >0);
         if(winnerIndex != 404) {
         dlistLP[datumIndexLP].prosum  += (reward.sub(rewardEligible));
         isPaid[nMixAddrandSpBlock(msg.sender, _bnum)] = true;
         _transfer(address(this), msg.sender, rewardEligible);
         }
    }


    function showBnum() public view returns(uint256) {
        return (block.number - genesisBlock)/BlockSizeForTC;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }


   function uintToString(uint256 v) internal pure returns(string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function nAddrHash(address _address) view private returns (uint256) {
        return uint256(_address) % 10000000000;
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a,"-",b));
    }


 function depositeLPtoken(uint256 tokens) external {
        //require(tokens > 1 * 10 ** LPTokenDecimals);
        require(usersLP[msg.sender].dp == 0);
        datumIndexLP++;
        totalStakedLP += tokens;
        if(datumIndexLP == 0) {
            usersLP[msg.sender] = UserLP(uint(tokens), datumIndexLP);
            dlistLP[datumIndexLP].liqsum =  uint(tokens);
            dlistLP[datumIndexLP].block =  block.number;
            BEP20(lpTokenAddress).transferFrom(msg.sender, address(this), tokens);
        } else {
            usersLP[msg.sender] = UserLP(uint(tokens), datumIndexLP);
            dlistLP[datumIndexLP].liqsum =  dlistLP[datumIndexLP-1].liqsum + uint(tokens);
            dlistLP[datumIndexLP].block =  block.number;
            BEP20(lpTokenAddress).transferFrom(msg.sender, address(this), tokens);
        }
 }

function LPcutRewards(address _addr) public view returns(uint) {

  if(usersLP[_addr].liq == 0) {
      return 0;
  } else {
      uint  totalReward = 0;
      for (uint i=usersLP[_addr].dp; i<=datumIndexLP; i++) {
         uint profitRate =  usersLP[_addr].liq.mul(100).div(dlistLP[i].liqsum);
         totalReward += profitRate.mul(dlistLP[i].prosum.div(100));
      }
      return totalReward;
  }
}

function LPemissionRewards(address _addr) public view returns(uint) {

  if(usersLP[_addr].liq == 0) {
      return 0;
  } else {
      uint  totalReward = 0;

        for (uint i=usersLP[_addr].dp; i<=datumIndexLP; i++) {

        uint currentDatumsBlock = dlistLP[i].block;
        uint nextDatumsBlock = dlistLP[i+1].block;
        if(nextDatumsBlock == 0){nextDatumsBlock = block.number-1;}

        uint numDatumBlocks = nextDatumsBlock - currentDatumsBlock;
        uint profitRate =  (usersLP[_addr].liq).mul(10**9).div(dlistLP[i].liqsum);

            if (((nextDatumsBlock - genesisBlock) > tenYearsasBlock) && ((currentDatumsBlock - genesisBlock) < tenYearsasBlock)){
                uint extraWeekBlocks = ((nextDatumsBlock - genesisBlock) - tenYearsasBlock);
                numDatumBlocks -= extraWeekBlocks;
                totalReward += numDatumBlocks.mul(blockRewardLP).mul(profitRate).div(10**9);
            } else if ((currentDatumsBlock - genesisBlock) > tenYearsasBlock){
                totalReward += 0;
            } else {
                totalReward += numDatumBlocks.mul(blockRewardLP).mul(profitRate).div(10**9);
            }
        }
        return totalReward.div(10);
        }
  }

function removeLiqudityLP() external {
    require(usersLP[msg.sender].liq != 0);
    uint usershareLP = (LPcutRewards(msg.sender).add(LPemissionRewards(msg.sender))).mul(decimalLossLP);

    datumIndexLP++;
    dlistLP[datumIndexLP].liqsum =  dlistLP[datumIndexLP-1].liqsum - usersLP[msg.sender].liq;

    dlistLP[datumIndexLP].block =  block.number;
    totalStakedLP -=  usersLP[msg.sender].liq;
    usersLP[msg.sender] = UserLP(0,0);

    if(block.number - dlistLP[usersLP[msg.sender].dp].block <= oneWeekasBlock) {
        BEP20(lpTokenAddress).transfer(msg.sender,  usersLP[msg.sender].liq.mul(96).div(100));
    } else {
        BEP20(lpTokenAddress).transfer(msg.sender,  usersLP[msg.sender].liq);
    }

    _transfer(address(this), msg.sender, usershareLP.div(decimalLossLP));
 }

 function checkusersLP(address _addr) public view returns (uint256, uint256){
         return (usersLP[_addr].liq, usersLP[_addr].dp);
  }

  function checkdlistLP(uint256 _val) public view returns (uint256, uint256){
        return (dlistLP[_val].liqsum ,dlistLP[_val].prosum);
    }

    function addLPToken(address _addr)  external {
        require(msg.sender == manager);
        lpTokenAddress = _addr;
    }

 }
