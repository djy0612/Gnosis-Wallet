// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";

interface Guard { //守卫
    function checkTransaction(//用于检查交易是否满足特定条件
        address to,//目标地址
        uint256 value,//转账金额
        bytes memory data,//交易数据，通常是通过ABI编码后的函数调用数据，包括函数签名以及参数编码
        Enum.Operation operation,//操作类型
        uint256 safeTxGas,//交易的安全 gas
        uint256 baseGas,//基础 gas
        uint256 gasPrice,//gas 价格
        address gasToken,//gas 代币地址
        address payable refundReceiver,//退款接收者地址
        bytes memory signatures,//签名
        address msgSender//交易发起者地址
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
    //在交易执行后进行检查。该函数接收交易哈希和交易执行结果作为参数，可以根据交易的执行结果进行相应的处理，如记录交易状态、触发事件等
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <richard@gnosis.pm>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);  //事件
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {  //设置guard合约处理器
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) { //获取guard合约处理器的地址
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}
