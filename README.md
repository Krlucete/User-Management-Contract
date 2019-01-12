# User-Management-Contract
There are two core parts (UserManagement(Members), Token(OreOreCoin))

# Notice

When 'OreOreCoin' contract is issued, we had to issued Members contract and then address of Memebers contract should be given in 
parameter
The 'updateHistory' function is specified modifier. it means that Token contract has authentication to execcute. not remainder.
At the called, context in the 'updateHistory' function is 'OreOreCoin' contract. that is the reason why modifier keyword is specified.
Also 'setCoin' function will be executed for modifier before some transact.

