// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <richard@gnosis.pm>
contract Executor {
    function execute(  //调用合约函数 该函数用于执行合约调用或委托调用（delegatecall）
        address to, //要调用的合约地址
        uint256 value, //调用时要传递的以太币数量
        bytes memory data, //调用时要传递的数据
        Enum.Operation operation, //调用操作类型，可能是委托调用或是普通调用
        uint256 txGas   //调用时提供的 gas 限制
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) { //判断调类型当为委托调用时执行该函数
            // solhint-disable-next-line no-inline-assembly
            assembly {  //assembly 关键字用于执行汇编代码来实现低级别的 EVM 操作
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0) //调用delegatecall汇编指令
                //add(data, 0x20)跳过data数据前四个字节的函数选择器的内容
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}
