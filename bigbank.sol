// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IBank 接口
interface IBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getContractBalance() external view returns (uint256);
    function admin() external view returns (address);
}

// 原 Bank 合约实现 IBank 接口
contract Bank is IBank {
    // 管理员地址
    address public override admin;
    
    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;
    
    // 存款排行榜（前3名）
    address[3] public topDepositors;
    
    // 事件
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed admin, uint256 amount);
    
    // 构造函数，设置管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 接收ETH的fallback函数（支持Metamask直接转账）
    receive() external payable {
        deposit();
    }
    
    // 存款函数（也可通过直接转账触发）
    function deposit() public override payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        // 更新存款排行榜
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // 仅管理员可调用的提款函数
    function withdraw(uint256 amount) external override {
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        
        payable(admin).transfer(amount);
        emit Withdrawn(admin, amount);
    }
    
    // 更新存款排行榜
    function updateTopDepositors(address user, uint256 newBalance) private {
        // 检查是否已在前3名中
        bool alreadyInTop = false;
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] == user) {
                alreadyInTop = true;
                break;
            }
        }
        
        // 如果不在前3名中，检查是否能进入
        if (!alreadyInTop) {
            for (uint i = 0; i < 3; i++) {
                if (newBalance > balances[topDepositors[i]] || topDepositors[i] == address(0)) {
                    // 插入到当前位置，后面的依次后移
                    for (uint j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j-1];
                    }
                    topDepositors[i] = user;
                    break;
                }
            }
        } else {
            // 如果已在榜单中，重新排序
            sortTopDepositors();
        }
    }
    
    // 对排行榜进行排序
    function sortTopDepositors() private {
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2 - i; j++) {
                if (balances[topDepositors[j]] < balances[topDepositors[j+1]]) {
                    address temp = topDepositors[j];
                    topDepositors[j] = topDepositors[j+1];
                    topDepositors[j+1] = temp;
                }
            }
        }
    }
    
    // 获取合约总余额
    function getContractBalance() public override view returns (uint256) {
        return address(this).balance;
    }
}

// BigBank 合约继承自 Bank
contract BigBank is Bank {
    // 修改器：要求存款金额大于0.001 ether
    modifier minimumDeposit() {
        require(msg.value > 0.001 ether, "Deposit must be greater than 0.001 ether");
        _;
    }
    
    // 重写deposit函数，添加minimumDeposit修饰器
    function deposit() public payable override minimumDeposit {
        super.deposit();
    }
    
    // 转移管理员权限
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can transfer admin rights");
        admin = newAdmin;
    }
}

// Admin 合约
contract Admin {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 只有owner可以调用的取款函数
    function adminWithdraw(IBank bank) external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = bank.getContractBalance();
        require(balance > 0, "No balance to withdraw");
        
        // 调用bank的withdraw函数
        bank.withdraw(balance);
    }
    
    // 接收ETH的fallback函数
    receive() external payable {}
}
