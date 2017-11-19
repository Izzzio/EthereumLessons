pragma solidity ^0.4.15;
// Указываем версию компилятора, с которой совместим наш код

// Этот контракт используется для предоставления модификатора проверки "владения" контрактом
contract owned {
    
    function owned() public { owner = msg.sender; }
    
    //Это "владелец" контракта. Он будет являтся админом голосования
    address owner;

    // В место, обозначенное как _; будет добавлен остальной код модифицируемого метода
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract Voting is owned {
  /* mapping - это альтернатива ассоциативному массиву или hash хранилищу из других языков
  Ключем у нас является массив uint8, используем вариант голосования. Значением является целое число - количество набранных голосов
  */
  
  mapping (uint8 => uint8) public votesReceived;
  
  /*
  Сохраняем названия пунктов голосования
  */
  mapping (uint8 => string) public candidates;
  
  /* К сожалению Solidity не позволяет создавать массив строк из-за технических огранечений.
  Используем uint8 для хранения вариантов голосования
  */
  
  uint8[] public candidateList;
  
  /*
   * Сохраняем информацию об уже голосовавших кошельках
   * Делаем приватную - для защиты списка проголосовавших
   */
  mapping (address => bool) private voted;


  /* Это конструктор класса контракта. Вызывается один раз при создании контракта
  */
  function Voting() public {
  }
  
  // Добавляем варианты голосования. Добавлять может только владелец
  function addVariant(uint8 candidateNo, string candidate) public onlyOwner{
      candidateList.push(candidateNo);
      candidates[candidateNo] = candidate;
  }

  // Функция возвращает количество голосов за вариант
  function totalVotesFor(uint8 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

    // Узнаём победителя голосования
  function whoWin() view public returns (string) {
    uint8 maxVotes = 0;
    uint8 maxEqualVotes = 0;
    uint8 candidateForWin;
    
    // Перебираем варианты голосования и сравниваем количество голосов
    for(uint i = 0; i < candidateList.length; i++) {
      if (votesReceived[candidateList[i]] > maxVotes) {
            maxVotes = votesReceived[candidateList[i]];
    	    candidateForWin = candidateList[i];
      }else if(votesReceived[candidateList[i]] == maxVotes){ //Произошёл случай, когда кто-то набрал одинаковое количество голосов
            maxEqualVotes = maxVotes; //Сохраняем для дальнейшей проверки
      }
    }

    // Если голосов ещё не было
    if(maxVotes == 0){
    	return "No winner";
    }
    
    // Если победителей больше одного, то никто не победитель
    if(maxVotes == maxEqualVotes){
        return "Dead heat";
    }

    return candidates[candidateForWin];
  }

  // Эта функцию добавляет один голос варианту голосования
  function voteForCandidate(uint8 candidate) public {
    //Проверяем, что кошелёк не голосовал
    require(voted[msg.sender] != true);
    
    //Проверяем, что кандидат существует
    require(validCandidate(candidate));

    //Сохраняем информацию о проголосовавшем
    voted[msg.sender] = true;
    votesReceived[candidate] += 1;
  }

  // Функция проверки кандидата на существование
  function validCandidate(uint8 candidate) view public returns (bool) {
    for(uint i = 0; i < candidateList.length; i++) {
      if (candidateList[i] == candidate) {
        return true;
      }
    }
    return false;
  }
}