// SPDX-License-Identifier: GPL-3.0-only
// author: Upaut (CallistoDAO)

pragma solidity ^0.8.16;

contract MonetaryPolicy {

    uint256 public MinerReward; // Награда для майнера за блок
    uint256 public TreasuryReward; // Награда для трежери за блок
    uint256 public StakeReward; // Награда для колдстака за блок
    uint256 public ReserveReward; // Зарезервированный слот под награду, если понадобится распределение на уровне консенсуса

    address public TreasuryAddress = 0x74682Fc32007aF0b6118F259cBe7bCCC21641600; // Адрес контракта Treasury
    address public StakeAddress = 0x08A7c8be47773546DC5E173d67B0c38AfFfa4b84; // Адрес контракта ColdStaking
    address public ReserveAddress = 0x0000000000000000000000000000000000000000; // Зарезервированный слот под адрес

    address public GovernanceDAO = 0x810059e1406dEDAFd1BdCa4E0137CbA306c0Ce36; // Владелец контракта
    address public CallistoNetwork = 0xA9389DB4610175CaC4Fad32670A5189A89f874B5; // Владелец контракта

    uint256 public TimeVoce = 45 days; // время отведенное для принятия решения по предложению вторым владельцем
    uint256 public TimeEnd = 60 days; // время жизни предложения

    struct Data {
        uint256 timeVoce; // крайний срок голосования для второго участника (если второй участник не проголосует до указанного времени, то первый участник может принять предложение в единоличном порядке)
        uint256 timeEnd; // крайний срок жизни предложения (если второй учасник не проголосовал по предложению и первый участник не провел предложение в единоличном порядке до указанного времени, то предложение аннулируется)
        bool governanceDAO; // активность участника (принимает true, если участник поддерживает предложение)
        bool callistoNetwork; // активность участника (принимает true, если участник поддерживает предложение)
    }

    mapping(bytes32 => Data) public proposals; // хеши предложений указывающие на структуру Data

    event Proposal(address indexed owner, bytes32 indexed hash, bool indexed voce); // логирование предложения

    modifier onlyGovernanceDAO() {
        require(msg.sender == GovernanceDAO, "Only GovernanceDAO");
        _;
    }

    modifier onlyTreasuryRecipients() {
        require((msg.sender == CallistoNetwork) || (msg.sender == GovernanceDAO), "Only treasury recipient");
        _;
    }


    // Функция назначает награды за блок используемые в консенсусе ноды (вся эмиссия блока должна распределяться за 1 одну транзакцию)
    function setRewards(uint256 _minerReward, uint256 _treasuryReward, uint256 _stakeReward, uint256 _reserveReward, bool _voce) external onlyTreasuryRecipients {
        bytes4 _selector = this.setRewards.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _minerReward, _treasuryReward, _stakeReward, _reserveReward)); // получаем хеш предложения
        if(_consensus(_hash, _voce)){ // если консенсус достигнут
            MinerReward = _minerReward;
            TreasuryReward = _treasuryReward;
            StakeReward = _stakeReward;
            ReserveReward = _reserveReward;            
        }
        emit Proposal(msg.sender, _hash, _voce); // логируем предложение
    }

    // Функция назначает новый адрес контракта TreasuryAddress
    function setTreasuryAddress(address _treasuryAddress, bool _voce) external onlyTreasuryRecipients {
        bytes4 _selector = this.setTreasuryAddress.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _treasuryAddress)); // получаем хеш предложения
        if(_consensus(_hash, _voce)){ // если консенсус достигнут
            TreasuryAddress = _treasuryAddress;
        }
        emit Proposal(msg.sender, _hash, _voce); // логируем предложение
    }

    // Функция назначает новый адрес контракта ColdStaking
    function setStakeAddress(address _stakeAddress) external onlyGovernanceDAO {
        StakeAddress = _stakeAddress;
    }

    // Функция назначает новый адрес для начисления резервной награды 
    function setReserveAddress(address _reserveAddress) external onlyGovernanceDAO {
        ReserveAddress = _reserveAddress;
    }

    // Функция устанавливает новые сроки проведения голосования по предложению 
    function setPeriods(uint256 _timeVoce, uint256 _timeEnd, bool _voce) external onlyTreasuryRecipients {
        require((_timeVoce > 0) && (_timeEnd > _timeVoce));
        bytes4 _selector = this.setPeriods.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _timeVoce, _timeEnd)); // получаем хеш предложения
        if(_consensus(_hash, _voce)){ // если консенсус достигнут
            TimeVoce = _timeVoce;
            TimeEnd = _timeEnd;
        }
        emit Proposal(msg.sender, _hash, _voce); // логируем предложение
    }

    // Функция назначает новый адрес контракта GovernanceDAO или CallistoNetwork
    function setNewOwners(address _newOwner) external onlyTreasuryRecipients {
        require((_newOwner != GovernanceDAO) && (_newOwner != CallistoNetwork));
        (GovernanceDAO, CallistoNetwork) = msg.sender == GovernanceDAO ? (_newOwner, CallistoNetwork) : (GovernanceDAO, _newOwner);
    }

    // Функция меняем адрес одного из владельцев, если этот владелец не опровергнет данного решения
    function resetOwner(address _owner, address _newOwner, bool _voce) external onlyTreasuryRecipients {
        require((_owner == GovernanceDAO) || (_owner == CallistoNetwork));
        require((_newOwner != GovernanceDAO) && (_newOwner != CallistoNetwork));

        bytes4 _selector = this.resetOwner.selector;
        bytes32 _hash = keccak256(abi.encodePacked(_selector, _owner, _newOwner)); // получаем хеш предложения
        if(_consensus(_hash, _voce)){ // если консенсус достигнут
            (GovernanceDAO, CallistoNetwork) = _owner == GovernanceDAO ? (_newOwner, CallistoNetwork) : (GovernanceDAO, _newOwner);
        }
        emit Proposal(msg.sender, _hash, _voce); // логируем предложение
    }

    // Функция достижения консенсуса между владельцами (возвращает true если консенсус был достигнут)
    function _consensus(bytes32 _hash, bool _voce) private returns (bool){
        if (proposals[_hash].timeEnd < block.timestamp){ // срок жизни предложения истек (либо предложение не существовало), будем его пересоздавать
            delete proposals[_hash];
            if (!_voce) return (false); // предложение не создается, если голос "против"
            proposals[_hash].timeVoce = block.timestamp + TimeVoce; // устанавливаем временной лимит для голосования второго владельца
            proposals[_hash].timeEnd = block.timestamp + TimeEnd; // Устанавливаем срок жизни предложения
            (proposals[_hash].governanceDAO, proposals[_hash].callistoNetwork) = msg.sender == GovernanceDAO ? (true, false) : (false, true);
        } else if (proposals[_hash].timeVoce < block.timestamp) { // период принятия одностороннего решения
            delete proposals[_hash];
            return (true);
        } else { // период голосования
            if (!_voce) { // голос "против" от любого из владельцев уничтожит предложение
                delete proposals[_hash];
            } else {
                (proposals[_hash].governanceDAO, proposals[_hash].callistoNetwork) = msg.sender == GovernanceDAO ? (true, proposals[_hash].callistoNetwork) : (proposals[_hash].governanceDAO, true); // выставляем голоса
                if ((proposals[_hash].governanceDAO) && (proposals[_hash].callistoNetwork)) { // консенсус достигнут
                    delete proposals[_hash]; // удаляем предложение, в нем более нет нужды
                    return (true);
                }
            }
        }

        return (false);
    }
}