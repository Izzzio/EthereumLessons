pragma solidity ^0.4.16;

/**
* Информация о владении
*/
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

//Уведомление о получении разрешения на трату токенов
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

/**
Описываем токен стандарта ERC20
*/
contract TokenERC20 {

	//Название токена
    string public name;
    
    //Обозначение токена
    string public symbol;
    
    //До скольки нулей после точки токен может делится (рекомендуется 18)
    uint8 public decimals = 18;
    
    //Сколько токенов выпущено
    uint256 public totalSupply;

    // Балансы ппользователей
    mapping (address => uint256) public balanceOf;
    
    // "Разрешения" траты токенов
    mapping (address => mapping (address => uint256)) public allowance;

    // Событие, рассылаемое всем участникам контракта о переводе средств
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Событие сжигания токенов
    event Burn(address indexed from, uint256 value);

    /**
     * Создаём и инфициализируем ERC20 токен
     *
     *
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Записываем сумму изначальной эмиссии
        balanceOf[msg.sender] = totalSupply;                // Переводим владельцу токена сумму изначальной эмиссии
        name = tokenName;                                   // Сохраняем название токена
        symbol = tokenSymbol;                               // Сохраняем обозначение токена
    }

    /**
     * Внутрений метод перевода, доступный только изнутри контракта
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Предотвращаем отправку токенов на нулевой адрес
        require(_to != 0x0);
        // Проверяем достаточно ли токенов у отправителя
        require(balanceOf[_from] >= _value);
        // !!! Проверка на переполнение переменной после отправки
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        // Сохраняем предыдущий баланс для провверки в будущем
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        // Списываем токены с отправителя
        balanceOf[_from] -= _value;
        
        // Начисляем токены получателю
        balanceOf[_to] += _value;
        
        // Создаём событие перевода
        Transfer(_from, _to, _value);
        
        // Эта проверка позволяет заранее найти ошибки в нашем коде
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Отправка токенов
     *
     * Отправка `_value` токенов `_to` с вашего аккаунта
     *
     * @param _to Адрес получателя
     * @param _value сумма для отправки
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Отправка с чужого аккаунта, с проверкой разрешения
     *
     * Отправка `_value` токенов `_to` с вашего аккаунта с аккаунта `_from`
     *
     * @param _from Адрес отправителя
     * @param _to Получатель
     * @param _value Сумма перевода
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Проверяем разрешие на распоряжение токенами
        require(_value <= allowance[_from][msg.sender]);     
        
        //Вычитаем потраченые токены из суммы одобрения
        allowance[_from][msg.sender] -= _value;
        
        //Выполняем перевод
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Разрешаем распоряжатся суммой токенов
     *
     * Разрешает `_spender` тратить не больше, чем `_value` токенов с нашего кошелька
     *
     * @param _spender Кто может тратить
     * @param _value Сумма
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Уничтожает токены
     *
     * Удаляем `_value` токнов со своего кошелкьа и из системы
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Проверяем наличие денег
        balanceOf[msg.sender] -= _value;            // Списываем с отправителя
        totalSupply -= _value;                      // Обновляем сумму всех токенов
        Burn(msg.sender, _value);                   // Уведомляем о сжигании
        return true;
    }

    /**
     * Уничтожение токенов с чужого аккаунта
     *
     * Удаляет `_value` токенов с акканта  `_from` если разрешено
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Проверка достаточно-ли средств
        require(_value <= allowance[_from][msg.sender]);    // Проверяем разрешение
        balanceOf[_from] -= _value;                         // Списываем токены с баланса
        allowance[_from][msg.sender] -= _value;             // Списываем разрешенные токены
        totalSupply -= _value;                              // Обновляем сумму токенов
        Burn(_from, _value);                                // Уведомляем о сжигании
        return true;
    }
}


/**
 * Описываем токен распродажи
 * Наш токен будет с проверкой владения и стандарта ERC20
 * 
 */
contract CrowdsaleToken is owned, TokenERC20 {

    // Стоимость токена в wei
    uint256 public tokenPrice = 1000000000000000000; // 1 token = 1 ETH
    
    // Флаг завершенности сбора средств
    bool public finished = false;
    
    //Сколько средств собрано
    uint public amountRaised = 0;

    function CrowdsaleToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    
    // Событие, рассылаемое всем участникам контракта о переводе средств
    event Finished(uint256 amount);

    /**
     * Внутрений метод перевода, доступный только изнутри контракта
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Предотвращаем отправку токенов на нулевой адрес
        require(_to != 0x0);
        // Проверяем достаточно ли токенов у отправителя
        require(balanceOf[_from] >= _value);
        // !!! Проверка на переполнение переменной после отправки
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // Списываем токены с отправителя
        balanceOf[_from] -= _value;
        
        // Начисляем токены получателю
        balanceOf[_to] += _value;
        
        // Создаём событие перевода
        Transfer(_from, _to, _value);

    }

    /**
     * Устанавливаем курс конвертации токенов
     */
    function setPrice(uint256 newTokenPrice) onlyOwner public {
        tokenPrice = newTokenPrice;
    }

    /**
     * Продаём токены покупателю согласно заданному курсу 
     */
    function buy() payable public returns (uint) {
        require(!finished);                             //Проверяем, что сбор средств не остановлен
        amountRaised += msg.value;
        uint amount = msg.value / tokenPrice;               // Высчитываем сумм
        _transfer(owner, msg.sender, amount);              // Переводим
        return amount;
    }

    /**
     * Завершаем сбор  средст и переводим эфир со счёта контракта владельцу
     * 
     */
    function finish() onlyOwner public {
        finished = true;
        Finished(amountRaised);
        msg.sender.transfer(amountRaised);  
    }
}
